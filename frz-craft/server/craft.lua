-- FRZ RP (frz-craft) - Validation et execution serveur des crafts.
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

RegisterNetEvent('frz-craft:consumeBarricade', function()
    local src = source
    frzCore:takeItem(src, 'barricade', 1)
end)
