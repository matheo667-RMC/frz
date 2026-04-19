-- FRZ RP - cote serveur
-- Gere : detection du premier join + sauvegarde de la derniere position de chaque
-- joueur pour qu'il reapparaisse ou il s'etait deconnecte.
--
-- Persistance : fichier JSON dans le dossier de la ressource (pas de DB requise).
-- Fichier : players_data.json
-- Structure :
--   {
--     "<license>": {
--       "joined":   <timestamp premier join>,
--       "lastPos":  { "x":..., "y":..., "z":..., "h":... } | nil,
--       "lastSeen": <timestamp dernier update>,
--       "money":    <number>  -- GTA $ du joueur (persiste entre les sessions)
--     },
--     ...
--   }
--
-- On evite SetResourceKvpString cote serveur (pas dispo sur toutes les builds FXServer).
-- On ecrit au chemin PLAT (sans sous-dossier) : SaveResourceFile ne cree pas de
-- dossier parent et echouerait silencieusement si 'data/' n'existait pas.

local DATA_FILE     = 'players_data.json'
local LEGACY_FILE   = 'joined_players.json'
local playersData   = nil
local dirty         = false
local lastFlush     = 0
local FLUSH_MIN_GAP = 2000  -- evite d'ecrire le fichier plus souvent que toutes les 2 s

local function getResource()
    return GetCurrentResourceName()
end

local function loadPlayersData()
    if playersData then
        return playersData
    end

    local content = LoadResourceFile(getResource(), DATA_FILE)
    if content and content ~= '' then
        local ok, data = pcall(json.decode, content)
        if ok and type(data) == 'table' then
            playersData = data
            return playersData
        end
    end

    -- Migration douce depuis l'ancien format (juste la liste "joined").
    local legacy = LoadResourceFile(getResource(), LEGACY_FILE)
    if legacy and legacy ~= '' then
        local ok, data = pcall(json.decode, legacy)
        if ok and type(data) == 'table' then
            playersData = {}
            for id, ts in pairs(data) do
                playersData[id] = { joined = ts, lastPos = nil, lastSeen = ts }
            end
            dirty = true
            return playersData
        end
    end

    playersData = {}
    return playersData
end

local function flushNow()
    if not playersData then return end
    local ok, encoded = pcall(json.encode, playersData)
    if not ok or not encoded then
        print('[frz-rp-spawn] Erreur d encodage JSON, sauvegarde annulee.')
        return
    end
    local saved = SaveResourceFile(getResource(), DATA_FILE, encoded, -1)
    if not saved then
        print('[frz-rp-spawn] SaveResourceFile a echoue (' .. DATA_FILE
            .. '). Verifie les droits en ecriture sur le dossier de la ressource.')
        return
    end
    dirty = false
    lastFlush = GetGameTimer()
end

-- Ecriture debouncee : on marque dirty, et un thread flush regulierement.
local function markDirty()
    dirty = true
end

CreateThread(function()
    while true do
        Wait(FLUSH_MIN_GAP)
        if dirty and (GetGameTimer() - lastFlush) >= FLUSH_MIN_GAP then
            flushNow()
        end
    end
end)

local function getOrCreatePlayer(id)
    local data = loadPlayersData()
    if not data[id] then
        local startingCash = (Config.CarRental and Config.CarRental.startingCash) or 0
        data[id] = {
            joined   = nil,
            lastPos  = nil,
            lastSeen = os.time(),
            money    = startingCash,
        }
        markDirty()
    else
        -- Migration pour les entrees creees avant l'ajout du champ 'money'.
        if data[id].money == nil then
            local startingCash = (Config.CarRental and Config.CarRental.startingCash) or 0
            data[id].money = startingCash
            markDirty()
        end
    end
    return data[id]
end

local function hasJoinedBefore(id)
    local data = loadPlayersData()
    return data[id] ~= nil and data[id].joined ~= nil
end

local function markJoined(id)
    local entry = getOrCreatePlayer(id)
    entry.joined = os.time()
    entry.lastSeen = os.time()
    markDirty()
end

local function getLastPos(id)
    local data = loadPlayersData()
    local entry = data[id]
    if entry and entry.lastPos then
        return entry.lastPos
    end
    return nil
end

local function setLastPos(id, pos)
    if type(pos) ~= 'table' then return end
    local entry = getOrCreatePlayer(id)
    entry.lastPos = {
        x = tonumber(pos.x) or 0.0,
        y = tonumber(pos.y) or 0.0,
        z = tonumber(pos.z) or 0.0,
        h = tonumber(pos.h) or 0.0,
    }
    entry.lastSeen = os.time()
    markDirty()
end

local function resetJoined(id)
    local data = loadPlayersData()
    if data[id] then
        data[id].joined = nil
        markDirty()
        return true
    end
    return false
end

-- Reinitialise les statuts "premier join" et les positions de tous les
-- joueurs, mais PRESERVE les autres champs (notamment `money`). Ecraser
-- l'entree complete avec {} ferait perdre tout l'argent de tout le monde,
-- ce qui est une perte irrecuperable pour un admin qui veut juste rejouer
-- la cinematique (comportement attendu par la commande frzresetspawnall).
local function resetAll()
    local data = loadPlayersData()
    for _, entry in pairs(data) do
        if type(entry) == 'table' then
            entry.joined  = nil
            entry.lastPos = nil
        end
    end
    markDirty()
    flushNow()
end

-- ============================================================================
-- Argent : helpers exposes globalement pour les autres scripts serveur
-- (notamment server/car_rental.lua).
-- ============================================================================

function FrzMoney_Get(id)
    if not id then return 0 end
    local entry = getOrCreatePlayer(id)
    return entry.money or 0
end

function FrzMoney_Set(id, amount)
    if not id then return end
    local entry = getOrCreatePlayer(id)
    entry.money = math.max(0, math.floor(tonumber(amount) or 0))
    markDirty()
end

function FrzMoney_Add(id, amount)
    if not id or not amount then return end
    local entry = getOrCreatePlayer(id)
    entry.money = math.max(0, (entry.money or 0) + math.floor(amount))
    markDirty()
end

-- Essaie de debiter `amount` au joueur. Retourne true si reussi, false sinon.
function FrzMoney_TryDeduct(id, amount)
    if not id or not amount then return false end
    amount = math.floor(amount)
    if amount < 0 then return false end
    local entry = getOrCreatePlayer(id)
    if (entry.money or 0) < amount then
        return false
    end
    entry.money = entry.money - amount
    markDirty()
    return true
end

local function getPlayerLicense(src)
    local identifiers = { 'license2', 'license', 'steam', 'discord', 'fivem' }
    for _, idType in ipairs(identifiers) do
        local id = GetPlayerIdentifierByType(src, idType)
        if id and id ~= '' then
            return id
        end
    end
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id and id ~= '' then
            return id
        end
    end
    return nil
end

-- Cache : source -> license (evite de re-resoudre a chaque event).
local srcToLicense = {}

local function licenseOfSource(src)
    if srcToLicense[src] then
        return srcToLicense[src]
    end
    local id = getPlayerLicense(src)
    if id then
        srcToLicense[src] = id
    end
    return id
end

-- Expose aussi globalement pour les autres scripts serveur.
function FrzMoney_LicenseOfSource(src)
    return licenseOfSource(src)
end

-- Le client demande quoi jouer (cinematique ou welcome back) des qu'il est pret.
RegisterNetEvent('frz-rp-spawn:requestIntro', function()
    local src = source
    local id = licenseOfSource(src)
    if not id then
        TriggerClientEvent('frz-rp-spawn:playWelcomeBack', src, nil)
        return
    end

    if not hasJoinedBefore(id) or Config.AlwaysPlayIntro then
        markJoined(id)
        TriggerClientEvent('frz-rp-spawn:playIntro', src)
    else
        local pos = getLastPos(id)
        TriggerClientEvent('frz-rp-spawn:playWelcomeBack', src, pos)
    end
end)

-- Le client envoie sa position periodiquement pour sauvegarde.
RegisterNetEvent('frz-rp-spawn:updatePosition', function(pos)
    local src = source
    local id = licenseOfSource(src)
    if not id or type(pos) ~= 'table' then return end
    setLastPos(id, pos)
end)

-- Sauvegarde definitive quand le joueur se deconnecte. Le client ne peut pas
-- envoyer de message apres sa deconnexion, donc on compte sur la derniere
-- position recue via updatePosition.
AddEventHandler('playerDropped', function()
    local src = source
    local id = srcToLicense[src]
    srcToLicense[src] = nil
    if id and dirty then
        flushNow()
    end
    -- id n'est pas toujours resolvable ici (le joueur est deja hors jeu), on s'en
    -- sert juste pour logguer si present.
    if id then
        print('[frz-rp-spawn] Position finale sauvegardee pour ' .. id)
    end
end)

-- Flush a l'arret de la ressource / du serveur.
AddEventHandler('onResourceStop', function(res)
    if res == getResource() then
        flushNow()
    end
end)

-- Commande admin : reinitialise le statut "premier join" pour un joueur connecte.
-- Usage (console serveur) : frzresetspawn <playerId>
RegisterCommand('frzresetspawn', function(source, args)
    if source ~= 0 then return end  -- Reserve console serveur
    local target = tonumber(args[1])
    if not target then
        print('[frz-rp-spawn] Usage : frzresetspawn <playerId>')
        return
    end
    local id = getPlayerLicense(target)
    if not id then
        print('[frz-rp-spawn] Joueur ' .. tostring(target) .. ' introuvable.')
        return
    end
    if resetJoined(id) then
        flushNow()
        print('[frz-rp-spawn] Statut reinitialise pour ' .. id)
    else
        print('[frz-rp-spawn] Aucun statut enregistre pour ' .. id)
    end
end, true)

-- Commande admin : reinitialise TOUS les statuts (tout le monde rejoue l'intro).
-- Les positions sauvegardees sont aussi effacees.
RegisterCommand('frzresetspawnall', function(source)
    if source ~= 0 then return end
    resetAll()
    print('[frz-rp-spawn] Tous les statuts + positions ont ete reinitialises.')
end, true)

-- Commande admin : efface la position sauvegardee d'un joueur (prochain join
-- = spawn par defaut, pas sa derniere position).
-- Usage : frzresetposition <playerId>
RegisterCommand('frzresetposition', function(source, args)
    if source ~= 0 then return end
    local target = tonumber(args[1])
    if not target then
        print('[frz-rp-spawn] Usage : frzresetposition <playerId>')
        return
    end
    local id = getPlayerLicense(target)
    if not id then
        print('[frz-rp-spawn] Joueur ' .. tostring(target) .. ' introuvable.')
        return
    end
    local data = loadPlayersData()
    if data[id] then
        data[id].lastPos = nil
        markDirty()
        flushNow()
        print('[frz-rp-spawn] Position reinitialisee pour ' .. id)
    end
end, true)
