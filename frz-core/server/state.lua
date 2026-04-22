-- Dead Zone RP (frz-core) - Gestion serveur des stats de survie.
-- Ces stats sont lues/ecrites par frz-survival (ticks faim/soif), frz-walkers
-- (morsures -> infection), frz-loot (consommation d'items), etc.

FrzCore = FrzCore or {}
FrzCore.Server = FrzCore.Server or {}

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function getRecordForSource(src)
    local id = FrzCore.Server.getIdentifier(src)
    if not id then return nil end
    return FrzCore.Server.getRecord(id)
end

function FrzCore.Server.getStats(src)
    local rec = getRecordForSource(src)
    if not rec then return nil end
    -- Renvoie une copie pour eviter les modifications externes accidentelles.
    local out = {}
    for k, v in pairs(rec.stats) do out[k] = v end
    return out
end

-- Met a jour une stat (valeur absolue) ou la delta (si `delta` fourni).
-- `stat` : 'hunger' | 'thirst' | 'fatigue' | 'infection'
function FrzCore.Server.setStat(src, stat, value)
    local rec = getRecordForSource(src)
    if not rec then return false end
    rec.stats[stat] = clamp(value, 0, 100)
    FrzCore.Server.markDirty()
    TriggerClientEvent('frz-core:syncStats', src, rec.stats)
    return true
end

function FrzCore.Server.addStat(src, stat, delta)
    local rec = getRecordForSource(src)
    if not rec then return false end
    rec.stats[stat] = clamp((rec.stats[stat] or 0) + delta, 0, 100)
    FrzCore.Server.markDirty()
    TriggerClientEvent('frz-core:syncStats', src, rec.stats)
    return true
end

-- Sync initial : le client demande son etat au spawn.
RegisterNetEvent('frz-core:requestState', function()
    local src = source
    local rec = getRecordForSource(src)
    if not rec then return end
    TriggerClientEvent('frz-core:syncStats', src, rec.stats)
    TriggerClientEvent('frz-core:syncInventory', src, rec.inventory)
end)

-- Sync push : le client envoie son etat courant (ticks de faim/soif calcules
-- cote client par frz-survival, pour eviter d'alourdir le serveur a 60 Hz).
--
-- /!\ L'infection est FULL server-authoritative : bites (frz-walkers),
-- progression passive (frz-survival/server/tick.lua) et antibiotiques/medkits
-- (frz-survival/server/consume.lua) passent tous par addStat. Le client ne
-- fait que refleter syncStats, il ne push JAMAIS sa copie au serveur,
-- sinon :
--   - une valeur stale post-bite reset l'infection a l'ancienne valeur
--   - un antibiotique (-50) est annule par le push client qui envoie encore
--     l'ancienne valeur haute
-- => on ignore purement et simplement infection dans pushStats.
local CLIENT_PUSH_IGNORED = { infection = true }

RegisterNetEvent('frz-core:pushStats', function(stats)
    local src = source
    local rec = getRecordForSource(src)
    if not rec or type(stats) ~= 'table' then return end
    for k, v in pairs(stats) do
        if type(v) == 'number' and rec.stats[k] ~= nil and not CLIENT_PUSH_IGNORED[k] then
            rec.stats[k] = clamp(v, 0, 100)
        end
    end
    FrzCore.Server.markDirty()
end)

exports('getStats', FrzCore.Server.getStats)
exports('setStat', FrzCore.Server.setStat)
exports('addStat', FrzCore.Server.addStat)
