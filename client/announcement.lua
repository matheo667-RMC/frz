-- FRZ RP - affichage banniere / title card / son atterrissage (NUI)
FrzSpawn = FrzSpawn or {}

function FrzSpawn.showAnnouncement(title, subtitle, playAudio)
    -- Une seule banniere (la NUI). On evite le feed natif GTA sinon on a
    -- deux banners qui s'affichent en meme temps (NUI en haut-gauche + feed
    -- GTA en bas-gauche).
    SendNUIMessage({
        action = 'show',
        title = title or Config.WelcomeMessage,
        subtitle = subtitle or Config.WelcomeSubtitle,
        playAudio = playAudio and true or false,
    })
end

function FrzSpawn.hideAnnouncement()
    SendNUIMessage({ action = 'hide' })
end

function FrzSpawn.showTitleCard(title, subtitle)
    SendNUIMessage({
        action = 'showTitle',
        title = title or Config.TitleCardMain,
        subtitle = subtitle or Config.TitleCardSub,
    })
end

function FrzSpawn.hideTitleCard()
    SendNUIMessage({ action = 'hideTitle' })
end

function FrzSpawn.playPlaneLandingSound()
    SendNUIMessage({ action = 'planeLanding' })
end

function FrzSpawn.stopPlaneLandingSound()
    SendNUIMessage({ action = 'stopPlaneLanding' })
end
