-- FRZ Inventaire - configuration
Config = Config or {}

-- Touche pour ouvrir l'inventaire (TAB est deja utilise par le jeu, on prend I).
-- Code de controle FiveM : https://docs.fivem.net/docs/game-references/controls/
Config.OpenKey = 'I'         -- touche d'ouverture
Config.OpenKeyCode = 249     -- INPUT_REPLAY_SHOWHOTKEY -> remap via RegisterKeyMapping

-- Taille de la grille d'inventaire (6 lignes x 5 colonnes = 30 slots).
Config.GridRows = 6
Config.GridCols = 5

-- Poids max du sac (kg). 0 = pas de limite.
Config.MaxWeight = 40.0

-- Slots de vetements autour du personnage (clefs lues par le client pour appliquer
-- les drawables GTA5). Chaque entree = { label, component_id }.
-- component_id : 0=face, 1=mask, 3=torso, 4=legs, 5=bag, 6=shoes, 7=accessory,
-- 8=undershirt, 9=body_armor, 10=decals, 11=top.
Config.ClothingSlots = {
    hat       = { label = 'Chapeau',    prop = 0 },  -- prop (hat)
    glasses   = { label = 'Lunettes',   prop = 1 },  -- prop (glasses)
    ears      = { label = 'Oreilles',   prop = 2 },  -- prop (ears)
    mask      = { label = 'Masque',     component = 1 },
    top       = { label = 'Haut',       component = 11 },
    undershirt= { label = 'T-shirt',    component = 8 },
    torso     = { label = 'Torse',      component = 3 },
    legs      = { label = 'Pantalon',   component = 4 },
    shoes     = { label = 'Chaussures', component = 6 },
    bag       = { label = 'Sac',        component = 5 },
    armor     = { label = 'Gilet',      component = 9 },
    accessory = { label = 'Accessoire', component = 7 },
    watch     = { label = 'Montre',     prop = 6 },
    bracelet  = { label = 'Bracelet',   prop = 7 },
}

-- Distance max pour ramasser un drop au sol.
Config.PickupDistance = 1.5

-- Duree de vie d'un drop au sol (s). 0 = infini.
Config.DropLifetime = 900

-- Persistance serveur : fichier JSON dans le dossier de la resource.
Config.PersistenceFile = 'inventories.json'
Config.DropsFile = 'drops.json'

-- Prop utilise pour afficher un drop au sol.
Config.DropProp = 'prop_drug_package_02'

-- Inventaire de depart (premier join).
Config.StartingInventory = {
    { name = 'bread',    count = 2, slot = 1 },
    { name = 'water',    count = 2, slot = 2 },
    { name = 'phone',    count = 1, slot = 3 },
    { name = 'wallet',   count = 1, slot = 4 },
}

-- Vetements de depart (map slot -> drawable/texture).
Config.StartingClothing = {}
