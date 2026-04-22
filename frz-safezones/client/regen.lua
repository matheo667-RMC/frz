-- Dead Zone RP (frz-safezones) - Regen lente dans une safe zone (HP + faim + soif).
-- Utilise les exports frz-core pour rester standalone.

FrzSafeZones = FrzSafeZones or {}
FrzSafeZones.Client = FrzSafeZones.Client or {}

local frzCore = exports['frz-core']

CreateThread(function()
    while true do
        Wait(FrzSafeZones.Config.RegenInterval)
        local zone = FrzSafeZones.Client.getCurrentZone()
        if zone then
            if zone.slowHeal then
                local ped = PlayerPedId()
                local maxHp = GetEntityMaxHealth(ped)
                local hp = GetEntityHealth(ped)
                if hp > 0 and hp < maxHp then
                    SetEntityHealth(ped, math.min(maxHp, hp + FrzSafeZones.Config.HealPerTick))
                end
            end

            local stats = frzCore:getStats()
            if zone.restoreHunger and zone.restoreHunger > 0 then
                frzCore:setStatLocal('hunger', (stats.hunger or 0) + zone.restoreHunger)
            end
            if zone.restoreThirst and zone.restoreThirst > 0 then
                frzCore:setStatLocal('thirst', (stats.thirst or 0) + zone.restoreThirst)
            end
        end
    end
end)
