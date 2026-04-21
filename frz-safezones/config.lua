-- Dead Zone RP (frz-safezones) - Liste des zones refuges.
-- Chaque zone a un centre, un rayon (m), un libelle FR et des options.

FrzSafeZones = FrzSafeZones or {}
FrzSafeZones.Config = FrzSafeZones.Config or {}

-- Zones refuges (pas de rodeurs, soin lent, message d'entree/sortie).
FrzSafeZones.Config.Zones = {
    {
        id     = 'lsia',
        label  = 'LSIA - Aeroport international',
        center = vector3(-1037.5, -2738.0, 20.17),
        radius = 180.0,
        slowHeal = true,
        restoreHunger = 0.5,  -- points par tick
        restoreThirst = 0.5,
    },
    {
        id     = 'paleto',
        label  = 'Paleto Bay - Camp de survivants',
        center = vector3(-275.0, 6214.0, 31.0),
        radius = 120.0,
        slowHeal = true,
        restoreHunger = 0.3,
        restoreThirst = 0.3,
    },
    {
        id     = 'altruist',
        label  = 'Camp Altruiste - Mt Chiliad',
        center = vector3(-1000.0, 4425.0, 25.0),
        radius = 80.0,
        slowHeal = false,
        restoreHunger = 0.0,
        restoreThirst = 0.0,
    },
}

-- Intervalle (ms) entre deux ticks de regen dans les safe zones.
FrzSafeZones.Config.RegenInterval = 5000
-- HP regagnes par tick dans une zone avec slowHeal = true.
FrzSafeZones.Config.HealPerTick = 5
