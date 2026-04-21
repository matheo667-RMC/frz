-- Dead Zone RP (frz-safezones) - Detection de zone : on calcule en continu la
-- safezone courante (celle qui contient le joueur, la plus petite en cas
-- d overlap) et on expose getCurrentZone() aux autres modules.

FrzSafeZones = FrzSafeZones or {}
FrzSafeZones.Client = FrzSafeZones.Client or {}

local currentZone = nil

local function findCurrentZone()
    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then return nil end
    local coords = GetEntityCoords(ped)

    local best, bestRadius
    for _, zone in ipairs(FrzSafeZones.Config.Zones) do
        if #(coords - zone.center) <= zone.radius then
            if not best or zone.radius < bestRadius then
                best, bestRadius = zone, zone.radius
            end
        end
    end
    return best
end

function FrzSafeZones.Client.getCurrentZone()
    return currentZone
end

function FrzSafeZones.Client.isInSafeZone()
    return currentZone ~= nil
end

CreateThread(function()
    while true do
        Wait(1000)
        local zone = findCurrentZone()
        if zone ~= currentZone then
            local previous = currentZone
            currentZone = zone
            TriggerEvent('frz-safezones:changed', zone, previous)
        end
    end
end)

exports('getCurrentZone', FrzSafeZones.Client.getCurrentZone)
exports('isInSafeZone', FrzSafeZones.Client.isInSafeZone)
