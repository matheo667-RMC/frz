-- FRZ RP (frz-safezones) - Bridge vers frz-walkers : pousse les zones dans
-- la table NoSpawnZones de frz-walkers pour empecher les spawns de rodeurs
-- dans les safe zones. Fait une seule fois au demarrage, ainsi que sur
-- changement de zone (pour debug).

CreateThread(function()
    -- Attend que frz-walkers soit demarre.
    while GetResourceState('frz-walkers') ~= 'started' do Wait(500) end
    Wait(500)

    if not FrzWalkers or not FrzWalkers.Config then
        -- frz-walkers existe mais sa config n'est pas encore chargee. On poll.
        local t0 = GetGameTimer()
        while (not FrzWalkers or not FrzWalkers.Config) and GetGameTimer() - t0 < 10000 do
            Wait(500)
        end
    end

    if not FrzWalkers or not FrzWalkers.Config then return end

    FrzWalkers.Config.NoSpawnZones = FrzWalkers.Config.NoSpawnZones or {}
    for _, zone in ipairs(FrzSafeZones.Config.Zones) do
        table.insert(FrzWalkers.Config.NoSpawnZones, {
            center = zone.center,
            radius = zone.radius,
        })
    end
end)
