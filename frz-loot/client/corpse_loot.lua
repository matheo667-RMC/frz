-- Dead Zone RP (frz-loot) - Loot sur les cadavres de rodeurs.
-- Les rodeurs morts sont gardes 30s par frz-walkers/cleanup.lua. Pendant ce
-- delai, le joueur peut les fouiller.

FrzLoot = FrzLoot or {}
FrzLoot.Client = FrzLoot.Client or {}

local frzCore = exports['frz-core']

local searched = {} -- { [pedHandle] = true }

-- Meme pattern que world_containers.lua : scan lent puis passage en per-frame
-- des qu'un cadavre est a portee (sinon le prompt flicke et la touche E est
-- ratee a 97%).
CreateThread(function()
    local sleep = 500
    while true do
        Wait(sleep)
        sleep = 500

        local player = PlayerPedId()
        if DoesEntityExist(player) and not IsPedDeadOrDying(player, true) then
            local pcoords = GetEntityCoords(player)
            -- frz-walkers expose les rodeurs actifs via un export (VM Lua
            -- isolee, on ne peut pas lire FrzWalkers.Client.active directement).
            local walkers = exports['frz-walkers']:getActiveWalkers() or {}
            for walker, _ in pairs(walkers) do
                if DoesEntityExist(walker) and IsPedDeadOrDying(walker, true) and not searched[walker] then
                    local d = #(GetEntityCoords(walker) - pcoords)
                    if d <= 1.8 then
                        sleep = 0
                        local c = GetEntityCoords(walker)
                        frzCore:drawText3D(c.x, c.y, c.z + 0.3, '[E] Fouiller le corps')
                        if IsControlJustReleased(0, 38) then
                            searched[walker] = true
                            -- Tag le kill pour les stats serveur.
                            TriggerServerEvent('frz-walkers:walkerKilled')
                            -- Tire le loot du corps.
                            TriggerServerEvent('frz-loot:searchCorpse')
                        end
                    end
                end
            end
        end
    end
end)

-- Purge la table searched de temps en temps (les handles peuvent etre reutilises).
CreateThread(function()
    while true do
        Wait(30000)
        for ped, _ in pairs(searched) do
            if not DoesEntityExist(ped) then searched[ped] = nil end
        end
    end
end)
