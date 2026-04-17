-- FRZ RP - affichage banniere / title card / son atterrissage (NUI)
FrzSpawn = FrzSpawn or {}

function FrzSpawn.showAnnouncement(title, subtitle, playAudio)
    SendNUIMessage({
        action = 'show',
        title = title or Config.WelcomeMessage,
        subtitle = subtitle or Config.WelcomeSubtitle,
        playAudio = playAudio and true or false,
    })

    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName((title or '') .. ' - ' .. (subtitle or ''))
    EndTextCommandThefeedPostTicker(false, true)
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
