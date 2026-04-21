-- FRZ RP (frz-safezones) - Indicateurs visuels (blips map + notifs) quand
-- on entre / sort d'une zone refuge.

FrzSafeZones = FrzSafeZones or {}
FrzSafeZones.Client = FrzSafeZones.Client or {}

local frzCore = exports['frz-core']

-- Pose un blip sur la map pour chaque zone des que la ressource demarre.
CreateThread(function()
    Wait(1000)
    for _, zone in ipairs(FrzSafeZones.Config.Zones) do
        local blip = AddBlipForRadius(zone.center.x, zone.center.y, zone.center.z, zone.radius)
        SetBlipColour(blip, 2)
        SetBlipAlpha(blip, 80)

        local icon = AddBlipForCoord(zone.center.x, zone.center.y, zone.center.z)
        SetBlipSprite(icon, 488) -- shield icon
        SetBlipColour(icon, 2)
        SetBlipAsShortRange(icon, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(zone.label)
        EndTextCommandSetBlipName(icon)
    end
end)

AddEventHandler('frz-safezones:changed', function(zone, previous)
    if zone and not previous then
        frzCore:notify('Entree dans une zone refuge : ' .. zone.label)
    elseif previous and not zone then
        frzCore:notify('Sortie de la zone refuge : ' .. previous.label)
    elseif zone and previous and zone.id ~= previous.id then
        frzCore:notify('Changement de zone refuge : ' .. zone.label)
    end
end)
