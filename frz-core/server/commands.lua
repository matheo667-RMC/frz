-- FRZ RP (frz-core) - Commandes admin pour debug / GM.
-- Toutes accessibles uniquement depuis la console (source 0) ou depuis un
-- identifiant present dans FrzCore.Config.Admins.

FrzCore = FrzCore or {}

local function isAuthorized(src)
    if src == 0 then return true end
    local id = FrzCore.Server.getIdentifier(src)
    if not id then return false end
    for _, allowed in ipairs(FrzCore.Config.Admins or {}) do
        if allowed == id then return true end
    end
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local pid = GetPlayerIdentifier(src, i)
        for _, allowed in ipairs(FrzCore.Config.Admins or {}) do
            if pid == allowed then return true end
        end
    end
    return false
end

-- frzgive <playerId> <itemId> [count]
RegisterCommand('frzgive', function(source, args)
    if not isAuthorized(source) then return end
    local target = tonumber(args[1])
    local itemId = args[2]
    local count  = tonumber(args[3]) or 1
    if not target or not itemId then
        print('[frz-core] Usage : frzgive <playerId> <itemId> [count]')
        return
    end
    if FrzCore.Server.giveItem(target, itemId, count) then
        print(('[frz-core] Donne %d x %s a %d'):format(count, itemId, target))
    else
        print('[frz-core] Echec giveItem (inventaire plein ou joueur introuvable).')
    end
end, true)

-- frzsetstat <playerId> <stat> <value>
RegisterCommand('frzsetstat', function(source, args)
    if not isAuthorized(source) then return end
    local target = tonumber(args[1])
    local stat   = args[2]
    local value  = tonumber(args[3])
    if not target or not stat or not value then
        print('[frz-core] Usage : frzsetstat <playerId> <hunger|thirst|fatigue|infection> <0-100>')
        return
    end
    if FrzCore.Server.setStat(target, stat, value) then
        print(('[frz-core] %s de %d = %d'):format(stat, target, value))
    else
        print('[frz-core] Echec setStat.')
    end
end, true)

-- frzwipe <playerId>  |  frzwipeall
RegisterCommand('frzwipe', function(source, args)
    if not isAuthorized(source) then return end
    local target = tonumber(args[1])
    if not target then
        print('[frz-core] Usage : frzwipe <playerId>')
        return
    end
    local id = FrzCore.Server.getIdentifier(target)
    if not id then
        print('[frz-core] Identifiant introuvable pour ' .. target)
        return
    end
    if FrzCore.Server.wipe(id) then
        print('[frz-core] Donnees de ' .. id .. ' effacees.')
    else
        print('[frz-core] Aucune donnee pour ' .. id)
    end
end, true)

RegisterCommand('frzwipeall', function(source)
    if not isAuthorized(source) then return end
    FrzCore.Server.wipeAll()
    print('[frz-core] Toutes les donnees joueurs ont ete effacees.')
end, true)
