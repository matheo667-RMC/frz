-- FRZ RP (frz-survival) - HUD NUI affichant les stats de survie.
-- On envoie un message postMessage a chaque changement de stat (throttle 500 ms).

FrzSurvival = FrzSurvival or {}
FrzSurvival.Client = FrzSurvival.Client or {}

local frzCore = exports['frz-core']

local function send(msg)
    SendNUIMessage(msg)
end

-- Init du HUD : on configure la position / opacite depuis la config serveur.
CreateThread(function()
    Wait(500)
    send({
        type = 'init',
        positionX = FrzSurvival.Config.HudPositionX,
        positionY = FrzSurvival.Config.HudPositionY,
        opacity   = FrzSurvival.Config.HudOpacity,
    })
end)

-- Boucle de refresh du HUD (throttled a 500 ms).
CreateThread(function()
    while true do
        Wait(500)
        if frzCore:isReady() then
            local stats = frzCore:getStats()
            send({
                type = 'update',
                hunger    = math.floor(stats.hunger    or 100),
                thirst    = math.floor(stats.thirst    or 100),
                fatigue   = math.floor(stats.fatigue   or 100),
                infection = math.floor(stats.infection or 0),
            })
        end
    end
end)

-- Cache le HUD quand le joueur est dans une cinematique (fade out).
CreateThread(function()
    local lastHidden = false
    while true do
        Wait(500)
        local hidden = IsScreenFadedOut() or IsScreenFadingOut()
        if hidden ~= lastHidden then
            send({ type = 'visibility', visible = not hidden })
            lastHidden = hidden
        end
    end
end)
