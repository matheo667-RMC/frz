-- FRZ Inventaire - drops au sol (serveur)
-- Stocke les drops { id, x, y, z, items{} } et les synchronise aux clients proches.

FrzInvDrops = FrzInvDrops or {}

local DROPS = {}   -- id -> { id, x, y, z, items = {{name, count}}, createdAt }
local nextId = 1

local function loadDrops()
    local raw = LoadResourceFile(GetCurrentResourceName(), Config.DropsFile or 'drops.json')
    if raw and raw ~= '' then
        local ok, parsed = pcall(json.decode, raw)
        if ok and type(parsed) == 'table' then
            DROPS = parsed.drops or {}
            nextId = parsed.nextId or 1
        end
    end
end

local function saveDrops()
    SaveResourceFile(GetCurrentResourceName(),
        Config.DropsFile or 'drops.json',
        json.encode({ drops = DROPS, nextId = nextId }), -1)
end

loadDrops()

CreateThread(function()
    while true do
        Wait(120000)
        saveDrops()
        -- Nettoyage des drops expires.
        if Config.DropLifetime and Config.DropLifetime > 0 then
            local now = os.time()
            for id, d in pairs(DROPS) do
                if d.createdAt and (now - d.createdAt) > Config.DropLifetime then
                    DROPS[id] = nil
                    TriggerClientEvent('frz-inventory:drops:remove', -1, id)
                end
            end
        end
    end
end)

local function broadcastDrops()
    -- Envoi a tous : les drops sont peu nombreux et le client filtre par distance.
    local list = {}
    for _, d in pairs(DROPS) do list[#list+1] = d end
    TriggerClientEvent('frz-inventory:drops:sync', -1, list)
end

function FrzInvDrops.spawnDrop(coords, items)
    local id = tostring(nextId)
    nextId = nextId + 1
    DROPS[id] = {
        id = id,
        x = coords.x, y = coords.y, z = coords.z,
        items = items,
        createdAt = os.time(),
    }
    broadcastDrops()
    return id
end

function FrzInvDrops.spawnDropFromPlayer(src, item)
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    return FrzInvDrops.spawnDrop(coords, { item })
end

RegisterNetEvent('frz-inventory:drops:pickup', function(dropId)
    local src = source
    local drop = DROPS[tostring(dropId)]
    if not drop then return end
    -- Verifie que le joueur est proche (anti-cheat simple).
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local dx, dy, dz = coords.x - drop.x, coords.y - drop.y, coords.z - drop.z
    local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
    if dist > (Config.PickupDistance or 1.5) + 1.0 then return end

    for _, it in ipairs(drop.items or {}) do
        exports[GetCurrentResourceName()]:addItem(src, it.name, it.count)
    end
    DROPS[tostring(dropId)] = nil
    TriggerClientEvent('frz-inventory:drops:remove', -1, dropId)
end)

-- Quand un joueur spawn, on lui pousse l'etat des drops.
AddEventHandler('playerJoining', function()
    local src = source
    SetTimeout(2000, function()
        local list = {}
        for _, d in pairs(DROPS) do list[#list+1] = d end
        TriggerClientEvent('frz-inventory:drops:sync', src, list)
    end)
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then saveDrops() end
end)
