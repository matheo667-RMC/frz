-- Dead Zone RP - gestion de la camera cinematique
FrzSpawn = FrzSpawn or {}

local activeCam = nil

function FrzSpawn.createCam(coords, rot)
    FrzSpawn.destroyCam()

    local cam = CreateCamWithParams(
        'DEFAULT_SCRIPTED_CAMERA',
        coords.x, coords.y, coords.z,
        rot.x, rot.y, rot.z,
        50.0, false, 0
    )
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, true)
    activeCam = cam
    return cam
end

function FrzSpawn.pointCamAtEntity(entity)
    if activeCam and entity and DoesEntityExist(entity) then
        PointCamAtEntity(activeCam, entity, 0.0, 0.0, 0.0, true)
    end
end

function FrzSpawn.stopPointingCam()
    if activeCam then
        StopCamPointing(activeCam)
    end
end

function FrzSpawn.destroyCam()
    if activeCam then
        RenderScriptCams(false, true, 800, true, true)
        SetCamActive(activeCam, false)
        DestroyCam(activeCam, false)
        activeCam = nil
    end
end
