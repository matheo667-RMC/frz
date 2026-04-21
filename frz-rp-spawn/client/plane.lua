-- Dead Zone RP - gestion de l'avion cinematique
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
    SetVehicleForwardSpeed(plane, Config.PlaneSpeed or 55.0)
    SetVehicleLandingGear(plane, 0)
    SetVehicleLights(plane, 2)
    -- Evite que l'avion ait un roll/pitch bizarre au spawn.
    SetEntityRotation(plane, -3.0, 0.0, s.w, 2, true)

    local pilotModel = loadModel(Config.PilotModel, 5000)
    local pilot = nil
    if pilotModel then
        pilot = CreatePedInsideVehicle(plane, 4, pilotModel, -1, false, false)
        if DoesEntityExist(pilot) then
            SetEntityAsMissionEntity(pilot, true, true)
            SetEntityInvincible(pilot, true)
            SetPedCanBeDraggedOut(pilot, false)
            SetBlockingOfNonTemporaryEvents(pilot, true)

            local rs = Config.RunwayStart
            local re = Config.RunwayEnd
            TaskPlaneLand(pilot, plane, rs.x, rs.y, rs.z, re.x, re.y, re.z)
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
