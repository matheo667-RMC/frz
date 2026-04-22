-- Dead Zone RP (frz-craft) - Pose de barricades.
-- Le joueur fait /placebarricade : le client demande au serveur de consommer
-- l'item (serveur-authoritatif). Ce n'est qu'apres confirmation serveur qu'on
-- spawn le prop reseau. Evite le "free barricade" si takeItem echoue apres
-- que le client a deja pose le prop (race condition entre hasItem et takeItem).

FrzCraft = FrzCraft or {}
FrzCraft.Client = FrzCraft.Client or {}

local frzCore = exports['frz-core']

-- Modele de prop utilise pour la barricade. 'prop_woodpile_01b' est present
-- dans le flux de base, pas besoin de streaming custom.
local BARRICADE_MODEL = 'prop_woodpile_01b'

local placedBarricades = {}
local requesting = false -- evite double-clic / spam command pendant un request.

local function spawnBarricadeProp()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local fwd = GetEntityForwardVector(ped)
    local pos = coords + fwd * 1.2

    local hash = GetHashKey(BARRICADE_MODEL)
    RequestModel(hash)
    local t0 = GetGameTimer()
    while not HasModelLoaded(hash) do
        Wait(50)
        if GetGameTimer() - t0 > 3000 then
            SetModelAsNoLongerNeeded(hash)
            frzCore:notify('Echec du placement (prop non charge).')
            -- L'item a deja ete consomme cote serveur : on refund.
            TriggerServerEvent('frz-craft:barricadeSpawnFailed')
            return
        end
    end

    local obj = CreateObject(hash, pos.x, pos.y, pos.z - 0.5, true, true, false)
    SetEntityHeading(obj, heading)
    PlaceObjectOnGroundProperly(obj)
    FreezeEntityPosition(obj, true)
    SetModelAsNoLongerNeeded(hash)

    placedBarricades[#placedBarricades + 1] = obj
    -- Ferme la fenetre de refund cote serveur : placement reussi.
    TriggerServerEvent('frz-craft:barricadePlaced')
    frzCore:notify('Barricade posee.')
end

local function placeBarricade()
    if requesting then return end
    -- Check local rapide (purement UX : le serveur re-verifie).
    if not frzCore:hasItem('barricade', 1) then
        frzCore:notify('Tu n as pas de barricade. Craft une : /craft barricade')
        return
    end
    requesting = true
    TriggerServerEvent('frz-craft:requestBarricade')
end

-- Le serveur confirme si on peut poser. On ne spawn le prop qu'ici.
RegisterNetEvent('frz-craft:barricadeResult', function(ok, msg)
    requesting = false
    if ok then
        spawnBarricadeProp()
    else
        frzCore:notify(msg or 'Impossible de poser la barricade.')
    end
end)

RegisterCommand('placebarricade', function() placeBarricade() end, false)
TriggerEvent('chat:addSuggestion', '/placebarricade', 'Pose une barricade devant toi')

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, obj in ipairs(placedBarricades) do
        if DoesEntityExist(obj) then DeleteEntity(obj) end
    end
    placedBarricades = {}
end)
