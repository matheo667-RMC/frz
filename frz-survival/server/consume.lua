-- FRZ RP (frz-survival) - Serveur : validation et retrait d'item lors d'une
-- consommation. Le client envoie 'frz-survival:consume', on retire l'item via
-- frz-core, puis on confirme au client qui applique les effets.

local frzCore = exports['frz-core']

RegisterNetEvent('frz-survival:consume', function(itemId)
    local src = source
    if type(itemId) ~= 'string' then return end

    local effect = FrzSurvival.Config.ConsumeEffects[itemId]
    if not effect then
        TriggerClientEvent('frz-core:notify', src, 'Objet non consommable.')
        return
    end

    if not frzCore:hasItem(src, itemId, 1) then
        TriggerClientEvent('frz-core:notify', src, 'Tu n as pas cet objet.')
        return
    end

    if not frzCore:takeItem(src, itemId, 1) then
        TriggerClientEvent('frz-core:notify', src, 'Echec : impossible de retirer l objet.')
        return
    end

    -- Applique les effets cote serveur (stats persistees) et notifie le client
    -- pour les effets cosmetiques (animation, HP local).
    for statName, delta in pairs(effect) do
        if statName ~= 'health' then
            frzCore:addStat(src, statName, delta)
        end
    end
    TriggerClientEvent('frz-survival:onConsumed', src, itemId)
end)
