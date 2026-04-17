-- FRZ RP - orchestrateur client (cinematique + restauration de position)
FrzSpawn = FrzSpawn or {}

local introPlayed   = false
local introRunning  = false
local welcomePlayed = false

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

local function teleportPed(pos)
    local ped = PlayerPedId()
    RequestCollisionAtCoord(pos.x, pos.y, pos.z)
    SetEntityCoords(ped, pos.x, pos.y, pos.z, false, false, false, true)
    SetEntityHeading(ped, pos.h or pos.w or 0.0)
    local t0 = GetGameTimer()
    while not HasCollisionLoadedAroundEntity(ped) do
        Wait(50)
        if GetGameTimer() - t0 > 5000 then break end
    end
end

local function teleportToAirport()
    local c = Config.SpawnCoords
    teleportPed({ x = c.x, y = c.y, z = c.z, h = c.w })
end

-- Declenche le son d'atterrissage apres un delai, dans un thread separe
-- pour ne pas bloquer la timeline principale de la cinematique.
local function scheduleLandingSound(delayMs)
    CreateThread(function()
        Wait(delayMs or 7000)
        FrzSpawn.playPlaneLandingSound()
    end)
end

function FrzSpawn.playIntro()
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

    FrzSpawn.showTitleCard(Config.TitleCardMain, Config.TitleCardSub)
    scheduleLandingSound(Config.LandingSoundDelay or 7500)

    Wait(Config.TitleCardDuration or 3000)
    FrzSpawn.hideTitleCard()

    local remaining = (Config.CinematicDuration or 12000) - (Config.TitleCardDuration or 3000)
    if remaining > 0 then Wait(remaining) end

    fadeOut(600)

    FrzSpawn.cleanupPlane(plane, pilot)
    FrzSpawn.destroyCam()
    FrzSpawn.stopPlaneLandingSound()

    -- Re-resolution du ped : le handle peut etre stale apres ~15 s.
    ped = PlayerPedId()
    SetEntityVisible(ped, true, false)
    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)

    fadeIn(800)

    Wait(500)
    FrzSpawn.showAnnouncement(Config.WelcomeMessage, Config.WelcomeSubtitle, true)

    Wait(Config.AnnouncementDuration or 17000)
    FrzSpawn.hideAnnouncement()

    introRunning = false
end

-- Pour les joueurs deja venus : on restaure leur derniere position connue
-- (si fournie par le serveur) et on affiche la petite banniere d'accueil.
function FrzSpawn.playWelcomeBack(savedPos)
    if introRunning or introPlayed or welcomePlayed then return end
    welcomePlayed = true

    if Config.RestoreLastPosition and type(savedPos) == 'table'
       and savedPos.x and savedPos.y and savedPos.z then
        -- Fade, teleport, fade in : evite que le joueur voie le "saut".
        fadeOut(400)
        local ped = PlayerPedId()
        FreezeEntityPosition(ped, true)
        teleportPed(savedPos)
        FreezeEntityPosition(ped, false)
        fadeIn(600)
        Wait(300)
    end

    FrzSpawn.showAnnouncement(Config.WelcomeBackMessage, Config.WelcomeSubtitle, false)
    Wait(Config.AnnouncementDuration or 17000)
    FrzSpawn.hideAnnouncement()
end

RegisterNetEvent('frz-rp-spawn:playIntro', function()
    FrzSpawn.playIntro()
end)

RegisterNetEvent('frz-rp-spawn:playWelcomeBack', function(savedPos)
    FrzSpawn.playWelcomeBack(savedPos)
end)

-- Demande au serveur quelle scene jouer des que le joueur est pret.
-- Flag local pour eviter de re-emettre sur restart de ressource en cours de session.
local introRequested = false
CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do Wait(250) end
    while not DoesEntityExist(PlayerPedId()) do Wait(250) end
    if introRequested then return end
    introRequested = true
    Wait(1000)
    TriggerServerEvent('frz-rp-spawn:requestIntro')
end)
