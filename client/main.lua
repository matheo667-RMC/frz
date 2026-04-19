-- FRZ RP - orchestrateur client (cinematique + restauration de position)
FrzSpawn = FrzSpawn or {}

local introPlayed   = false
local introRunning  = false
local welcomePlayed = false

-- On shutdown immediatement le loading screen du NUI FiveM, sinon il peut
-- rester affiche ("Awaiting scripts...") au-dessus de notre cinematique
-- tant qu'il n'a pas ete explicitement ferme par un gamemode (basic-gamemode
-- le faisait, il est desactive ici).
ShutdownLoadingScreenNui()
ShutdownLoadingScreen()

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

    -- Color grading cinematique : teinte plus chaude + contraste pour un
    -- rendu "plus beau" a l'ecran pendant la cinematique. Restaure avant la
    -- banniere de bienvenue pour ne pas biaiser le gameplay apres.
    SetTimecycleModifier('hud_def_blur')
    SetTimecycleModifierStrength(0.3)

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

    -- Phase observation de l'avion (avion qui descend + passe devant la cam)
    -- puis fade to black avant le touchdown reel. L'atterrissage "vrai" a
    -- lieu pendant l'ecran noir, ce qui evite de devoir perfectement timer
    -- le touchdown.
    local total        = Config.CinematicDuration or 12000
    local titleDur     = Config.TitleCardDuration or 3000
    local fadeToBlackAt = Config.FadeToBlackAt or 10000
    local observeDur   = math.max(0, fadeToBlackAt - titleDur)
    local blackDur     = math.max(0, total - fadeToBlackAt)

    if observeDur > 0 then Wait(observeDur) end

    -- Fade to black : le son d'avion peak pendant le noir.
    fadeOut(900)
    if blackDur > 0 then Wait(blackDur) end

    FrzSpawn.cleanupPlane(plane, pilot)
    FrzSpawn.destroyCam()
    FrzSpawn.stopPlaneLandingSound()

    -- Restaure le color grading normal.
    ClearTimecycleModifier()

    -- Re-resolution du ped : le handle peut etre stale apres ~15 s.
    ped = PlayerPedId()
    SetEntityVisible(ped, true, false)
    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)

    fadeIn(900)

    Wait(400)
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

local function kickoffIntro()
    if introRequested then return end
    introRequested = true
    Wait(500)
    TriggerServerEvent('frz-rp-spawn:requestIntro')
end

local FREEMODE_MODEL = 'mp_m_freemode_01'
local FREEMODE_HASH  = GetHashKey(FREEMODE_MODEL)

-- Force le modele freemode sur le ped actuel. Utilise apres chaque spawn
-- pour s'assurer que le joueur n'apparait jamais en Michael/Trevor/Franklin,
-- meme si un autre script (ou spawnmanager) a tente de restaurer ces modeles.
local function forceFreemodeModel()
    if GetEntityModel(PlayerPedId()) == FREEMODE_HASH then return end

    RequestModel(FREEMODE_HASH)
    local t0 = GetGameTimer()
    while not HasModelLoaded(FREEMODE_HASH) do
        Wait(10)
        if GetGameTimer() - t0 > 5000 then return end
    end

    SetPlayerModel(PlayerId(), FREEMODE_HASH)
    SetModelAsNoLongerNeeded(FREEMODE_HASH)
    -- Composants par defaut (pas les vetements de Michael qui trainent).
    SetPedDefaultComponentVariation(PlayerPedId())
end

-- IMPORTANT : on enregistre le callback d'autospawn AU CHARGEMENT de la
-- ressource (pas dans un thread avec des Wait), sinon spawnmanager a le
-- temps de declencher son spawn par defaut (= Michael) avant que notre
-- callback soit attache, et le joueur apparait en Michael au lieu de
-- mp_m_freemode_01.
if GetResourceState('spawnmanager') == 'started' then
    exports.spawnmanager:setAutoSpawnCallback(function()
        local c = Config.SpawnCoords
        exports.spawnmanager:spawnPlayer({
            x = c.x, y = c.y, z = c.z,
            heading = c.w,
            -- Modele freemode par defaut (pas Michael/Trevor/Franklin).
            model = FREEMODE_MODEL,
            skipFade = false,
        }, function()
            -- Belt-and-suspenders : si spawnmanager n'a pas applique le
            -- modele (race condition, modele pas charge a temps, etc.), on
            -- force le swap ici.
            forceFreemodeModel()
            kickoffIntro()
        end)
    end)
    exports.spawnmanager:setAutoSpawn(true)
end

-- Filet de securite final : sur CHAQUE spawn (initial, respawn apres mort,
-- restart de ressource), on force le modele freemode. Si spawnmanager ou
-- un autre script a remis Michael, on le swap immediatement.
AddEventHandler('playerSpawned', function()
    CreateThread(function()
        Wait(200) -- laisse spawnmanager finir son taf
        forceFreemodeModel()
    end)
end)

-- Thread de secours : gere le cas restart de ressource en cours de session
-- (le ped existe deja, spawnmanager n'appellera pas forcement notre callback).
CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do Wait(250) end

    if GetResourceState('spawnmanager') == 'started'
       and not DoesEntityExist(PlayerPedId()) then
        -- Joueur connecte mais pas encore spawn : on force notre callback.
        exports.spawnmanager:forceRespawn()
        return
    end

    -- Ped deja spawn (restart mid-session) : on enchaine directement sur la
    -- cinematique sans re-spawn.
    while not DoesEntityExist(PlayerPedId()) do Wait(250) end
    Wait(500)
    kickoffIntro()
end)
