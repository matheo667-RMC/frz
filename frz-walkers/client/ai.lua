-- Dead Zone RP (frz-walkers) - IA secondaire : re-aggro les rodeurs qui ont perdu
-- leur cible, et met a jour leur comportement (melee agressif, pas de fuite).

FrzWalkers = FrzWalkers or {}
FrzWalkers.Client = FrzWalkers.Client or {}

CreateThread(function()
    while true do
        Wait(2000)
        local player = PlayerPedId()
        local pcoords = GetEntityCoords(player)

        for walker, _ in pairs(FrzWalkers.Client.active) do
            if DoesEntityExist(walker) and not IsPedDeadOrDying(walker, true) then
                local wcoords = GetEntityCoords(walker)
                local dist = #(wcoords - pcoords)
                if dist <= FrzWalkers.Config.DetectionRange then
                    local target = GetPedTargetFromCombatPed(walker, 0)
                    if not target or target == 0 or target ~= player then
                        TaskCombatPed(walker, player, 0, 16)
                    end
                end
            end
        end
    end
end)
