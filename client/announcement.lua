-- FRZ RP - affichage de la banniere d'annonce et lecture audio (NUI)
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
