-- FRZ RP - envoie la position du joueur au serveur a intervalle regulier
-- pour pouvoir la restaurer a la prochaine connexion.
--
-- Le serveur sauvegarde aussi sur 'playerDropped' en utilisant la derniere
-- position recue. On ne peut pas envoyer d'event au moment de la deconnexion
-- (le client est deja parti), donc on envoie regulierement pendant le jeu.

local function isPedValid(ped)
    return ped and ped ~= 0 and DoesEntityExist(ped) and not IsEntityDead(ped)
end

CreateThread(function()
    -- Attend que le joueur soit vraiment en jeu avant de commencer a envoyer.
    while not NetworkIsPlayerActive(PlayerId()) do Wait(500) end
    while not DoesEntityExist(PlayerPedId()) do Wait(500) end

    -- Laisse finir la cinematique avant de commencer a sauvegarder les positions
    -- (sinon on sauve la position "a l'aeroport" meme pour les returning players).
    Wait(5000)

    local interval = Config.PositionSaveInterval or 20000
    local lastSent = 0
    local lastPos  = nil

    while true do
        Wait(interval)

        local ped = PlayerPedId()
        if isPedValid(ped) then
            local coords  = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)

            -- Ne renvoie pas si la position n'a pas change de plus de 1 m.
            if not lastPos or
               #(vector3(coords.x, coords.y, coords.z) - vector3(lastPos.x, lastPos.y, lastPos.z)) > 1.0 then
                TriggerServerEvent('frz-rp-spawn:updatePosition', {
                    x = coords.x,
                    y = coords.y,
                    z = coords.z,
                    h = heading,
                })
                lastPos = { x = coords.x, y = coords.y, z = coords.z }
                lastSent = GetGameTimer()
            end
        end
    end
end)
