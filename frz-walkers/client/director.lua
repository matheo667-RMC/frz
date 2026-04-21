-- Dead Zone RP (frz-walkers) - Directeur de spawn local.
-- Genere/supprime les rodeurs autour du joueur en respectant les caps et les
-- safe zones. Chaque client gere ses propres rodeurs (pas de sync serveur).

FrzWalkers = FrzWalkers or {}
FrzWalkers.Client = FrzWalkers.Client or {}

local frzCore = exports['frz-core']

-- Table des rodeurs actifs : { [pedHandle] = { spawnedAt = ms, lastBiteAt = ms } }
FrzWalkers.Client.active = FrzWalkers.Client.active or {}

local function activeCount()
    local n = 0
    for ped, _ in pairs(FrzWalkers.Client.active) do
        if DoesEntityExist(ped) then
            n = n + 1
        else
            FrzWalkers.Client.active[ped] = nil
        end
    end
    return n
end

local function randomModel()
    local models = FrzWalkers.Config.PedModels
    return models[math.random(1, #models)]
end

local function isInSafeZone(coords)
    for _, zone in ipairs(FrzWalkers.Config.NoSpawnZones or {}) do
        if #(coords - zone.center) <= zone.radius then
            return true
        end
    end
    return false
end

local function hotZoneMultiplier(coords)
    local mult = 1.0
    for _, zone in ipairs(FrzWalkers.Config.HotZones or {}) do
        if #(coords - zone.center) <= zone.radius then
            mult = math.max(mult, zone.multiplier or 1.0)
        end
    end
    return mult
end

-- Cherche un point de spawn valide autour d'un centre (joueur).
local function findSpawnPoint(center)
    for _ = 1, FrzWalkers.Config.MaxPlacementAttempts do
        local angle = math.random() * math.pi * 2
        local dist  = FrzWalkers.Config.SpawnMinDistance
                    + math.random() * (FrzWalkers.Config.SpawnMaxDistance - FrzWalkers.Config.SpawnMinDistance)
        local x = center.x + math.cos(angle) * dist
        local y = center.y + math.sin(angle) * dist
        local found, groundZ = GetGroundZFor_3dCoord(x, y, center.z + 50.0, false)
        if found then
            local pt = vector3(x, y, groundZ)
            if not isInSafeZone(pt) then
                -- Verifie qu'un joueur ne regarde pas pile dedans (evite les
                -- apparitions sous les yeux).
                local cam = GetGameplayCamCoord()
                if #(pt - cam) > FrzWalkers.Config.SpawnMinDistance then
                    return pt
                end
            end
        end
    end
    return nil
end

local function spawnWalker()
    local ped = PlayerPedId()
    local center = GetEntityCoords(ped)

    if isInSafeZone(center) then return end

    local modelName = randomModel()
    local modelHash = GetHashKey(modelName)
    RequestModel(modelHash)
    local t0 = GetGameTimer()
    while not HasModelLoaded(modelHash) do
        Wait(50)
        if GetGameTimer() - t0 > 4000 then
            SetModelAsNoLongerNeeded(modelHash)
            return
        end
    end

    local spawnPt = findSpawnPoint(center)
    if not spawnPt then
        SetModelAsNoLongerNeeded(modelHash)
        return
    end

    local walker = CreatePed(4, modelHash, spawnPt.x, spawnPt.y, spawnPt.z, math.random(0, 360) + 0.0, true, false)
    SetModelAsNoLongerNeeded(modelHash)
    if not walker or walker == 0 then return end

    SetEntityAsMissionEntity(walker, true, true)
    SetPedRelationshipGroupHash(walker, FrzWalkers.Client.GroupHash)
    SetPedMaxHealth(walker, FrzWalkers.Config.WalkerHealth)
    SetEntityHealth(walker, FrzWalkers.Config.WalkerHealth)
    SetPedAccuracy(walker, FrzWalkers.Config.WalkerAccuracy)
    SetPedSuffersCriticalHits(walker, false)
    SetPedFleeAttributes(walker, 0, false)
    SetPedDiesWhenInjured(walker, false)
    SetPedCombatAttributes(walker, 46, true) -- BF_AlwaysFight
    SetPedCombatAttributes(walker, 5, true)  -- BF_CanUseCover = false (agressif)
    SetPedCombatAbility(walker, 1)
    SetPedCombatRange(walker, 0)             -- short range (melee)
    SetPedSeeingRange(walker, FrzWalkers.Config.DetectionRange)
    SetPedHearingRange(walker, FrzWalkers.Config.DetectionRange)

    -- Demarche de rodeur (clipset "ivre" pour l allure traineuse caracteristique).
    local clipset = FrzWalkers.Config.WalkerMovementClipset
    RequestAnimSet(clipset)
    local ta = GetGameTimer()
    while not HasAnimSetLoaded(clipset) do
        Wait(20)
        if GetGameTimer() - ta > 1500 then break end
    end
    if HasAnimSetLoaded(clipset) then
        SetPedMovementClipset(walker, clipset, 1.0)
    end

    TaskWanderStandard(walker, 10.0, 10)

    FrzWalkers.Client.active[walker] = {
        spawnedAt = GetGameTimer(),
        lastBiteAt = 0,
        moanAt = GetGameTimer() + math.random(FrzWalkers.Config.MoanIntervalMin, FrzWalkers.Config.MoanIntervalMax),
    }
end

CreateThread(function()
    while true do
        Wait(FrzWalkers.Config.SpawnInterval)

        local ped = PlayerPedId()
        if DoesEntityExist(ped) and not IsPedDeadOrDying(ped, true) then
            local center = GetEntityCoords(ped)
            local mult = hotZoneMultiplier(center)
            local cap = math.floor(FrzWalkers.Config.MaxPerPlayer * mult)
            if activeCount() < cap and math.random() < FrzWalkers.Config.SpawnChance then
                spawnWalker()
            end
        end
    end
end)

-- Exports : les autres ressources (frz-loot, frz-safezones) vivent dans des
-- VMs Lua isolees, donc FrzWalkers.Client / FrzWalkers.Config n'est pas
-- visible chez elles. On passe par des exports pour les partager.

exports('getActiveWalkers', function()
    -- On renvoie une copie superficielle : la table est reevaluee par copy-by-value
    -- cote appelant, donc pas de risque de modif externe de FrzWalkers.Client.active.
    local out = {}
    for ped, info in pairs(FrzWalkers.Client.active) do
        if DoesEntityExist(ped) then
            out[ped] = info
        end
    end
    return out
end)

exports('addNoSpawnZone', function(center, radius)
    if not center or not radius then return end
    FrzWalkers.Config.NoSpawnZones = FrzWalkers.Config.NoSpawnZones or {}
    table.insert(FrzWalkers.Config.NoSpawnZones, {
        center = vector3(center.x or center[1], center.y or center[2], center.z or center[3]),
        radius = radius,
    })
end)
