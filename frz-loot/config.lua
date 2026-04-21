-- FRZ RP (frz-loot) - Config du systeme de loot.

FrzLoot = FrzLoot or {}
FrzLoot.Config = FrzLoot.Config or {}

-- Modeles de props consideres comme "fouillables" quand le joueur passe
-- a proximite. On utilise le hash pour matcher les props dynamiques (bennes,
-- poubelles, caisses) deja places par GTA V de base.
FrzLoot.Config.ContainerModels = {
    ['prop_dumpster_01a']   = 'dumpster',
    ['prop_dumpster_02a']   = 'dumpster',
    ['prop_dumpster_02b']   = 'dumpster',
    ['prop_dumpster_3a']    = 'dumpster',
    ['prop_dumpster_4a']    = 'dumpster',
    ['prop_dumpster_4b']    = 'dumpster',
    ['prop_bin_01a']        = 'trash',
    ['prop_bin_02a']        = 'trash',
    ['prop_bin_04a']        = 'trash',
    ['prop_bin_05a']        = 'trash',
    ['prop_bin_07a']        = 'trash',
    ['prop_bin_07b']        = 'trash',
    ['prop_toolchest_01']   = 'toolbox',
    ['prop_toolchest_02']   = 'toolbox',
    ['prop_toolchest_05']   = 'toolbox',
    ['prop_cs_cardbox_01']  = 'cardboard',
    ['prop_cardbdbox_md_2'] = 'cardboard',
}

-- Distance max de detection d'un container (m).
FrzLoot.Config.SearchRange = 1.8
-- Duree de la fouille (ms).
FrzLoot.Config.SearchDuration = 3500
-- Cooldown par container apres une fouille (ms).
FrzLoot.Config.ContainerCooldown = 15 * 60 * 1000 -- 15 min

-- Tables de loot par type de container. Chaque entree :
--   item   : id d'item frz-core
--   min,max: nombre possible
--   chance : probabilite de tirage (0.0 - 1.0)
-- A chaque fouille, on tire chaque ligne independamment (plusieurs items
-- possibles en un seul loot).
FrzLoot.Config.LootTables = {
    dumpster = {
        { item = 'canned_food',  min = 1, max = 2, chance = 0.35 },
        { item = 'water_bottle', min = 1, max = 1, chance = 0.25 },
        { item = 'cloth',        min = 1, max = 3, chance = 0.45 },
        { item = 'scrap_metal',  min = 1, max = 2, chance = 0.30 },
        { item = 'bandage',      min = 1, max = 1, chance = 0.10 },
    },
    trash = {
        { item = 'cloth',        min = 1, max = 2, chance = 0.50 },
        { item = 'energy_bar',   min = 1, max = 1, chance = 0.20 },
        { item = 'water_bottle', min = 1, max = 1, chance = 0.15 },
        { item = 'nails',        min = 1, max = 3, chance = 0.25 },
    },
    toolbox = {
        { item = 'nails',        min = 2, max = 5, chance = 0.70 },
        { item = 'scrap_metal',  min = 1, max = 3, chance = 0.50 },
        { item = 'wood',         min = 1, max = 2, chance = 0.35 },
    },
    cardboard = {
        { item = 'canned_food',  min = 1, max = 2, chance = 0.45 },
        { item = 'energy_bar',   min = 1, max = 2, chance = 0.35 },
        { item = 'bandage',      min = 1, max = 2, chance = 0.20 },
        { item = 'antibiotics',  min = 1, max = 1, chance = 0.05 },
    },
    corpse = {
        { item = 'cloth',        min = 1, max = 2, chance = 0.60 },
        { item = 'bandage',      min = 1, max = 1, chance = 0.20 },
        { item = 'pistol_ammo',  min = 1, max = 5, chance = 0.25 },
        { item = 'rifle_ammo',   min = 1, max = 3, chance = 0.10 },
    },
}

-- Chance qu'un rodeur tue droppe un loot (sinon le corps est vide).
FrzLoot.Config.CorpseLootChance = 0.6
