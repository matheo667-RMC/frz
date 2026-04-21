-- FRZ RP (frz-core) - Persistance JSON des etats joueurs.
-- On reutilise le pattern etabli dans frz-rp-spawn : SaveResourceFile /
-- LoadResourceFile, qui fonctionne sur toutes les builds FXServer sans
-- dependre de SetResourceKvp cote serveur.

FrzCore = FrzCore or {}
FrzCore.Server = FrzCore.Server or {}

local DATA_FILE = 'player_states.json'
local cache = nil -- { [identifier] = { stats = {...}, inventory = {...} } }
local dirty = false

local function getResource()
    return GetCurrentResourceName()
end

local function deepCopy(tbl)
    if type(tbl) ~= 'table' then return tbl end
    local out = {}
    for k, v in pairs(tbl) do out[k] = deepCopy(v) end
    return out
end

local function load()
    if cache then return cache end
    local content = LoadResourceFile(getResource(), DATA_FILE)
    if content and content ~= '' then
        local ok, data = pcall(json.decode, content)
        if ok and type(data) == 'table' then
            cache = data
            return cache
        end
    end
    cache = {}
    return cache
end

local function save()
    if not cache or not dirty then return end
    local ok, encoded = pcall(json.encode, cache)
    if not ok or not encoded then
        print('[frz-core] Erreur d encodage JSON, sauvegarde annulee.')
        return
    end
    local saved = SaveResourceFile(getResource(), DATA_FILE, encoded, -1)
    if not saved then
        print('[frz-core] SaveResourceFile a echoue (' .. DATA_FILE .. ').')
        return
    end
    dirty = false
end

-- Identifiant stable pour persister l'etat. On privilegie license2 qui est le
-- plus resistant (lie au compte Rockstar), puis les autres.
function FrzCore.Server.getIdentifier(src)
    local types = { 'license2', 'license', 'steam', 'discord', 'fivem' }
    for _, t in ipairs(types) do
        local id = GetPlayerIdentifierByType(src, t)
        if id and id ~= '' then return id end
    end
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id and id ~= '' then return id end
    end
    return nil
end

-- Renvoie (et cree si besoin) l'enregistrement persistant d'un identifiant.
function FrzCore.Server.getRecord(identifier)
    if not identifier then return nil end
    local data = load()
    if not data[identifier] then
        data[identifier] = {
            stats = deepCopy(FrzCore.Config.DefaultStats),
            inventory = {},
        }
        dirty = true
    else
        -- Retro-compat : ajoute les champs manquants si la config a evolue.
        data[identifier].stats = data[identifier].stats or {}
        for k, v in pairs(FrzCore.Config.DefaultStats) do
            if data[identifier].stats[k] == nil then
                data[identifier].stats[k] = v
                dirty = true
            end
        end
        data[identifier].inventory = data[identifier].inventory or {}
    end
    return data[identifier]
end

function FrzCore.Server.markDirty()
    dirty = true
end

function FrzCore.Server.wipe(identifier)
    local data = load()
    if data[identifier] then
        data[identifier] = nil
        dirty = true
        save()
        return true
    end
    return false
end

function FrzCore.Server.wipeAll()
    cache = {}
    dirty = true
    save()
end

-- Sauvegarde periodique (toutes les 60s) + a l'arret de la ressource.
CreateThread(function()
    while true do
        Wait(60000)
        save()
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    save()
end)

AddEventHandler('playerDropped', function()
    -- Force un flush quand un joueur quitte pour ne pas perdre sa progression.
    save()
end)

exports('getIdentifier', FrzCore.Server.getIdentifier)
exports('getRecord', FrzCore.Server.getRecord)
exports('markDirty', FrzCore.Server.markDirty)
exports('wipe', FrzCore.Server.wipe)
exports('wipeAll', FrzCore.Server.wipeAll)
