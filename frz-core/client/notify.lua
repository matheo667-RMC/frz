-- FRZ RP (frz-core) - Notifications joueur (messages a l'ecran).
-- Utilise BeginTextCommandThefeedPost, qui est dispo en standalone FiveM sans
-- dependance externe (scaleform natif GTA V).

FrzCore = FrzCore or {}
FrzCore.Client = FrzCore.Client or {}

function FrzCore.Client.notify(msg)
    if type(msg) ~= 'string' then return end
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandThefeedPostTicker(false, true)
end

RegisterNetEvent('frz-core:notify', function(msg)
    FrzCore.Client.notify(msg)
end)

-- Helper visible a l'ecran sous forme de texte 3D (utilise par frz-loot
-- pour afficher "Appuie sur E pour fouiller").
function FrzCore.Client.drawText3D(x, y, z, text)
    local onScreen, sx, sy = World3dToScreen2d(x, y, z)
    if not onScreen then return end
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 220)
    SetTextOutline()
    SetTextCentre(true)
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(sx, sy)
end

exports('notify', FrzCore.Client.notify)
exports('drawText3D', FrzCore.Client.drawText3D)
