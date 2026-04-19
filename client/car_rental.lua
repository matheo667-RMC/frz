-- FRZ RP - cote client : vendeur PNJ de voitures pres du terminal.
-- Spawn un PNJ a la position configuree, surveille la distance au joueur,
-- ouvre un menu NUI quand le joueur appuie sur la touche d'interaction.

FrzSpawn = FrzSpawn or {}

local dealerPed       = nil
local menuOpen        = false
local lastOpenRequest = 0    -- anti-spam + recuperation si le serveur ne repond pas
local OPEN_COOLDOWN   = 1000 -- ms entre deux tentatives d'ouverture
local rentInFlight    = false -- empeche les clics rapides de declencher plusieurs spawns

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
RegisterNetEvent('frz-rp-spawn:showRentalMenu', function(balance, vehicles, categories)
    menuOpen = true
    SendNUIMessage({
        action = 'showRental',
        balance = balance or 0,
        vehicles = vehicles or {},
        categories = categories or {},
    })
    SetNuiFocus(true, true)
end)

-- Reception du resultat d'une tentative de location.
RegisterNetEvent('frz-rp-spawn:rentalResult', function(result)
    if not result then return end
    if result.ok then
        -- Guard anti-doublon : si un spawn est deja en cours (clics rapides qui
        -- auraient genere plusieurs rentVehicle), on ignore les resultats
        -- suivants pour eviter de spawner plusieurs vehicules et de perdre
        -- l'argent sur un seul pendingRefund. Le serveur ajoute aussi un
        -- garde-fou, c'est une defense en profondeur.
        if rentInFlight then return end
        rentInFlight = true

        -- Ferme le menu et fait apparaitre la voiture.
        closeMenu()
        local ok = FrzSpawn.spawnRentedVehicle(result.model)
        if ok then
            -- Ferme la fenetre de remboursement cote serveur : sans ca, le
            -- pendingRefund resterait valide jusqu'a son TTL (30s) et un client
            -- modifie pourrait envoyer rentalSpawnFailed pour recuperer les $$
            -- tout en gardant le vehicule.
            if result.price and result.price > 0 then
                TriggerServerEvent('frz-rp-spawn:rentalSpawnOK',
                    result.model, result.price)
            end
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

        rentInFlight = false
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

-- Trouve l'entree vehicule dans la config (pour recuperer color / category).
local function findConfigVehicle(modelName)
    if not Config.CarRental or not Config.CarRental.vehicles then return nil end
    for _, v in ipairs(Config.CarRental.vehicles) do
        if v.model == modelName then return v end
    end
    return nil
end

-- Retourne l'ID de couleur GTA pour une cle symbolique ('black', 'white',
-- 'red', ...) configuree dans Config.CarRental.colors.
local function resolveColor(key)
    if not key or not Config.CarRental or not Config.CarRental.colors then
        return nil
    end
    return Config.CarRental.colors[key]
end

-- Snap a position vers le road node le plus proche (garantit qu'on tombe
-- sur une vraie route, pas sur des escaliers / un trottoir / une zone
-- piétonne). Retourne (x, y, z, heading) de la route. Si aucune route
-- n'est trouvée dans un rayon raisonnable, on retourne la position d'origine.
local function snapToNearestRoad(x, y, z, fallbackHeading)
    -- nodeType = 1 = route standard ; 3 = route + lanes.
    local ok, roadX, roadY, roadZ, roadHeading =
        GetClosestVehicleNodeWithHeading(x, y, z, 1, 3.0, 0)
    if ok and roadX and roadY then
        return roadX, roadY, roadZ, roadHeading
    end
    return x, y, z, fallbackHeading or 0.0
end

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

    -- On snap vers le road node le plus proche : les coords de config sont
    -- une hint, mais c'est le jeu qui decide ou est la route reelle. Ca
    -- evite de faire spawner une voiture dans un escalier / un trottoir /
    -- sous une rampe, meme si les coords sont un peu off.
    local spawnX, spawnY, spawnZ, spawnH = snapToNearestRoad(sp.x, sp.y, sp.z, sp.w)

    -- isNetwork = true pour que les autres joueurs voient le vehicule.
    local veh = CreateVehicle(model, spawnX, spawnY, spawnZ, spawnH, true, false)
    if not DoesEntityExist(veh) then
        SetModelAsNoLongerNeeded(model)
        return false
    end

    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleOnGroundProperly(veh)
    SetVehicleEngineOn(veh, true, true, false)
    SetVehicleFuelLevel(veh, 100.0)
    SetVehicleNumberPlateText(veh, 'FRZ ' .. math.random(100, 999))

    -- Couleur definie dans la config : on applique la meme teinte primary et
    -- secondary pour que le vehicule soit uniformement colore (pas de contraste
    -- toit/carrosserie qui ferait bizarre sur un velo).
    local entry = findConfigVehicle(modelName)
    local colorId = entry and resolveColor(entry.color)
    if colorId then
        SetVehicleColours(veh, colorId, colorId)
    end

    -- Met le joueur directement au volant (siege conducteur = -1) si la config
    -- le demande. Evite au joueur d'avoir a courir autour du vehicule.
    if Config.CarRental and Config.CarRental.putPlayerInVehicle then
        local ped = PlayerPedId()
        if DoesEntityExist(ped) then
            TaskWarpPedIntoVehicle(ped, veh, -1)
        end
    end

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

-- ============================================================================
-- Commande utilitaire : /frzwhereami
-- Affiche les coords + heading actuels du joueur dans la console F8 et dans
-- la notification in-game. Utile pour recuperer la position exacte a mettre
-- dans Config.CarRental.spawnPos ou Config.CarRental.pedPos.
-- ============================================================================
RegisterCommand('frzwhereami', function()
    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then return end
    local c = GetEntityCoords(ped)
    local h = GetEntityHeading(ped)
    local str = ('vector4(%.2f, %.2f, %.2f, %.1f)'):format(c.x, c.y, c.z, h)
    print('[frz-rp-spawn] /frzwhereami -> ' .. str)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(str)
    EndTextCommandThefeedPostTicker(false, true)
    -- Affiche aussi en chat (si le chat est active) pour copier-coller facile.
    TriggerEvent('chat:addMessage', {
        color = { 180, 150, 255 },
        multiline = true,
        args = { 'FRZ', str },
    })
end, false)
