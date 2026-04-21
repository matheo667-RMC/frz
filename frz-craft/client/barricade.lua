-- Dead Zone RP (frz-craft) - Pose de barricades.
-- Quand le joueur a un item 'barricade' et utilise /placebarricade, on spawn
-- un prop de planche de bois devant lui et on consomme l'item.

FrzCraft = FrzCraft or {}
FrzCraft.Client = FrzCraft.Client or {}

local frzCore = exports['frz-core']

-- Modele de prop utilise pour la barricade. 'prop_woodpile_01b' est present
-- dans le flux de base, pas besoin de streaming custom.
local BARRICADE_MODEL = 'prop_woodpile_01b'

local placedBarricades = {}

local function placeBarricade()
    if not frzCore:hasItem('barricade', 1) then
        frzCore:notify('Tu n as pas de barricade. Craft une : /craft barricade')
        return
    end
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
            return
        end
    end
    local obj = CreateObject(hash, pos.x, pos.y, pos.z - 0.5, true, true, false)
    SetEntityHeading(obj, heading)
    PlaceObjectOnGroundProperly(obj)
    FreezeEntityPosition(obj, true)
    SetModelAsNoLongerNeeded(hash)

    placedBarricades[#placedBarricades + 1] = obj
    TriggerServerEvent('frz-craft:consumeBarricade')
    frzCore:notify('Barricade posee.')
end

RegisterCommand('placebarricade', function() placeBarricade() end, false)
TriggerEvent('chat:addSuggestion', '/placebarricade', 'Pose une barricade devant toi')

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, obj in ipairs(placedBarricades) do
        if DoesEntityExist(obj) then DeleteEntity(obj) end
    end
    placedBarricades = {}
end)
