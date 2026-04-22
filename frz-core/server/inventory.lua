-- Dead Zone RP (frz-core) - Inventaire serveur (standalone, sans ESX/QBCore).
-- Format de l'inventaire : table { [itemId:string] = count:int }.
-- La capacite maximum est exprimee en kg via FrzCore.Config.ItemWeights.

FrzCore = FrzCore or {}
FrzCore.Server = FrzCore.Server or {}

local function itemWeight(id)
    return FrzCore.Config.ItemWeights[id] or FrzCore.Config.DefaultItemWeight
end

local function totalWeight(inv)
    local w = 0.0
    for id, qty in pairs(inv) do
        w = w + (itemWeight(id) * qty)
    end
    return w
end

local function getInventoryForSource(src)
    local id = FrzCore.Server.getIdentifier(src)
    if not id then return nil end
    local rec = FrzCore.Server.getRecord(id)
    return rec and rec.inventory or nil
end

local function sync(src, inv)
    TriggerClientEvent('frz-core:syncInventory', src, inv)
end

function FrzCore.Server.getInventory(src)
    local inv = getInventoryForSource(src)
    if not inv then return nil end
    local out = {}
    for k, v in pairs(inv) do out[k] = v end
    return out
end

function FrzCore.Server.hasItem(src, itemId, count)
    count = count or 1
    local inv = getInventoryForSource(src)
    if not inv then return false end
    return (inv[itemId] or 0) >= count
end

function FrzCore.Server.giveItem(src, itemId, count)
    count = count or 1
    if count <= 0 then return false end
    local inv = getInventoryForSource(src)
    if not inv then return false end
    local projected = totalWeight(inv) + (itemWeight(itemId) * count)
    if projected > FrzCore.Config.MaxInventoryWeight then
        -- Notifie le client (message dans le chat) et refuse.
        TriggerClientEvent('frz-core:notify', src, 'Inventaire plein (' .. string.format('%.1f', projected) .. ' / ' .. FrzCore.Config.MaxInventoryWeight .. ' kg)')
        return false
    end
    inv[itemId] = (inv[itemId] or 0) + count
    FrzCore.Server.markDirty()
    sync(src, inv)
    return true
end

function FrzCore.Server.takeItem(src, itemId, count)
    count = count or 1
    if count <= 0 then return false end
    local inv = getInventoryForSource(src)
    if not inv then return false end
    if (inv[itemId] or 0) < count then return false end
    inv[itemId] = inv[itemId] - count
    if inv[itemId] <= 0 then inv[itemId] = nil end
    FrzCore.Server.markDirty()
    sync(src, inv)
    return true
end

-- Evenement client pour demander la consommation d'un item. On delegue la
-- logique (bouffer / boire / soigner) a frz-survival via un event serveur.
RegisterNetEvent('frz-core:useItem', function(itemId)
    local src = source
    if type(itemId) ~= 'string' then return end
    -- On ne retire PAS l'item ici : c'est frz-survival qui decide si l'action
    -- est possible (cooldown, etc.) puis appelle takeItem via export.
    TriggerEvent('frz-core:onUseItem', src, itemId)
end)

exports('getInventory', FrzCore.Server.getInventory)
exports('hasItem', FrzCore.Server.hasItem)
exports('giveItem', FrzCore.Server.giveItem)
exports('takeItem', FrzCore.Server.takeItem)
