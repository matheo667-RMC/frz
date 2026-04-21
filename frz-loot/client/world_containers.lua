-- FRZ RP (frz-loot) - Detection des props "fouillables" dans le monde
-- (bennes, poubelles, caisses). On scanne les entites proches du joueur et
-- quand il appuie sur E -> event serveur -> tirage + inventaire.

FrzLoot = FrzLoot or {}
FrzLoot.Client = FrzLoot.Client or {}

local frzCore = exports['frz-core']

-- Cache local des containers deja fouilles (hash -> timestamp). Les IDs de
-- props sont non persistants entre deux sessions mais suffisent pour eviter
-- le spam dans la meme session.
local cooldowns = {}

local function containerKey(obj)
    local coords = GetEntityCoords(obj)
    -- Pos arrondie + model hash : identifiant stable pour la session.
    return string.format('%d_%d_%d_%d',
        math.floor(coords.x * 10),
        math.floor(coords.y * 10),
        math.floor(coords.z * 10),
        GetEntityModel(obj))
end

local function isOnCooldown(key)
    local at = cooldowns[key]
    if not at then return false end
    return (GetGameTimer() - at) < FrzLoot.Config.ContainerCooldown
end

local function modelNameForHash(hash)
    for name, _ in pairs(FrzLoot.Config.ContainerModels) do
        if GetHashKey(name) == hash then return name end
    end
    return nil
end

local function findNearestContainer()
    local ped = PlayerPedId()
    local pcoords = GetEntityCoords(ped)

    local bestObj, bestDist, bestType, bestName
    -- On prend une liste d'objets proches via le raycast des models connus.
    for modelName, kind in pairs(FrzLoot.Config.ContainerModels) do
        local obj = GetClosestObjectOfType(pcoords.x, pcoords.y, pcoords.z,
            FrzLoot.Config.SearchRange * 1.5, GetHashKey(modelName), false, false, false)
        if obj ~= 0 then
            local d = #(GetEntityCoords(obj) - pcoords)
            if d <= FrzLoot.Config.SearchRange then
                if not bestObj or d < bestDist then
                    bestObj, bestDist, bestType, bestName = obj, d, kind, modelName
                end
            end
        end
    end

    return bestObj, bestType, bestName
end

local function searchAnimation()
    local ped = PlayerPedId()
    RequestAnimDict('anim@gangops@facility@servers@')
    local t0 = GetGameTimer()
    while not HasAnimDictLoaded('anim@gangops@facility@servers@') and GetGameTimer() - t0 < 1500 do Wait(20) end
    if HasAnimDictLoaded('anim@gangops@facility@servers@') then
        TaskPlayAnim(ped, 'anim@gangops@facility@servers@', 'hotwire', 8.0, -8.0, -1, 49, 0, false, false, false)
    end
    Wait(FrzLoot.Config.SearchDuration)
    ClearPedTasks(ped)
end

-- Boucle principale : on scanne lentement quand rien a proximite (Wait 500),
-- mais des qu'un container est detecte on passe en per-frame (Wait 0) pour
-- que drawText3D affiche le prompt en continu et que IsControlJustReleased
-- capte bien la touche E (les deux ne vivent qu'une frame a la fois).
CreateThread(function()
    local sleep = 500
    while true do
        Wait(sleep)
        sleep = 500

        local ped = PlayerPedId()
        if DoesEntityExist(ped) and not IsPedDeadOrDying(ped, true) then
            local obj, kind, modelName = findNearestContainer()
            if obj then
                sleep = 0
                local key = containerKey(obj)
                local coords = GetEntityCoords(obj)
                if isOnCooldown(key) then
                    frzCore:drawText3D(coords.x, coords.y, coords.z + 0.5, 'Deja fouille')
                else
                    frzCore:drawText3D(coords.x, coords.y, coords.z + 0.5, '[E] Fouiller')
                    if IsControlJustReleased(0, 38) then -- E
                        cooldowns[key] = GetGameTimer()
                        searchAnimation()
                        TriggerServerEvent('frz-loot:searchContainer', kind, modelName)
                    end
                end
            end
        end
    end
end)

RegisterNetEvent('frz-loot:result', function(loot)
    if type(loot) ~= 'table' or #loot == 0 then
        frzCore:notify('Rien trouve.')
        return
    end
    for _, entry in ipairs(loot) do
        local label = FrzCore.Config.ItemLabels[entry.item] or entry.item
        frzCore:notify(string.format('+ %d x %s', entry.count, label))
    end
end)
