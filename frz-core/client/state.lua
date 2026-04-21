-- FRZ RP (frz-core) - Cache local de l'etat joueur + exports client.
-- Les autres ressources (survival, walkers, loot...) lisent l'etat via ces
-- exports plutot que de dupliquer la logique de synchro.

FrzCore = FrzCore or {}
FrzCore.Client = FrzCore.Client or {}

local stats = {}
local inventory = {}
local ready = false

for k, v in pairs(FrzCore.Config.DefaultStats) do stats[k] = v end

RegisterNetEvent('frz-core:syncStats', function(newStats)
    if type(newStats) ~= 'table' then return end
    for k, v in pairs(newStats) do
        stats[k] = v
    end
    ready = true
end)

RegisterNetEvent('frz-core:syncInventory', function(newInv)
    if type(newInv) ~= 'table' then return end
    -- Remplacement complet (le serveur est source de verite).
    inventory = {}
    for k, v in pairs(newInv) do inventory[k] = v end
end)

function FrzCore.Client.getStat(name)
    return stats[name]
end

function FrzCore.Client.getStats()
    local out = {}
    for k, v in pairs(stats) do out[k] = v end
    return out
end

function FrzCore.Client.setStatLocal(name, value)
    -- Les ticks de survie modifient localement puis pushent au serveur tous
    -- les FrzCore.Config.StateSyncInterval ms (voir frz-survival).
    if value < 0 then value = 0 end
    if value > 100 then value = 100 end
    stats[name] = value
end

function FrzCore.Client.isReady()
    return ready
end

-- Demande son etat au serveur une fois le player actif.
CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do Wait(250) end
    while not DoesEntityExist(PlayerPedId()) do Wait(250) end
    Wait(500)
    TriggerServerEvent('frz-core:requestState')
end)

-- Push periodique : envoie l'etat local au serveur pour persistance.
CreateThread(function()
    while true do
        Wait(FrzCore.Config.StateSyncInterval or 30000)
        if ready then
            TriggerServerEvent('frz-core:pushStats', stats)
        end
    end
end)

exports('getStat', FrzCore.Client.getStat)
exports('getStats', FrzCore.Client.getStats)
exports('setStatLocal', FrzCore.Client.setStatLocal)
exports('isReady', FrzCore.Client.isReady)
