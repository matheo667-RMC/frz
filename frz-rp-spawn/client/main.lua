-- Dead Zone RP - orchestrateur client (cinematique d'arrivee a LSIA)
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

-- Declenche le son d'atterrissage apres un delai, dans un thread separe
-- pour ne pas bloquer la timeline principale de la cinematique.
local function scheduleLandingSound(delayMs)
    CreateThread(function()
        Wait(delayMs or 7000)
        FrzSpawn.playPlaneLandingSound()
    end)
end

function FrzSpawn.playIntro()
    -- Empeche tout double declenchement (event recu deux fois, etc.).
    if introPlayed or introRunning then return end
    introRunning = true
    introPlayed = true

    -- 1. Fade out, prep du joueur (invisible, fige, teleporte au terminal).
    fadeOut(500)

    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetEntityVisible(ped, false, false)

    teleportToAirport()

    -- 2. Spawn de l'avion en approche + camera cinematique.
    local plane, pilot = FrzSpawn.spawnPlane()

    FrzSpawn.createCam(Config.CameraPosition, Config.CameraRotation)
    if plane then
        FrzSpawn.pointCamAtEntity(plane)
    end

    -- 3. Fade in sur la scene cinematique.
    fadeIn(1000)

    -- 4. Title card "Dead Zone RP - Los Santos International Airport".
    FrzSpawn.showTitleCard(Config.TitleCardMain, Config.TitleCardSub)

    -- 5. Programme le son d'atterrissage pour le moment ou l'avion touche la piste.
    scheduleLandingSound(Config.LandingSoundDelay or 7500)

    -- 6. Laisse le title card visible un moment puis le masque.
    Wait(Config.TitleCardDuration or 3000)
    FrzSpawn.hideTitleCard()

    -- 7. Continue la cinematique jusqu'a la fin.
    local remaining = (Config.CinematicDuration or 12000) - (Config.TitleCardDuration or 3000)
    if remaining > 0 then Wait(remaining) end

    -- 8. Fin de la cinematique : fade out, cleanup.
    fadeOut(600)

    FrzSpawn.cleanupPlane(plane, pilot)
    FrzSpawn.destroyCam()
    FrzSpawn.stopPlaneLandingSound()

    -- Re-resolution du ped : le handle capture en debut de fonction peut etre
    -- stale apres ~15 s (changement de modele par un autre script, respawn, etc.).
    -- Sans ca, le joueur resterait fige/invisible/invincible sur un handle mort.
    ped = PlayerPedId()
    SetEntityVisible(ped, true, false)
    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)

    fadeIn(800)

    -- 9. Petit temps d'arret puis annonce vocale + banniere.
    Wait(500)
    FrzSpawn.showAnnouncement(Config.WelcomeMessage, Config.WelcomeSubtitle, true)

    Wait(Config.AnnouncementDuration or 17000)
    FrzSpawn.hideAnnouncement()

    introRunning = false
end

function FrzSpawn.playWelcomeBack()
    -- Evite de superposer avec une intro en cours et les re-emissions d'event.
    if introRunning or introPlayed or welcomePlayed then return end
    welcomePlayed = true

    FrzSpawn.showAnnouncement(Config.WelcomeBackMessage, Config.WelcomeSubtitle, false)
    Wait(Config.AnnouncementDuration or 17000)
    FrzSpawn.hideAnnouncement()
end

RegisterNetEvent('frz-rp-spawn:playIntro', function()
    FrzSpawn.playIntro()
end)

RegisterNetEvent('frz-rp-spawn:playWelcomeBack', function()
    FrzSpawn.playWelcomeBack()
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
