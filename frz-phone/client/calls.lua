-- FRZ Phone - gestion des appels cote client
-- Pour la voix : si pma-voice ou mumble-voip est present, on tente d'ajouter
-- le peer dans un canal. Sinon, on simule avec des notifications.

local activeCall = nil  -- { peerSrc, peerNumber }

RegisterNetEvent('frz-phone:voice:connect', function(peerSrc, peerNumber)
    activeCall = { peerSrc = peerSrc, peerNumber = peerNumber }
    -- Integration pma-voice (si installe).
    if exports['pma-voice'] and exports['pma-voice'].addPlayerToTargetList then
        pcall(function() exports['pma-voice']:addPlayerToTargetList(peerSrc) end)
    end
end)

RegisterNetEvent('frz-phone:voice:disconnect', function()
    if activeCall and exports['pma-voice'] and exports['pma-voice'].removePlayerFromTargetList then
        pcall(function() exports['pma-voice']:removePlayerFromTargetList(activeCall.peerSrc) end)
    end
    activeCall = nil
end)
