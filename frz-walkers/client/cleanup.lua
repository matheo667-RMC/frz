-- Dead Zone RP (frz-walkers) - Cleanup des rodeurs hors de portee ou morts.
-- Libere la memoire cote client et empeche une accumulation infinie.

FrzWalkers = FrzWalkers or {}

CreateThread(function()
    while true do
        Wait(3000)
        local player = PlayerPedId()
        local pcoords = GetEntityCoords(player)

        for walker, _ in pairs(FrzWalkers.Client.active) do
            local remove = false
            if not DoesEntityExist(walker) then
                remove = true
            else
                local wcoords = GetEntityCoords(walker)
                if #(wcoords - pcoords) > FrzWalkers.Config.DespawnDistance then
                    remove = true
                elseif IsPedDeadOrDying(walker, true) then
                    -- Laisse le cadavre 30s (pour le loot via frz-loot) puis despawn.
                    local timeDead = GetGameTimer() - (FrzWalkers.Client.active[walker].diedAt or 0)
                    if not FrzWalkers.Client.active[walker].diedAt then
                        FrzWalkers.Client.active[walker].diedAt = GetGameTimer()
                    elseif timeDead > 30000 then
                        remove = true
                    end
                end
            end

            if remove then
                if DoesEntityExist(walker) then
                    DeleteEntity(walker)
                end
                FrzWalkers.Client.active[walker] = nil
            end
        end
    end
end)

-- Au stop de la ressource, supprime tous les rodeurs pour ne pas laisser
-- de peds orphelins dans le monde.
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for walker, _ in pairs(FrzWalkers.Client.active or {}) do
        if DoesEntityExist(walker) then
            DeleteEntity(walker)
        end
    end
    FrzWalkers.Client.active = {}
end)
