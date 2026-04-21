-- Dead Zone RP (frz-survival) - Effets de gameplay lies aux stats basses.
-- Quand faim/soif/fatigue tombent sous un seuil : tremblements, vision floue,
-- perte de HP. Quand infection = 100 : mort (transformation en rodeur).

FrzSurvival = FrzSurvival or {}
FrzSurvival.Client = FrzSurvival.Client or {}

local frzCore = exports['frz-core']

-- Liste des cam shakes natifs GTA V. On utilise 'DRUNK_SHAKE' qui est
-- suffisamment subtil pour ne pas rendre le jeu injouable.
local ACTIVE_SHAKE = 'DRUNK_SHAKE'

local shaking = false
local blurActive = false

local function triggerDamage(reason)
    local ped = PlayerPedId()
    local health = GetEntityHealth(ped)
    SetEntityHealth(ped, math.max(0, health - FrzSurvival.Config.DamagePerTick))
end

local function updateEffects()
    if not frzCore:isReady() then return end

    local stats = frzCore:getStats()
    local low = math.min(stats.hunger or 100, stats.thirst or 100, stats.fatigue or 100)

    -- Cam shake et blur si une stat est critique.
    if low <= FrzSurvival.Config.ShakeThreshold then
        if not shaking then
            ShakeGameplayCam(ACTIVE_SHAKE, 0.25)
            shaking = true
        end
        if not blurActive then
            -- Post fx TransitionMetalsSwitch donne un aspect flou / grisatre.
            AnimpostfxPlay('DeathFailMPDark', 0, true)
            blurActive = true
        end
    else
        if shaking then
            StopGameplayCamShaking(true)
            shaking = false
        end
        if blurActive then
            AnimpostfxStop('DeathFailMPDark')
            blurActive = false
        end
    end

    -- Degats HP si stats sous le seuil de dommage.
    if (stats.hunger or 100) <= FrzSurvival.Config.DamageThreshold
       or (stats.thirst or 100) <= FrzSurvival.Config.DamageThreshold then
        triggerDamage('starvation')
    end

    -- Infection max -> mort + ajout d'un statut "devenu rodeur" (cosmetique).
    if (stats.infection or 0) >= 100 then
        local ped = PlayerPedId()
        SetEntityHealth(ped, 0)
        TriggerEvent('frz-survival:turned')
    end
end

CreateThread(function()
    while true do
        Wait(2000)
        updateEffects()
    end
end)

-- Reset des effets visuels a la mort (evite un blur coince au respawn).
AddEventHandler('gameEventTriggered', function(name, args)
    if name == 'CEventNetworkEntityDamage' then
        local victim = args[1]
        if victim == PlayerPedId() and IsEntityDead(victim) then
            if shaking then StopGameplayCamShaking(true); shaking = false end
            if blurActive then AnimpostfxStop('DeathFailMPDark'); blurActive = false end
        end
    end
end)

-- Hook morsure rodeur -> infection + damage.
RegisterNetEvent('frz-survival:onBite', function()
    local stats = frzCore:getStats()
    local newInf = (stats.infection or 0) + FrzSurvival.Config.InfectionOnBite
    frzCore:setStatLocal('infection', newInf)

    local ped = PlayerPedId()
    SetEntityHealth(ped, math.max(0, GetEntityHealth(ped) - FrzSurvival.Config.BiteDamage))

    exports['frz-core']:notify('Tu as ete mordu ! Infection : ' .. math.floor(newInf) .. ' %')
end)
