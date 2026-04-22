-- Dead Zone RP (frz-survival) - Serveur : applique l'infection d'une morsure
-- cote serveur (persistance immediate via frz-core:addStat) et notifie le
-- client pour jouer les effets visuels / la notif.
--
-- Avant : frz-walkers/server/sync.lua ne faisait que relayer vers le client
-- qui appelait setStatLocal (cache client uniquement). Si le joueur se
-- deconnectait avant le prochain pushStats periodique (30s), la morsure
-- etait perdue. On passe par addStat serveur pour persister immediatement.

FrzSurvival = FrzSurvival or {}
FrzSurvival.Server = FrzSurvival.Server or {}

function FrzSurvival.Server.applyBite(src)
    if type(src) ~= 'number' or src <= 0 then return end
    local amount = FrzSurvival.Config.InfectionOnBite or 15.0
    exports['frz-core']:addStat(src, 'infection', amount)
    -- Le client re-calcule l'affichage en se basant sur la stat pushee par
    -- frz-core:syncStats (declenche par addStat ci-dessus), mais on lui
    -- envoie aussi l'amount pour l'effet HP / shake local.
    TriggerClientEvent('frz-survival:onBite', src, amount)
end

exports('applyBite', FrzSurvival.Server.applyBite)
