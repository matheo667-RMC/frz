-- Dead Zone RP (frz-loot) - Handlers des events de fouille cote serveur.

local frzCore = exports['frz-core']
local frzLoot = exports['frz-loot']

-- Anti-spam : un joueur ne peut pas fouiller plus d'une fois toutes les
-- FrzLoot.Config.SearchDuration - 500 ms (la duree de l'anim). Evite le
-- triggers en rafale si un client est triche.
local lastSearchAt = {}
local function tooFast(src)
    local now = GetGameTimer()
    local last = lastSearchAt[src] or 0
    local cd = math.max(1000, (FrzLoot.Config.SearchDuration or 3500) - 500)
    if now - last < cd then return true end
    lastSearchAt[src] = now
    return false
end

local function award(src, loot)
    local given = {}
    for _, entry in ipairs(loot) do
        if frzCore:giveItem(src, entry.item, entry.count) then
            given[#given + 1] = entry
        end
    end
    TriggerClientEvent('frz-loot:result', src, given)
end

RegisterNetEvent('frz-loot:searchContainer', function(kind, modelName)
    local src = source
    if tooFast(src) then return end
    if type(kind) ~= 'string' then return end
    if not FrzLoot.Config.LootTables[kind] then return end

    local loot = FrzLoot.Server.rollTable(kind)
    award(src, loot)
end)

RegisterNetEvent('frz-loot:searchCorpse', function()
    local src = source
    if tooFast(src) then return end
    if math.random() > (FrzLoot.Config.CorpseLootChance or 0.6) then
        TriggerClientEvent('frz-loot:result', src, {})
        return
    end
    local loot = FrzLoot.Server.rollTable('corpse')
    award(src, loot)
end)
