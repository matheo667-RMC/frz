-- Dead Zone RP (frz-survival) - Serveur : progression autonome de l'infection.
-- Cette boucle etait auparavant cote client (frz-survival/client/ticks.lua)
-- mais elle devenait impossible a concilier avec des consommables qui
-- DIMINUENT l'infection (antibiotiques, medkit) : le tick client rebumpait
-- aussitot la valeur et le push ecrasait le serveur.
--
-- En pilotant le tick cote serveur, la progression est naturellement
-- persistee et les antibiotiques peuvent reellement baisser la stat sans
-- etre "annules" par un push client stale.

CreateThread(function()
    while true do
        Wait(FrzSurvival.Config.TickInterval or 60000)
        local per = FrzSurvival.Config.InfectionPerTick or 1.0
        if per > 0 then
            for _, pidStr in ipairs(GetPlayers()) do
                local src = tonumber(pidStr)
                if src then
                    local stats = exports['frz-core']:getStats(src)
                    if stats and (stats.infection or 0) > 0 and (stats.infection or 0) < 100 then
                        exports['frz-core']:addStat(src, 'infection', per)
                    end
                end
            end
        end
    end
end)
