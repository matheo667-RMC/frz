-- Dead Zone RP (frz-craft) - Validation et execution serveur des crafts.
-- Le client envoie l'id de recette apres l'animation. Le serveur re-verifie
-- les inputs (anti-triche) puis consomme et donne l'output.

local frzCore = exports['frz-core']

local function findRecipe(id)
    for _, r in ipairs(FrzCraft.Config.Recipes) do
        if r.id == id then return r end
    end
    return nil
end

-- Anti-spam : empeche 2 crafts serveur a moins de 1s d'intervalle par joueur.
local lastCraftAt = {}

RegisterNetEvent('frz-craft:requestCraft', function(recipeId)
    local src = source
    if type(recipeId) ~= 'string' then return end

    local now = GetGameTimer()
    if (now - (lastCraftAt[src] or 0)) < 1000 then return end
    lastCraftAt[src] = now

    local recipe = findRecipe(recipeId)
    if not recipe then
        TriggerClientEvent('frz-craft:result', src, false, 'Recette inconnue.')
        return
    end

    -- Verifie tous les inputs.
    for _, input in ipairs(recipe.inputs) do
        if not frzCore:hasItem(src, input.item, input.count) then
            TriggerClientEvent('frz-craft:result', src, false, 'Ressources insuffisantes : ' .. recipe.label)
            return
        end
    end

    -- Retire les inputs. On garde la liste des items reellement retires pour
    -- pouvoir tout refund en cas d'echec (inventaire plein, take mid-loop...).
    local taken = {}
    for _, input in ipairs(recipe.inputs) do
        if not frzCore:takeItem(src, input.item, input.count) then
            -- Edge case : entre la verif et le take, un autre script a pris
            -- l'item. Refund ce qu'on avait deja retire.
            for _, t in ipairs(taken) do
                frzCore:giveItem(src, t.item, t.count)
            end
            TriggerClientEvent('frz-craft:result', src, false, 'Echec : ressources non consommees.')
            return
        end
        taken[#taken + 1] = input
    end

    -- Donne l'output.
    if not frzCore:giveItem(src, recipe.output.item, recipe.output.count) then
        -- Inventaire plein : refund tous les inputs deja retires.
        for _, t in ipairs(taken) do
            frzCore:giveItem(src, t.item, t.count)
        end
        TriggerClientEvent('frz-craft:result', src, false, 'Inventaire plein.')
        return
    end

    local outLabel = FrzCore.Config.ItemLabels[recipe.output.item] or recipe.output.item
    TriggerClientEvent('frz-craft:result', src, true, string.format('%dx %s', recipe.output.count, outLabel))
end)

-- Anti-spam barricades (1 request/sec par joueur, meme rule que les crafts).
local lastBarricadeAt = {}

-- Tracke les consommations de barricade en attente de confirmation client.
-- Sans ce flag, un client pourrait spammer frz-craft:barricadeSpawnFailed
-- pour recuperer des items gratos sans jamais avoir consomme de barricade.
-- Chaque entree = timestamp de la consommation, auto-expire apres 15s
-- (suffisamment long pour le streaming du prop + une marge reseau).
local pendingBarricadeRefund = {}
local REFUND_WINDOW_MS = 15000

local function clearExpiredRefunds(src)
    local t = pendingBarricadeRefund[src]
    if t and (GetGameTimer() - t) > REFUND_WINDOW_MS then
        pendingBarricadeRefund[src] = nil
    end
end

-- Flow serveur-authoritatif : le client demande la pose, on valide + consomme
-- l'item, on repond ok/fail. Le client ne spawn le prop reseau qu'apres ok.
RegisterNetEvent('frz-craft:requestBarricade', function()
    local src = source
    local now = GetGameTimer()
    if (now - (lastBarricadeAt[src] or 0)) < 1000 then return end
    lastBarricadeAt[src] = now

    if not frzCore:hasItem(src, 'barricade', 1) then
        TriggerClientEvent('frz-craft:barricadeResult', src, false, 'Aucune barricade disponible.')
        return
    end
    if not frzCore:takeItem(src, 'barricade', 1) then
        TriggerClientEvent('frz-craft:barricadeResult', src, false, 'Echec : barricade non consommee.')
        return
    end
    -- On vient bien de consommer 1 barricade : on autorise 1 refund eventuel.
    pendingBarricadeRefund[src] = now
    TriggerClientEvent('frz-craft:barricadeResult', src, true)
end)

-- Refund au cas ou le client n'arrive pas a charger le prop apres qu'on a
-- deja consomme l'item (crash streaming, kick reseau, etc). Ne rembourse
-- QUE si une consommation recente (<15s) n'a pas encore ete refundee,
-- sinon un client pourrait appeler ce net event en boucle pour dupliquer.
RegisterNetEvent('frz-craft:barricadeSpawnFailed', function()
    local src = source
    clearExpiredRefunds(src)
    if not pendingBarricadeRefund[src] then return end
    pendingBarricadeRefund[src] = nil
    frzCore:giveItem(src, 'barricade', 1)
end)

-- Le client confirme le placement : on ferme la fenetre de refund pour
-- empecher un refund frauduleux apres succes.
RegisterNetEvent('frz-craft:barricadePlaced', function()
    local src = source
    pendingBarricadeRefund[src] = nil
end)

AddEventHandler('playerDropped', function()
    local src = source
    pendingBarricadeRefund[src] = nil
    lastBarricadeAt[src] = nil
    lastCraftAt[src] = nil
end)
