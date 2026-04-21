-- FRZ RP (frz-survival) - Consommation d'items (manger / boire / soigner).
-- Commandes chat :
--   /eat <itemId>   : mange l'item (canned_food, energy_bar...)
--   /drink <itemId> : boit l'item (water_bottle)
--   /use <itemId>   : utilise un medkit / bandage / antibiotiques

FrzSurvival = FrzSurvival or {}
FrzSurvival.Client = FrzSurvival.Client or {}

local frzCore = exports['frz-core']

local lastUseAt = 0

local function useItem(itemId)
    if not itemId or itemId == '' then
        frzCore:notify('Usage : /use <itemId>')
        return
    end
    local now = GetGameTimer()
    if now - lastUseAt < FrzSurvival.Config.ConsumeCooldown then
        frzCore:notify('Attends un peu avant de reutiliser un objet.')
        return
    end
    local effect = FrzSurvival.Config.ConsumeEffects[itemId]
    if not effect then
        frzCore:notify('Cet objet ne peut pas etre consomme.')
        return
    end
    if not frzCore:hasItem(itemId, 1) then
        frzCore:notify('Tu n as pas cet objet.')
        return
    end
    lastUseAt = now
    TriggerServerEvent('frz-survival:consume', itemId)
end

RegisterCommand('use',   function(_, args) useItem(args[1]) end, false)
RegisterCommand('eat',   function(_, args) useItem(args[1]) end, false)
RegisterCommand('drink', function(_, args) useItem(args[1]) end, false)

TriggerEvent('chat:addSuggestion', '/use',   'Utiliser un objet (bandage, medkit, antibiotics)', { { name = 'item', help = 'ex: bandage' } })
TriggerEvent('chat:addSuggestion', '/eat',   'Manger un item (ex: canned_food)', { { name = 'item', help = 'ex: canned_food' } })
TriggerEvent('chat:addSuggestion', '/drink', 'Boire un item (ex: water_bottle)', { { name = 'item', help = 'ex: water_bottle' } })

-- Le serveur confirme la consommation : on applique les effets localement.
RegisterNetEvent('frz-survival:onConsumed', function(itemId)
    local effect = FrzSurvival.Config.ConsumeEffects[itemId]
    if not effect then return end

    local stats = frzCore:getStats()
    for statName, delta in pairs(effect) do
        if statName == 'health' then
            local ped = PlayerPedId()
            local hp  = GetEntityHealth(ped) + delta
            SetEntityHealth(ped, math.min(GetEntityMaxHealth(ped), math.max(0, hp)))
        else
            frzCore:setStatLocal(statName, (stats[statName] or 0) + delta)
        end
    end
    -- Animation de consommation (simple : burger natif).
    local ped = PlayerPedId()
    if itemId == 'water_bottle' then
        RequestAnimDict('mp_player_intdrink')
        local t0 = GetGameTimer()
        while not HasAnimDictLoaded('mp_player_intdrink') and GetGameTimer() - t0 < 2000 do Wait(10) end
        TaskPlayAnim(ped, 'mp_player_intdrink', 'loop_bottle', 8.0, -8.0, 2500, 49, 0, false, false, false)
    else
        RequestAnimDict('mp_player_inteat@burger')
        local t0 = GetGameTimer()
        while not HasAnimDictLoaded('mp_player_inteat@burger') and GetGameTimer() - t0 < 2000 do Wait(10) end
        TaskPlayAnim(ped, 'mp_player_inteat@burger', 'mp_player_int_eat_burger', 8.0, -8.0, 2500, 49, 0, false, false, false)
    end

    frzCore:notify(string.format('Tu as utilise : %s', FrzCore.Config.ItemLabels[itemId] or itemId))
end)
