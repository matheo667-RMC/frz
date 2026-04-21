-- FRZ RP (frz-survival) - Parametres des ticks de survie et des effets.
-- Modifie ces valeurs pour rendre la survie plus ou moins punitive.

FrzSurvival = FrzSurvival or {}
FrzSurvival.Config = FrzSurvival.Config or {}

-- Interval des ticks de survie (ms). A chaque tick, on retire les deltas
-- definis ci-dessous aux stats.
FrzSurvival.Config.TickInterval = 60000 -- 1 min

-- Delta par tick (en points). Exemple : -0.5 de faim / min => 100 pts =
-- ~3h20 de jeu sans manger avant famine.
FrzSurvival.Config.HungerPerTick  = 0.5
FrzSurvival.Config.ThirstPerTick  = 0.7 -- la soif baisse plus vite que la faim
FrzSurvival.Config.FatiguePerTick = 0.2 -- la fatigue monte lentement en activite normale

-- Multiplicateur de consommation quand le joueur court / sprint.
FrzSurvival.Config.SprintMultiplier = 2.0

-- Seuils en-dessous desquels le joueur commence a prendre des degats.
FrzSurvival.Config.DamageThreshold = 10   -- sous 10 pts, degats HP
FrzSurvival.Config.DamagePerTick   = 5    -- HP retires par tick si sous seuil
FrzSurvival.Config.ShakeThreshold  = 25   -- sous 25 pts, cam shake + vision floue

-- Infection : si le joueur est mordu par un rodeur (evenement declenche par
-- frz-walkers), son compteur d'infection monte. A 100 => mort automatique.
FrzSurvival.Config.InfectionPerTick = 1.0  -- tick autonome une fois infecte
FrzSurvival.Config.InfectionOnBite  = 15.0 -- points gagnes par morsure
FrzSurvival.Config.BiteDamage       = 20   -- HP perdus par morsure

-- Effets de consommation (items manges / bus).
-- key = itemId, value = { hunger = +X, thirst = +Y, infection = -Z, health = +H }
FrzSurvival.Config.ConsumeEffects = {
    water_bottle = { thirst    = 40 },
    canned_food  = { hunger    = 35 },
    energy_bar   = { hunger    = 15, fatigue = 10 },
    bandage      = { health    = 20 },
    medkit       = { health    = 60, infection = -10 },
    antibiotics  = { infection = -50 },
}

-- Cooldown entre deux consommations (ms). Empeche le spam de bandages.
FrzSurvival.Config.ConsumeCooldown = 3000

-- HUD : position (% de l'ecran) et opacite.
FrzSurvival.Config.HudPositionX = 2.0  -- left %
FrzSurvival.Config.HudPositionY = 70.0 -- top %
FrzSurvival.Config.HudOpacity   = 0.85
