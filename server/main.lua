-- FRZ RP - cote serveur (detection du premier join via fichier JSON persistant)
-- On n'utilise pas SetResourceKvpString cote serveur car certaines builds FXServer
-- ne l'exposent pas. On passe par SaveResourceFile / LoadResourceFile qui est disponible
-- partout et qui s'ecrit dans le dossier de la ressource.

local DATA_FILE = 'data/joined_players.json'
local joinedPlayers = nil

local function getResource()
    return GetCurrentResourceName()
end

local function loadJoinedPlayers()
    if joinedPlayers then
        return joinedPlayers
    end
    local content = LoadResourceFile(getResource(), DATA_FILE)
    if content and content ~= '' then
        local ok, data = pcall(json.decode, content)
        if ok and type(data) == 'table' then
            joinedPlayers = data
            return joinedPlayers
        end
    end
    joinedPlayers = {}
    return joinedPlayers
end

local function saveJoinedPlayers()
    if not joinedPlayers then return end
    local ok, encoded = pcall(json.encode, joinedPlayers)
    if not ok or not encoded then
        print('[frz-rp-spawn] Erreur d encodage JSON, sauvegarde annulee.')
        return
    end
    SaveResourceFile(getResource(), DATA_FILE, encoded, -1)
end

local function hasJoinedBefore(id)
    local data = loadJoinedPlayers()
    return data[id] ~= nil
end

local function markJoined(id)
    local data = loadJoinedPlayers()
    data[id] = os.time()
    saveJoinedPlayers()
end

local function resetJoined(id)
    local data = loadJoinedPlayers()
    if data[id] ~= nil then
        data[id] = nil
        saveJoinedPlayers()
        return true
    end
    return false
end

local function getPlayerLicense(src)
    -- Recherche un identifiant stable pour la persistance du "deja joue".
    local identifiers = { 'license2', 'license', 'steam', 'discord', 'fivem' }
    for _, idType in ipairs(identifiers) do
        local id = GetPlayerIdentifierByType(src, idType)
        if id and id ~= '' then
            return id
        end
    end

    -- Fallback : parcourir manuellement la liste d'identifiants.
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id and id ~= '' then
            return id
        end
    end

    return nil
end

RegisterNetEvent('frz-rp-spawn:requestIntro', function()
    local src = source
    local id = getPlayerLicense(src)

    if not id then
        TriggerClientEvent('frz-rp-spawn:playWelcomeBack', src)
        return
    end

    if not hasJoinedBefore(id) or Config.AlwaysPlayIntro then
        markJoined(id)
        TriggerClientEvent('frz-rp-spawn:playIntro', src)
    else
        TriggerClientEvent('frz-rp-spawn:playWelcomeBack', src)
    end
end)

-- Commande admin : reinitialise le statut "premier join" pour un joueur connecte.
-- Utilisation (console serveur) : frzresetspawn <id_joueur>
RegisterCommand('frzresetspawn', function(source, args)
    if source ~= 0 then
        -- Reserve a la console serveur pour eviter tout abus.
        return
    end
    local target = tonumber(args[1])
    if not target then
        print('[frz-rp-spawn] Usage : frzresetspawn <playerId>')
        return
    end
    local id = getPlayerLicense(target)
    if not id then
        print('[frz-rp-spawn] Joueur ' .. tostring(target) .. ' introuvable ou non connecte.')
        return
    end
    if resetJoined(id) then
        print('[frz-rp-spawn] Statut reinitialise pour ' .. id)
    else
        print('[frz-rp-spawn] Aucun statut enregistre pour ' .. id)
    end
end, true)

-- Commande admin : reinitialise TOUS les statuts (tout le monde rejoue l'intro).
-- Utilisation (console serveur) : frzresetspawnall
RegisterCommand('frzresetspawnall', function(source)
    if source ~= 0 then return end
    joinedPlayers = {}
    saveJoinedPlayers()
    print('[frz-rp-spawn] Tous les statuts ont ete reinitialises.')
end, true)
