-- Dead Zone RP (frz-safezones) - Bridge vers frz-walkers : enregistre les
-- safe zones comme NoSpawnZones pour empecher les spawns de rodeurs dedans.
-- On passe par un export (et pas par la global FrzWalkers.Config) car
-- chaque ressource FiveM a sa propre VM Lua isolee.

CreateThread(function()
    -- Attend que frz-walkers soit demarre avant d'appeler son export.
    while GetResourceState('frz-walkers') ~= 'started' do Wait(500) end
    Wait(500)

    for _, zone in ipairs(FrzSafeZones.Config.Zones) do
        exports['frz-walkers']:addNoSpawnZone(zone.center, zone.radius)
    end
end)
