-- FRZ RP - cote serveur (detection du premier join via KVP)

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

    local key = Config.KvpPrefix .. id
    local already = GetResourceKvpString(key)

    if already == nil or Config.AlwaysPlayIntro then
        SetResourceKvpString(key, tostring(os.time()))
        TriggerClientEvent('frz-rp-spawn:playIntro', src)
    else
        TriggerClientEvent('frz-rp-spawn:playWelcomeBack', src)
    end
end)

-- Commande admin : reinitialise le statut "premier join" pour un joueur.
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
        print('[frz-rp-spawn] Joueur ' .. tostring(target) .. ' introuvable.')
        return
    end
    DeleteResourceKvp(Config.KvpPrefix .. id)
    print('[frz-rp-spawn] Statut reinitialise pour ' .. id)
end, true)
