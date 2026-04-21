-- FRZ RP (frz-walkers) - Detection des morsures.
-- Quand un rodeur est a portee courte du joueur et fait une animation de
-- melee, on declenche l'infection cote serveur (anti-cheat : le serveur
-- verifie qu'il y a bien un rodeur a portee via frz-walkers:validateBite).

FrzWalkers = FrzWalkers or {}
FrzWalkers.Client = FrzWalkers.Client or {}

CreateThread(function()
    while true do
        Wait(500)
        local player = PlayerPedId()
        if DoesEntityExist(player) and not IsPedDeadOrDying(player, true) then
            local pcoords = GetEntityCoords(player)
            local now = GetGameTimer()

            for walker, meta in pairs(FrzWalkers.Client.active) do
                if DoesEntityExist(walker) and not IsPedDeadOrDying(walker, true) then
                    local wcoords = GetEntityCoords(walker)
                    local dist = #(wcoords - pcoords)

                    if dist <= FrzWalkers.Config.BiteRange
                       and now - (meta.lastBiteAt or 0) >= FrzWalkers.Config.BiteCooldown then
                        meta.lastBiteAt = now

                        -- Joue l'animation de morsure cote rodeur.
                        local dict = 'melee@unarmed@streamed_core'
                        RequestAnimDict(dict)
                        local t0 = GetGameTimer()
                        while not HasAnimDictLoaded(dict) and GetGameTimer() - t0 < 800 do Wait(20) end
                        if HasAnimDictLoaded(dict) then
                            TaskPlayAnim(walker, dict, 'heavy_punch_a', 8.0, -8.0, 900, 49, 0, false, false, false)
                        end

                        -- Le serveur valide via sync.lua puis re-emet onBite.
                        TriggerServerEvent('frz-walkers:bite')
                        -- Degats HP natifs (le rodeur frappe aussi).
                        ApplyDamageToPed(player, FrzWalkers.Config.WalkerMeleeDamage, false)
                    end
                end
            end
        end
    end
end)
