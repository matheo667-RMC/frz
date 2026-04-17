-- FRZ RP - cote client : vendeur PNJ de voitures pres du terminal.
-- Spawn un PNJ a la position configuree, surveille la distance au joueur,
-- ouvre un menu NUI quand le joueur appuie sur la touche d'interaction.

FrzSpawn = FrzSpawn or {}

local dealerPed      = nil
local menuOpen       = false
local lastOpenRequest = 0   -- anti-spam + recuperation si le serveur ne repond pas
local OPEN_COOLDOWN  = 1000 -- ms entre deux tentatives d'ouverture

-- Mapping des codes de controle GTA vers une etiquette lisible (touche physique
-- usuelle sur clavier QWERTY, pour affichage dans le prompt 3D).
local CONTROL_LABEL = {
    [23]  = 'F',        -- INPUT_ENTER
    [38]  = 'E',        -- INPUT_PICKUP
    [47]  = 'G',        -- INPUT_DETONATE
    [51]  = 'E',        -- INPUT_CONTEXT
    [74]  = 'H',        -- INPUT_VEH_HEADLIGHT
    [86]  = 'Q',        -- INPUT_VEH_HORN
    [246] = 'R',        -- INPUT_REPLAY_RECORDING
    [311] = 'K',        -- INPUT_REPLAY_START_STOP_RECORDING
}

local function controlLabel(controlId)
    return CONTROL_LABEL[controlId] or tostring(controlId)
end

local function loadModel(modelName, timeoutMs)
    local model = type(modelName) == 'string' and GetHashKey(modelName) or modelName
    RequestModel(model)
    local t0 = GetGameTimer()
    while not HasModelLoaded(model) do
        Wait(50)
        if GetGameTimer() - t0 > (timeoutMs or 5000) then return nil end
    end
    return model
end

local function spawnDealer()
    if not Config.CarRental or not Config.CarRental.enabled then return end
    if dealerPed and DoesEntityExist(dealerPed) then return end

    local pos = Config.CarRental.pedPos
    local model = loadModel(Config.CarRental.pedModel, 5000)
    if not model then
        print('[frz-rp-spawn] Impossible de charger le modele vendeur')
        return
    end

    dealerPed = CreatePed(4, model, pos.x, pos.y, pos.z - 1.0, pos.w, false, false)
    if not DoesEntityExist(dealerPed) then
        SetModelAsNoLongerNeeded(model)
        return
    end

    SetEntityAsMissionEntity(dealerPed, true, true)
    SetEntityInvincible(dealerPed, true)
    SetBlockingOfNonTemporaryEvents(dealerPed, true)
    SetPedCanRagdoll(dealerPed, false)
    SetPedDiesWhenInjured(dealerPed, false)
    SetPedFleeAttributes(dealerPed, 0, false)
    FreezeEntityPosition(dealerPed, true)
    SetEntityHeading(dealerPed, pos.w)
    -- Le vendeur joue une petite animation "parler au telephone / attendre".
    TaskStartScenarioInPlace(dealerPed, 'WORLD_HUMAN_CLIPBOARD', 0, true)

    SetModelAsNoLongerNeeded(model)
end

local function removeDealer()
    if dealerPed and DoesEntityExist(dealerPed) then
        SetEntityAsMissionEntity(dealerPed, true, true)
        DeletePed(dealerPed)
    end
    dealerPed = nil
end

-- Dessine du texte 3D au dessus du ped.
local function drawText3D(x, y, z, text)
    local onScreen, sx, sy = World3dToScreen2d(x, y, z)
    if not onScreen then return end
    local camCoords = GetGameplayCamCoords()
    local dist = #(vector3(camCoords.x, camCoords.y, camCoords.z) - vector3(x, y, z))
    local scale = math.max(0.35, 0.6 * (6.0 / dist))

    SetTextScale(0.0, scale)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 215)
    SetTextOutline()
    SetTextCentre(true)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(sx, sy)
end

local function openMenu()
    -- Ne PAS mettre menuOpen = true ici : le serveur peut silencieusement
    -- ignorer la demande (ex : check de proximite cote serveur echoue a cause
    -- d'un decalage de sync). Si on le mettait a true sans confirmation, le
    -- joueur serait bloque (prompt masque, menu invisible car jamais affiche).
    -- On se fie a l'event `showRentalMenu` pour passer a true.
    if menuOpen then return end
    local now = GetGameTimer()
    if now - lastOpenRequest < OPEN_COOLDOWN then return end
    lastOpenRequest = now
    TriggerServerEvent('frz-rp-spawn:openRentalMenu')
end

local function closeMenu()
    if not menuOpen then return end
    menuOpen = false
    SendNUIMessage({ action = 'hideRental' })
    SetNuiFocus(false, false)
end

-- Thread principal : surveille la distance au vendeur et affiche le prompt.
CreateThread(function()
    -- Attend que le joueur soit dans le monde.
    while not NetworkIsPlayerActive(PlayerId()) do Wait(500) end
    while not DoesEntityExist(PlayerPedId()) do Wait(500) end

    -- Laisse passer la cinematique initiale.
    Wait(5000)

    spawnDealer()

    local interactionKey = (Config.CarRental and Config.CarRental.interactionKey) or 38
    local maxDist = (Config.CarRental and Config.CarRental.interactionDistance) or 2.5

    while true do
        local sleep = 500
        if dealerPed and DoesEntityExist(dealerPed) then
            local pedCoords    = GetEntityCoords(dealerPed)
            local playerCoords = GetEntityCoords(PlayerPedId())
            local d = #(pedCoords - playerCoords)

            if d < 15.0 then
                sleep = 0
                if d < maxDist and not menuOpen then
                    drawText3D(pedCoords.x, pedCoords.y, pedCoords.z + 1.1,
                        '~y~[' .. controlLabel(interactionKey) .. ']~w~ Parler au vendeur')
                    if IsControlJustReleased(0, interactionKey) then
                        openMenu()
                    end
                end
            end
        else
            -- Respawn defensif si le PNJ a disparu (changement de map, streaming...)
            spawnDealer()
        end
        Wait(sleep)
    end
end)

-- Nettoyage au stop de la ressource.
AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        removeDealer()
        if menuOpen then
            SetNuiFocus(false, false)
        end
    end
end)

-- Reception : le serveur a autorise l'ouverture du menu.
RegisterNetEvent('frz-rp-spawn:showRentalMenu', function(balance, vehicles)
    menuOpen = true
    SendNUIMessage({
        action = 'showRental',
        balance = balance or 0,
        vehicles = vehicles or {},
    })
    SetNuiFocus(true, true)
end)

-- Reception du resultat d'une tentative de location.
RegisterNetEvent('frz-rp-spawn:rentalResult', function(result)
    if not result then return end
    if result.ok then
        -- Ferme le menu et fait apparaitre la voiture.
        closeMenu()
        local ok = FrzSpawn.spawnRentedVehicle(result.model)
        if ok then
            local priceStr = (result.price and result.price > 0)
                and ('pour ' .. result.price .. ' $') or 'gratuitement'
            BeginTextCommandThefeedPost('STRING')
            AddTextComponentSubstringPlayerName(
                ('Vehicule %s livre %s. Solde : %d $')
                :format(result.label or result.model, priceStr, result.newBalance or 0))
            EndTextCommandThefeedPostTicker(false, true)
        else
            -- Spawn client a echoue (timeout modele, limite entites, etc.).
            -- On demande au serveur de rembourser si un paiement avait ete debite.
            if result.price and result.price > 0 then
                TriggerServerEvent('frz-rp-spawn:rentalSpawnFailed',
                    result.model, result.price)
                BeginTextCommandThefeedPost('STRING')
                AddTextComponentSubstringPlayerName(
                    ('Echec spawn. %d $ rembourses.'):format(result.price))
                EndTextCommandThefeedPostTicker(false, true)
            end
        end
    else
        -- Ferme le menu et affiche un message d'erreur.
        local msg = 'Erreur lors de la location.'
        if result.reason == 'insufficient_funds' then
            msg = 'Fonds insuffisants (solde : ' .. (result.newBalance or 0) .. ' $).'
        elseif result.reason == 'unknown_model' then
            msg = 'Ce modele n est pas dispo.'
        elseif result.reason == 'too_far' then
            msg = 'Tu es trop loin du vendeur.'
        end
        -- Notifie via la NUI pour rester dans le menu (sans le fermer).
        SendNUIMessage({ action = 'rentalError', message = msg, balance = result.newBalance or 0 })
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(msg)
        EndTextCommandThefeedPostTicker(false, true)
    end
end)

-- Reception d'une mise a jour de solde (commande admin).
RegisterNetEvent('frz-rp-spawn:moneyUpdate', function(newBalance)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(('Solde mis a jour : %d $'):format(newBalance or 0))
    EndTextCommandThefeedPostTicker(false, true)
    if menuOpen then
        SendNUIMessage({ action = 'rentalUpdateBalance', balance = newBalance or 0 })
    end
end)

-- ============================================================================
-- Spawn de la voiture louee (local, puis transfere au reseau).
-- ============================================================================

function FrzSpawn.spawnRentedVehicle(modelName)
    local sp = Config.CarRental and Config.CarRental.spawnPos
    if not sp then return false end

    local model = loadModel(modelName, 5000)
    if not model then
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName('Impossible de charger le vehicule.')
        EndTextCommandThefeedPostTicker(false, true)
        return false
    end

    -- isNetwork = true pour que les autres joueurs voient le vehicule.
    local veh = CreateVehicle(model, sp.x, sp.y, sp.z, sp.w, true, false)
    if not DoesEntityExist(veh) then
        SetModelAsNoLongerNeeded(model)
        return false
    end

    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleOnGroundProperly(veh)
    SetVehicleEngineOn(veh, true, true, false)
    SetVehicleFuelLevel(veh, 100.0)
    SetVehicleNumberPlateText(veh, 'FRZ ' .. math.random(100, 999))

    SetModelAsNoLongerNeeded(model)
    return true
end

-- NUI callbacks (quand le joueur clique sur un vehicule dans le menu).
RegisterNUICallback('rent', function(data, cb)
    if type(data) == 'table' and type(data.model) == 'string' then
        TriggerServerEvent('frz-rp-spawn:rentVehicle', data.model)
    end
    cb({ ok = true })
end)

RegisterNUICallback('close', function(_, cb)
    closeMenu()
    cb({ ok = true })
end)
