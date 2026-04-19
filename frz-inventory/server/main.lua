-- FRZ Inventaire - serveur principal
-- Stockage : fichier JSON dans le dossier de la resource (standalone, pas de DB).
-- `json` est fourni par Cfx (global) : encode/decode.

-- ============================================================================
-- Persistance
-- ============================================================================

local INVENTORIES = {}  -- identifier -> { grid = {[slot] = {name, count}}, clothing = {} }

local function getIdentifier(src)
    -- On prend le premier identifiant "license:" disponible ; fallback steam puis ip.
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:match('^license:') then return id end
    end
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:match('^steam:') then return id end
    end
    return 'ip:' .. (GetPlayerEndpoint(src) or tostring(src))
end

local function savePersistence()
    local data = json.encode(INVENTORIES)
    SaveResourceFile(GetCurrentResourceName(), Config.PersistenceFile, data, -1)
end

local function loadPersistence()
    local raw = LoadResourceFile(GetCurrentResourceName(), Config.PersistenceFile)
    if raw and raw ~= '' then
        local ok, parsed = pcall(json.decode, raw)
        if ok and type(parsed) == 'table' then
            INVENTORIES = parsed
        end
    end
end

loadPersistence()

-- Save periodique + sur shutdown.
CreateThread(function()
    while true do
        Wait(60000)
        savePersistence()
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then savePersistence() end
end)

-- ============================================================================
-- Helpers inventaire
-- ============================================================================

local function ensureInventory(id)
    if INVENTORIES[id] then return INVENTORIES[id] end
    local inv = { grid = {}, clothing = {} }
    for _, it in ipairs(Config.StartingInventory or {}) do
        inv.grid[tostring(it.slot)] = { name = it.name, count = it.count }
    end
    for slotKey, slot in pairs(Config.StartingClothing or {}) do
        inv.clothing[slotKey] = slot
    end
    INVENTORIES[id] = inv
    return inv
end

local function totalWeight(inv)
    local w = 0
    for _, item in pairs(inv.grid) do
        if item and item.name then
            local meta = Items[item.name]
            if meta then w = w + (meta.weight or 0) * (item.count or 1) end
        end
    end
    return w
end

local function sendState(src)
    local id = getIdentifier(src)
    local inv = ensureInventory(id)
    TriggerClientEvent('frz-inventory:setState', src, inv)
end

local function notify(src, msg, type)
    TriggerClientEvent('frz-inventory:notify', src, msg, type)
end

-- ============================================================================
-- API exports (autres resources)
-- ============================================================================

local function addItem(src, itemName, count, targetSlot)
    count = count or 1
    if not Items[itemName] then return false, 'item inconnu' end
    local id = getIdentifier(src)
    local inv = ensureInventory(id)
    local meta = Items[itemName]

    -- Verification de poids AVANT toute mutation.
    if Config.MaxWeight > 0 then
        local projected = totalWeight(inv) + (meta.weight or 0) * count
        if projected > Config.MaxWeight then return false, 'trop lourd' end
    end

    -- On prepare la liste des mutations puis on l'applique atomiquement.
    -- En cas d'echec (pas de slot libre), on rollback les modifications deja faites.
    local stackMods = {}    -- [slotIdx] = deltaCount
    local newSlots = {}     -- { { slot, name, count } }

    if meta.stackable then
        for slotIdx, slot in pairs(inv.grid) do
            if count <= 0 then break end
            if slot.name == itemName and (slot.count or 0) < (meta.max_stack or 1) then
                local space = (meta.max_stack or 1) - slot.count
                local add = math.min(space, count)
                stackMods[slotIdx] = (stackMods[slotIdx] or 0) + add
                count = count - add
            end
        end
    end
    while count > 0 do
        local free = targetSlot
        if not free or inv.grid[tostring(free)] or newSlots[free] then
            free = nil
            for i = 1, (Config.GridRows * Config.GridCols) do
                local key = tostring(i)
                local taken = inv.grid[key]
                for _, n in ipairs(newSlots) do if n.slot == key then taken = true break end end
                if not taken then free = i; break end
            end
        end
        if not free then return false, 'inventaire plein' end
        local add = math.min(count, meta.stackable and (meta.max_stack or 1) or 1)
        table.insert(newSlots, { slot = tostring(free), name = itemName, count = add })
        count = count - add
        targetSlot = nil
    end

    -- Applique les mutations (toutes ou rien -- on est arrive jusqu'ici donc on a la place).
    for slotIdx, delta in pairs(stackMods) do
        inv.grid[slotIdx].count = inv.grid[slotIdx].count + delta
    end
    for _, n in ipairs(newSlots) do
        inv.grid[n.slot] = { name = n.name, count = n.count }
    end
    sendState(src)
    return true
end

local function removeItem(src, itemName, count)
    count = count or 1
    local id = getIdentifier(src)
    local inv = ensureInventory(id)
    for slotIdx, slot in pairs(inv.grid) do
        if count <= 0 then break end
        if slot.name == itemName then
            local take = math.min(slot.count, count)
            slot.count = slot.count - take
            count = count - take
            if slot.count <= 0 then inv.grid[slotIdx] = nil end
        end
    end
    sendState(src)
    return count == 0
end

local function countItem(src, itemName)
    local id = getIdentifier(src)
    local inv = ensureInventory(id)
    local n = 0
    for _, slot in pairs(inv.grid) do
        if slot.name == itemName then n = n + (slot.count or 0) end
    end
    return n
end

exports('addItem', addItem)
exports('removeItem', removeItem)
exports('countItem', countItem)
exports('hasItem', function(src, name, min) return countItem(src, name) >= (min or 1) end)
exports('getInventory', function(src)
    local id = getIdentifier(src)
    return ensureInventory(id)
end)

-- ============================================================================
-- Events client
-- ============================================================================

RegisterNetEvent('frz-inventory:requestState', function()
    local src = source
    sendState(src)
end)

local function slotKey(v) return tostring(v) end

RegisterNetEvent('frz-inventory:action', function(payload)
    local src = source
    local id = getIdentifier(src)
    local inv = ensureInventory(id)
    local t = payload and payload.type

    if t == 'move' then
        local from, to = slotKey(payload.from), slotKey(payload.to)
        if from == to then return end
        local a, b = inv.grid[from], inv.grid[to]
        if not a then return end
        -- Stack si meme item et stackable.
        if b and b.name == a.name and Items[a.name] and Items[a.name].stackable then
            local cap = Items[a.name].max_stack or 1
            local space = cap - (b.count or 0)
            local move = math.min(space, a.count or 0)
            b.count = (b.count or 0) + move
            a.count = (a.count or 0) - move
            if a.count <= 0 then inv.grid[from] = nil end
        else
            inv.grid[from], inv.grid[to] = b, a
        end
        sendState(src)
    elseif t == 'drop' then
        local from = slotKey(payload.from)
        local slot = inv.grid[from]
        if not slot then return end
        local count = math.min(payload.count or slot.count, slot.count)
        slot.count = slot.count - count
        local dropped = { name = slot.name, count = count }
        if slot.count <= 0 then inv.grid[from] = nil end
        sendState(src)
        -- Hook vers drops.lua (server).
        if FrzInvDrops and FrzInvDrops.spawnDropFromPlayer then
            FrzInvDrops.spawnDropFromPlayer(src, dropped)
        end
    elseif t == 'equip' then
        local from = slotKey(payload.from)
        local slotKey_ = payload.slotKey
        local item = inv.grid[from]
        if not item then return end
        if not Config.ClothingSlots[slotKey_] then return end
        local drawable = item.drawable or math.random(0, 20)
        local texture = item.texture or 0
        -- Si un vetement est deja equipe sur ce slot, on le remet dans le slot d'origine (from)
        -- apres avoir libere celui-ci. Comme "from" devient libre, il accueille l'ancien vetement.
        local previous = inv.clothing[slotKey_]
        inv.clothing[slotKey_] = { name = item.name, drawable = drawable, texture = texture }
        if previous then
            inv.grid[from] = { name = previous.name, count = 1, drawable = previous.drawable, texture = previous.texture }
        else
            inv.grid[from] = nil
        end
        sendState(src)
    elseif t == 'unequip' then
        local slotKey_ = payload.slotKey
        local eq = inv.clothing[slotKey_]
        if not eq then return end
        -- Remet dans la premiere case libre.
        local free = nil
        for i = 1, (Config.GridRows * Config.GridCols) do
            if not inv.grid[tostring(i)] then free = i; break end
        end
        if not free then notify(src, 'Inventaire plein', 'error'); return end
        inv.grid[tostring(free)] = { name = eq.name, count = 1, drawable = eq.drawable, texture = eq.texture }
        inv.clothing[slotKey_] = nil
        sendState(src)
    elseif t == 'use' then
        local from = slotKey(payload.from)
        local item = inv.grid[from]
        if not item or not Items[item.name] or not Items[item.name].usable then return end
        -- Trigger un event pour les autres resources.
        TriggerEvent('frz-inventory:itemUsed', src, item.name)
        TriggerClientEvent('frz-inventory:itemUsed', src, item.name)
        -- Certains items sont consommes.
        local consumeList = { bread = true, water = true, burger = true, coffee = true, cigarette = true, medkit = true }
        if consumeList[item.name] then
            item.count = (item.count or 1) - 1
            if item.count <= 0 then inv.grid[from] = nil end
            sendState(src)
        end
        notify(src, 'Vous utilisez : ' .. (Items[item.name].label or item.name), 'info')
    end
end)

AddEventHandler('playerDropped', function()
    savePersistence()
end)

RegisterCommand('frz_giveitem', function(source, args)
    if source ~= 0 then return end  -- admin console only
    local target = tonumber(args[1])
    local name = args[2]
    local count = tonumber(args[3]) or 1
    if not target or not name then
        print('Usage: frz_giveitem <playerId> <itemName> [count]')
        return
    end
    local ok, err = addItem(target, name, count)
    print(ok and ('+'..count..' '..name..' -> '..target) or ('erreur: '..tostring(err)))
end, true)
