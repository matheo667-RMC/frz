-- Dead Zone RP (frz-craft) - Recettes de craft.
-- Chaque recette a un id unique, des inputs (items a consommer), un output
-- (item produit + qty), et un temps de craft.

FrzCraft = FrzCraft or {}
FrzCraft.Config = FrzCraft.Config or {}

-- Temps de craft par defaut (ms) si la recette n'en specifie pas.
FrzCraft.Config.DefaultDuration = 4000

-- Liste des recettes. L'ordre determine l'ordre d'affichage dans /craft list.
FrzCraft.Config.Recipes = {
    {
        id     = 'bandage',
        label  = 'Bandage',
        inputs = { { item = 'cloth', count = 2 } },
        output = { item = 'bandage', count = 1 },
        duration = 3000,
    },
    {
        id     = 'medkit',
        label  = 'Kit de soin',
        inputs = { { item = 'bandage', count = 3 }, { item = 'antibiotics', count = 1 } },
        output = { item = 'medkit', count = 1 },
        duration = 6000,
    },
    {
        id     = 'melee_bat',
        label  = 'Batte cloutee',
        inputs = { { item = 'wood', count = 2 }, { item = 'nails', count = 5 } },
        output = { item = 'melee_bat', count = 1 },
        duration = 5000,
    },
    {
        id     = 'barricade',
        label  = 'Barricade (planche de bois)',
        inputs = { { item = 'wood', count = 3 }, { item = 'nails', count = 4 } },
        output = { item = 'barricade', count = 1 },
        duration = 4500,
    },
    {
        id     = 'pistol_ammo_pack',
        label  = '10 balles 9mm',
        inputs = { { item = 'scrap_metal', count = 1 } },
        output = { item = 'pistol_ammo', count = 10 },
        duration = 3500,
    },
    {
        id     = 'rifle_ammo_pack',
        label  = '5 balles fusil',
        inputs = { { item = 'scrap_metal', count = 2 } },
        output = { item = 'rifle_ammo', count = 5 },
        duration = 4500,
    },
}
