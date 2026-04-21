-- FRZ RP (frz-survival) - Boucle de ticks cote client.
-- On calcule les baisses de stats localement pour eviter d'alourdir le serveur,
-- et on pushe l'etat au serveur via frz-core toutes les FrzCore.Config.StateSyncInterval ms.

FrzSurvival = FrzSurvival or {}
FrzSurvival.Client = FrzSurvival.Client or {}

local frzCore = exports['frz-core']

-- Cache local de "dernier tick" pour gerer le multiplicateur sprint sans
-- double-comptage.
local lastTickAt = 0

local function applyTick()
    if not frzCore:isReady() then return end

    local ped = PlayerPedId()
    local sprinting = IsPedSprinting(ped) or IsPedRunning(ped)
    local mult = sprinting and FrzSurvival.Config.SprintMultiplier or 1.0

    local stats = frzCore:getStats()

    local hunger  = (stats.hunger  or 100) - FrzSurvival.Config.HungerPerTick  * mult
    local thirst  = (stats.thirst  or 100) - FrzSurvival.Config.ThirstPerTick  * mult
    local fatigue = (stats.fatigue or 100) - FrzSurvival.Config.FatiguePerTick * mult

    -- La fatigue monte si le joueur dort (ped ragdoll dans un lit, simplifie :
    -- ici on la recupere quand il est immobile > 30s -> geree dans effects.lua).

    frzCore:setStatLocal('hunger',  hunger)
    frzCore:setStatLocal('thirst',  thirst)
    frzCore:setStatLocal('fatigue', fatigue)

    -- Infection : une fois infecte, elle progresse meme en mangeant / buvant.
    local infection = stats.infection or 0
    if infection > 0 then
        infection = infection + FrzSurvival.Config.InfectionPerTick
        frzCore:setStatLocal('infection', infection)
    end
end

CreateThread(function()
    while true do
        Wait(FrzSurvival.Config.TickInterval)
        local now = GetGameTimer()
        if now - lastTickAt >= FrzSurvival.Config.TickInterval - 1000 then
            applyTick()
            lastTickAt = now
        end
    end
end)
