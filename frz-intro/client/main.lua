-- Dead Zone RP (frz-intro) - Declenchement cote client de l'anim NUI.
-- Affiche "Bienvenue dans la Dead Zone" une fois apres la premiere apparition
-- du joueur. Pas de manipulation de camera : on laisse spawnmanager gerer
-- le spawn aleatoire natif, on superpose juste une NUI.

local played = false

local function playIntro()
    SendNUIMessage({
        action   = 'play',
        title    = FrzIntro.Config.Title,
        subtitle = FrzIntro.Config.Subtitle,
        tagline  = FrzIntro.Config.Tagline,
        duration = FrzIntro.Config.TotalDuration,
    })

    if FrzIntro.Config.FreezePlayer then
        local ped = PlayerPedId()
        FreezeEntityPosition(ped, true)
        SetPlayerControl(PlayerId(), false, 0)

        SetTimeout(FrzIntro.Config.TotalDuration, function()
            local p = PlayerPedId()
            FreezeEntityPosition(p, false)
            SetPlayerControl(PlayerId(), true, 0)
        end)
    end
end

local function onFirstSpawn()
    if played and not FrzIntro.Config.PlayOnEveryConnect then return end
    played = true

    -- Attend que le player soit pleinement en jeu.
    while not NetworkIsPlayerActive(PlayerId()) do Wait(200) end
    while not DoesEntityExist(PlayerPedId()) do Wait(200) end

    Wait(FrzIntro.Config.StartDelay or 1500)
    playIntro()
end

-- Hook sur playerSpawned (emit par spawnmanager natif ou toute ressource qui
-- l'emet). On ne joue qu'une fois par session sauf si la config l'autorise.
AddEventHandler('playerSpawned', function()
    -- La variable 'played' bascule apres la premiere execution ; on ne rejoue
    -- jamais apres un respawn dans la meme session.
    if not played then
        CreateThread(onFirstSpawn)
    end
end)

-- Fallback : si pour une raison quelconque playerSpawned n'est pas emis
-- (typique en dev sans spawnmanager), on detecte manuellement le premier tick
-- ou le joueur est actif et on lance l'intro.
CreateThread(function()
    Wait(10000)
    if not played then
        onFirstSpawn()
    end
end)

-- Commande de debug pour tester sans relancer le serveur.
RegisterCommand('intro', function()
    played = true
    playIntro()
end, false)
TriggerEvent('chat:addSuggestion', '/intro', 'Rejouer l\'intro Dead Zone RP (debug)')
