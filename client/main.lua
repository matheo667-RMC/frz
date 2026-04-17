-- FRZ RP - orchestrateur client (cinematique d'arrivee)
FrzSpawn = FrzSpawn or {}

local introPlayed   = false
local introRunning  = false
local welcomePlayed = false

local function teleportToAirport()
    local ped = PlayerPedId()
    local c = Config.SpawnCoords
    RequestCollisionAtCoord(c.x, c.y, c.z)
    SetEntityCoords(ped, c.x, c.y, c.z, false, false, false, true)
    SetEntityHeading(ped, c.w)
    local t0 = GetGameTimer()
    while not HasCollisionLoadedAroundEntity(ped) do
        Wait(50)
        if GetGameTimer() - t0 > 5000 then break end
    end
end

local function fadeOut(ms)
    DoScreenFadeOut(ms or 500)
    local t0 = GetGameTimer()
    while not IsScreenFadedOut() do
        Wait(10)
        if GetGameTimer() - t0 > 2000 then break end
    end
end

local function fadeIn(ms)
    DoScreenFadeIn(ms or 800)
end

function FrzSpawn.playIntro()
    -- Evite tout double declenchement (event recu deux fois, resource reset, etc.).
    if introPlayed or introRunning then return end
    introRunning = true
    introPlayed = true

    fadeOut(500)

    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetEntityVisible(ped, false, false)

    teleportToAirport()

    local plane, pilot = FrzSpawn.spawnPlane()

    FrzSpawn.createCam(Config.CameraPosition, Config.CameraRotation)
    if plane then
        FrzSpawn.pointCamAtEntity(plane)
    end

    fadeIn(1000)

    Wait(Config.CinematicDuration)

    FrzSpawn.showAnnouncement(Config.WelcomeMessage, Config.WelcomeSubtitle, true)

    Wait(3500)

    fadeOut(600)

    FrzSpawn.cleanupPlane(plane, pilot)
    FrzSpawn.destroyCam()

    SetEntityVisible(ped, true, false)
    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)

    fadeIn(800)

    local remaining = Config.AnnouncementDuration - 3500
    if remaining < 0 then remaining = 0 end
    Wait(remaining)
    FrzSpawn.hideAnnouncement()

    introRunning = false
end

function FrzSpawn.playWelcomeBack()
    -- Si l'intro complete tourne deja, on ne superpose pas la banniere "welcome back".
    if introRunning or introPlayed or welcomePlayed then return end
    welcomePlayed = true

    FrzSpawn.showAnnouncement(Config.WelcomeBackMessage, Config.WelcomeSubtitle, false)
    Wait(Config.AnnouncementDuration)
    FrzSpawn.hideAnnouncement()
end

RegisterNetEvent('frz-rp-spawn:playIntro', function()
    FrzSpawn.playIntro()
end)

RegisterNetEvent('frz-rp-spawn:playWelcomeBack', function()
    FrzSpawn.playWelcomeBack()
end)

-- Demande au serveur quelle scene jouer des que le joueur est pret.
-- On utilise un flag local pour ne pas re-emettre la requete si la ressource est redemarree
-- en cours de session (ex: /restart frz-rp-spawn par un admin).
local introRequested = false
CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do Wait(250) end
    while not DoesEntityExist(PlayerPedId()) do Wait(250) end
    if introRequested then return end
    introRequested = true
    Wait(1000)
    TriggerServerEvent('frz-rp-spawn:requestIntro')
end)
