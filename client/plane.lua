-- FRZ RP - gestion de l'avion cinematique
FrzSpawn = FrzSpawn or {}

local function loadModel(modelName, timeoutMs)
    local model = type(modelName) == 'string' and GetHashKey(modelName) or modelName
    RequestModel(model)
    local t0 = GetGameTimer()
    while not HasModelLoaded(model) do
        Wait(50)
        if GetGameTimer() - t0 > (timeoutMs or 5000) then
            return nil
        end
    end
    return model
end

function FrzSpawn.spawnPlane()
    local planeModel = loadModel(Config.PlaneModel, 5000)
    if not planeModel then
        return nil, nil
    end

    local s = Config.PlaneSpawn
    -- isNetwork = false : la cinematique est locale au joueur, on ne sync pas l'avion sur le reseau.
    local plane = CreateVehicle(planeModel, s.x, s.y, s.z, s.w, false, false)
    if not DoesEntityExist(plane) then
        SetModelAsNoLongerNeeded(planeModel)
        return nil, nil
    end

    SetEntityAsMissionEntity(plane, true, true)
    SetVehicleEngineOn(plane, true, true, false)
    SetVehicleForwardSpeed(plane, 80.0)
    SetVehicleLandingGear(plane, 0)
    SetVehicleLights(plane, 2)

    local pilotModel = loadModel(Config.PilotModel, 5000)
    local pilot = nil
    if pilotModel then
        -- pedType 4 = PED_TYPE_CIVMALE ; isNetwork = false (meme raison que l'avion).
        pilot = CreatePedInsideVehicle(plane, 4, pilotModel, -1, false, false)
        if DoesEntityExist(pilot) then
            SetEntityAsMissionEntity(pilot, true, true)
            SetEntityInvincible(pilot, true)
            SetPedCanBeDraggedOut(pilot, false)
            SetBlockingOfNonTemporaryEvents(pilot, true)

            local rs = Config.RunwayStart
            local re = Config.RunwayEnd
            TaskPlaneLand(pilot, plane, rs.x, rs.y, rs.z, re.x, re.y, re.z)
            -- SetPedKeepTask doit etre appele APRES le task pour qu'il soit conserve.
            SetPedKeepTask(pilot, true)
        end
        SetModelAsNoLongerNeeded(pilotModel)
    end

    SetModelAsNoLongerNeeded(planeModel)
    return plane, pilot
end

function FrzSpawn.cleanupPlane(plane, pilot)
    if pilot and DoesEntityExist(pilot) then
        SetEntityAsMissionEntity(pilot, true, true)
        DeletePed(pilot)
    end
    if plane and DoesEntityExist(plane) then
        SetEntityAsMissionEntity(plane, true, true)
        DeleteVehicle(plane)
    end
end
