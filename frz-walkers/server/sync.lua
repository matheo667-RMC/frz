-- FRZ RP (frz-walkers) - Serveur : relaie les morsures aux ressources de
-- survie (frz-survival) et expose une kill-count par joueur (utile pour des
-- scoreboards futurs).

local killsByIdentifier = {} -- { [identifier] = int }

-- Anti-spam tres simple : un joueur ne peut pas etre mordu plus d'une fois
-- par seconde, meme si plusieurs clients trigger l'event en rafale (ex: lag,
-- triche). Si tu veux une validation spatiale plus forte, tu peux y ajouter
-- un check contre la position des peds... mais comme les rodeurs sont gerees
-- cote client, le serveur n'a pas la verite du monde. Le cooldown suffit.
local lastBiteAt = {}

RegisterNetEvent('frz-walkers:bite', function()
    local src = source
    local now = GetGameTimer()
    if (now - (lastBiteAt[src] or 0)) < 1000 then return end
    lastBiteAt[src] = now

    TriggerClientEvent('frz-survival:onBite', src)
end)

RegisterNetEvent('frz-walkers:walkerKilled', function()
    local src = source
    local id = exports['frz-core']:getIdentifier(src)
    if not id then return end
    killsByIdentifier[id] = (killsByIdentifier[id] or 0) + 1
end)

-- Commande admin : affiche le top 10 tueurs de rodeurs dans la console.
RegisterCommand('frzwalkerkills', function(source)
    if source ~= 0 then return end
    local list = {}
    for id, count in pairs(killsByIdentifier) do
        list[#list + 1] = { id = id, count = count }
    end
    table.sort(list, function(a, b) return a.count > b.count end)
    print('[frz-walkers] Top tueurs de rodeurs :')
    for i = 1, math.min(10, #list) do
        print(('  %2d. %s : %d'):format(i, list[i].id, list[i].count))
    end
end, true)

exports('getKills', function(src)
    local id = exports['frz-core']:getIdentifier(src)
    return id and (killsByIdentifier[id] or 0) or 0
end)
