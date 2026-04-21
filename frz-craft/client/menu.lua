-- FRZ RP (frz-craft) - Menu de craft via chat (pas de NUI pour rester simple).
-- Commandes :
--   /craft         : liste les recettes disponibles avec l'etat (faisable ou pas).
--   /craft <id>    : lance le craft (si possible) avec progress bar dans le chat.

FrzCraft = FrzCraft or {}
FrzCraft.Client = FrzCraft.Client or {}

local frzCore = exports['frz-core']

local crafting = false

local function findRecipe(id)
    for _, r in ipairs(FrzCraft.Config.Recipes) do
        if r.id == id then return r end
    end
    return nil
end

local function canCraft(recipe)
    for _, input in ipairs(recipe.inputs) do
        if not frzCore:hasItem(input.item, input.count) then
            return false
        end
    end
    return true
end

local function describeInputs(recipe)
    local parts = {}
    for _, input in ipairs(recipe.inputs) do
        local label = FrzCore.Config.ItemLabels[input.item] or input.item
        parts[#parts + 1] = string.format('%dx %s', input.count, label)
    end
    return table.concat(parts, ', ')
end

local function listRecipes()
    TriggerEvent('chat:addMessage', { color = { 180, 220, 255 }, args = { 'Craft', 'Recettes disponibles :' } })
    for _, recipe in ipairs(FrzCraft.Config.Recipes) do
        local status = canCraft(recipe) and '[OK]' or '[-]'
        local outLabel = FrzCore.Config.ItemLabels[recipe.output.item] or recipe.output.item
        TriggerEvent('chat:addMessage', {
            color = canCraft(recipe) and { 120, 200, 120 } or { 180, 180, 180 },
            args = {
                status .. ' ' .. recipe.id,
                string.format('%dx %s  <-  %s', recipe.output.count, outLabel, describeInputs(recipe)),
            },
        })
    end
    TriggerEvent('chat:addMessage', { color = { 180, 180, 180 }, args = { 'Astuce', '/craft <id> pour lancer un craft.' } })
end

local function playCraftAnim(duration)
    local ped = PlayerPedId()
    RequestAnimDict('amb@world_human_hammering@male@base')
    local t0 = GetGameTimer()
    while not HasAnimDictLoaded('amb@world_human_hammering@male@base') and GetGameTimer() - t0 < 1500 do Wait(20) end
    if HasAnimDictLoaded('amb@world_human_hammering@male@base') then
        TaskPlayAnim(ped, 'amb@world_human_hammering@male@base', 'base', 8.0, -8.0, duration, 49, 0, false, false, false)
    end
    Wait(duration)
    ClearPedTasks(ped)
end

RegisterCommand('craft', function(_, args)
    if crafting then
        frzCore:notify('Deja en train de crafter.')
        return
    end

    if #args == 0 then
        listRecipes()
        return
    end

    local recipe = findRecipe(args[1])
    if not recipe then
        frzCore:notify('Recette inconnue. Tape /craft pour la liste.')
        return
    end
    if not canCraft(recipe) then
        frzCore:notify('Ressources insuffisantes : ' .. describeInputs(recipe))
        return
    end

    crafting = true
    frzCore:notify('Craft en cours : ' .. recipe.label)
    playCraftAnim(recipe.duration or FrzCraft.Config.DefaultDuration)
    TriggerServerEvent('frz-craft:requestCraft', recipe.id)
    crafting = false
end, false)

TriggerEvent('chat:addSuggestion', '/craft', 'Craft FRZ RP - sans argument = liste, avec = lance le craft',
    { { name = 'recipe_id', help = 'ex: bandage, medkit, melee_bat, barricade' } })

RegisterNetEvent('frz-craft:result', function(ok, message)
    frzCore:notify((ok and '+ ' or '- ') .. (message or ''))
end)
