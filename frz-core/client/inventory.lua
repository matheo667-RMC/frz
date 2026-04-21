-- FRZ RP (frz-core) - Cache local de l'inventaire + commande /inv.
-- Affiche l'inventaire dans le chat (standalone, pas de menu NUI ici pour
-- rester minimal : un menu NUI complet pourra etre ajoute plus tard).

FrzCore = FrzCore or {}
FrzCore.Client = FrzCore.Client or {}

local inventory = {}

RegisterNetEvent('frz-core:syncInventory', function(newInv)
    if type(newInv) ~= 'table' then return end
    inventory = {}
    for k, v in pairs(newInv) do inventory[k] = v end
end)

function FrzCore.Client.getInventory()
    local out = {}
    for k, v in pairs(inventory) do out[k] = v end
    return out
end

function FrzCore.Client.hasItem(id, count)
    count = count or 1
    return (inventory[id] or 0) >= count
end

local function label(id)
    return FrzCore.Config.ItemLabels[id] or id
end

local function totalWeight()
    local w = 0.0
    for id, qty in pairs(inventory) do
        local per = FrzCore.Config.ItemWeights[id] or FrzCore.Config.DefaultItemWeight
        w = w + per * qty
    end
    return w
end

RegisterCommand('inv', function()
    local keys = {}
    for id, _ in pairs(inventory) do keys[#keys + 1] = id end
    table.sort(keys)

    TriggerEvent('chat:addMessage', {
        color = { 180, 220, 255 },
        multiline = false,
        args = { 'Inventaire', string.format('%.1f / %.1f kg', totalWeight(), FrzCore.Config.MaxInventoryWeight) },
    })
    if #keys == 0 then
        TriggerEvent('chat:addMessage', {
            color = { 180, 180, 180 },
            args = { 'Inventaire', '(vide)' },
        })
        return
    end
    for _, id in ipairs(keys) do
        TriggerEvent('chat:addMessage', {
            color = { 200, 200, 200 },
            args = { label(id), tostring(inventory[id]) },
        })
    end
end, false)

TriggerEvent('chat:addSuggestion', '/inv', 'Afficher ton inventaire FRZ RP')

exports('getInventory', FrzCore.Client.getInventory)
exports('hasItem', FrzCore.Client.hasItem)
