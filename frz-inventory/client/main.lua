-- FRZ Inventaire - client principal
-- Ouverture NUI, sync slots, application des vetements (drawables GTA5).

local isOpen = false
local inventory = {
    grid = {},      -- slot_index -> { name, count }
    clothing = {},  -- slot_key -> { name, drawable, texture, palette }
}

-- ============================================================================
-- Application des vetements sur le ped
-- ============================================================================

local function applyClothingToPed()
    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then return end

    for slotKey, slot in pairs(Config.ClothingSlots) do
        local equipped = inventory.clothing[slotKey]
        if equipped and equipped.drawable ~= nil then
            if slot.component ~= nil then
                SetPedComponentVariation(ped, slot.component, equipped.drawable, equipped.texture or 0, equipped.palette or 0)
            elseif slot.prop ~= nil then
                SetPedPropIndex(ped, slot.prop, equipped.drawable, equipped.texture or 0, true)
            end
        else
            -- Slot vide : retire le prop s'il y en a un (les components ont un defaut par ped,
            -- on ne les force pas sauf mask/undershirt/torso pour le style).
            if slot.prop ~= nil then
                ClearPedProp(ped, slot.prop)
            end
        end
    end
end

-- ============================================================================
-- Ouverture / fermeture de l'UI NUI
-- ============================================================================

local function buildPayload()
    local slots = {}
    for key, meta in pairs(Config.ClothingSlots) do
        slots[#slots+1] = { key = key, label = meta.label }
    end
    return {
        action = 'open',
        grid = inventory.grid,
        clothing = inventory.clothing,
        rows = Config.GridRows,
        cols = Config.GridCols,
        clothingSlots = slots,
        items = Items,
        maxWeight = Config.MaxWeight,
    }
end

local function openInventory()
    if isOpen then return end
    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage(buildPayload())
end

local function closeInventory()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterNUICallback('close', function(_, cb)
    closeInventory()
    cb({ ok = true })
end)

-- Demande au serveur : l'UI a demande un move/drop/equip. Le serveur est autoritatif.
local function nuiAction(payload)
    TriggerServerEvent('frz-inventory:action', payload)
end

RegisterNUICallback('move', function(data, cb)
    nuiAction({ type = 'move', from = data.from, to = data.to })
    cb({ ok = true })
end)

RegisterNUICallback('drop', function(data, cb)
    nuiAction({ type = 'drop', from = data.from, count = data.count or 1 })
    cb({ ok = true })
end)

RegisterNUICallback('equip', function(data, cb)
    nuiAction({ type = 'equip', from = data.from, slotKey = data.slotKey })
    cb({ ok = true })
end)

RegisterNUICallback('unequip', function(data, cb)
    nuiAction({ type = 'unequip', slotKey = data.slotKey })
    cb({ ok = true })
end)

RegisterNUICallback('use', function(data, cb)
    nuiAction({ type = 'use', from = data.from })
    cb({ ok = true })
end)

-- Le serveur renvoie l'etat complet a chaque modification : simple, robuste, evite
-- les desyncs entre les callbacks concurrents.
RegisterNetEvent('frz-inventory:setState', function(state)
    inventory.grid = state.grid or {}
    inventory.clothing = state.clothing or {}
    applyClothingToPed()
    if isOpen then
        SendNUIMessage({
            action = 'update',
            grid = inventory.grid,
            clothing = inventory.clothing,
        })
    end
end)

RegisterNetEvent('frz-inventory:notify', function(msg, type)
    SendNUIMessage({ action = 'notify', message = msg, type = type or 'info' })
end)

-- ============================================================================
-- Keybinding
-- ============================================================================

RegisterCommand('frz_inventory_open', function()
    if isOpen then
        closeInventory()
    else
        openInventory()
    end
end, false)

RegisterKeyMapping('frz_inventory_open', 'Ouvrir FRZ Inventaire', 'keyboard', Config.OpenKey or 'I')

-- ESC ferme via le NUI (gere cote JS) - on expose une commande backup.
RegisterCommand('frz_inventory_close', closeInventory, false)

-- Demande l'etat au spawn.
AddEventHandler('playerSpawned', function()
    TriggerServerEvent('frz-inventory:requestState')
end)

CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do Wait(200) end
    Wait(500)
    TriggerServerEvent('frz-inventory:requestState')
end)

-- Reapplique les vetements periodiquement (apres respawn, changement de ped ESX, etc.)
CreateThread(function()
    while true do
        Wait(5000)
        if next(inventory.clothing) ~= nil then
            applyClothingToPed()
        end
    end
end)

-- Export consomme par d'autres resources (frz-phone/frz-bank).
exports('hasItem', function(itemName, minCount)
    minCount = minCount or 1
    local total = 0
    for _, item in pairs(inventory.grid) do
        if item and item.name == itemName then
            total = total + (item.count or 0)
            if total >= minCount then return true end
        end
    end
    return false
end)

exports('getInventory', function()
    return { grid = inventory.grid, clothing = inventory.clothing }
end)
