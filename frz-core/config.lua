-- Dead Zone RP - Configuration partagee du noyau (frz-core).
-- Ce fichier est charge en shared_script : accessible cote client ET cote serveur.

FrzCore = FrzCore or {}
FrzCore.Config = FrzCore.Config or {}

-- Valeurs par defaut de l'etat d'un nouveau joueur (stats de survie).
-- Les autres ressources (frz-survival, frz-walkers...) lisent et modifient ces
-- stats via les exports server/client de frz-core.
FrzCore.Config.DefaultStats = {
    hunger    = 100, -- 100 = rassasie, 0 = famine
    thirst    = 100, -- 100 = hydrate, 0 = deshydrate
    fatigue   = 100, -- 100 = repose, 0 = epuise
    infection = 0,   -- 0 = sain, 100 = tourne en rodeur
}

-- Cout en kilo d'un item dans l'inventaire. Les items absents de cette table
-- comptent comme FrzCore.Config.DefaultItemWeight.
FrzCore.Config.ItemWeights = {
    water_bottle = 0.5,
    canned_food  = 0.4,
    energy_bar   = 0.1,
    bandage      = 0.05,
    medkit       = 0.3,
    antibiotics  = 0.1,
    wood         = 1.0,
    nails        = 0.2,
    scrap_metal  = 1.5,
    cloth        = 0.1,
    melee_bat    = 2.0,
    pistol_ammo  = 0.02,
    rifle_ammo   = 0.03,
    shotgun_ammo = 0.05,
}

FrzCore.Config.DefaultItemWeight = 0.2

-- Capacite maximum par defaut du sac a dos (kg).
FrzCore.Config.MaxInventoryWeight = 25.0

-- Libelles FR affiches pour les items (HUD, menus craft, loot...).
FrzCore.Config.ItemLabels = {
    water_bottle = "Bouteille d'eau",
    canned_food  = 'Conserve',
    energy_bar   = 'Barre energetique',
    bandage      = 'Bandage',
    medkit       = 'Kit de soin',
    antibiotics  = 'Antibiotiques',
    wood         = 'Bois',
    nails        = 'Clous',
    scrap_metal  = 'Ferraille',
    cloth        = 'Tissu',
    melee_bat    = 'Batte cloutee',
    pistol_ammo  = 'Balles 9mm',
    rifle_ammo   = 'Balles fusil',
    shotgun_ammo = 'Cartouches fusil a pompe',
    barricade    = 'Barricade',
}

-- Interval (ms) entre deux synchronisations client -> serveur de l'etat local
-- (utilise par frz-survival pour persister les ticks de faim/soif).
FrzCore.Config.StateSyncInterval = 30000

-- Liste des identifiants Discord/Steam/FiveM autorises a utiliser les commandes
-- admin (/frzgive, /frzsetstat, /frzwipe...). Laisser vide pour n'autoriser que
-- la console serveur. Exemples : 'discord:1234567890', 'license:abcdef...'.
FrzCore.Config.Admins = {}
