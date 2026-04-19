-- FRZ Inventaire - catalogue d'items partage client/serveur.
-- Chaque item : { label, weight (kg), stackable, max_stack, usable, description, icon }
-- icon : chemin relatif dans html/ (pas d'images en base64 - on utilise des emojis par defaut).
Items = {
    bread       = { label = 'Pain',              weight = 0.2, stackable = true,  max_stack = 10, usable = true,  icon = '🥖', description = 'Un morceau de pain frais.' },
    water       = { label = "Bouteille d'eau",   weight = 0.5, stackable = true,  max_stack = 10, usable = true,  icon = '💧', description = 'Hydrate.' },
    phone       = { label = 'Telephone',         weight = 0.2, stackable = false, max_stack = 1,  usable = true,  icon = '📱', description = 'Smartphone FRZ.' },
    wallet      = { label = 'Portefeuille',      weight = 0.1, stackable = false, max_stack = 1,  usable = false, icon = '💳', description = 'Contient votre carte bancaire.' },
    cash        = { label = 'Argent liquide',    weight = 0.0, stackable = true,  max_stack = 999999, usable = false, icon = '💵', description = 'Billets.' },
    bankcard    = { label = 'Carte bancaire',    weight = 0.0, stackable = false, max_stack = 1,  usable = true,  icon = '💳', description = 'Carte de la Banque FRZ.' },
    keys        = { label = 'Clefs',             weight = 0.1, stackable = false, max_stack = 1,  usable = false, icon = '🔑', description = 'Trousseau.' },
    cigarette   = { label = 'Cigarette',         weight = 0.01,stackable = true,  max_stack = 20, usable = true,  icon = '🚬', description = '' },
    lighter     = { label = 'Briquet',           weight = 0.05,stackable = false, max_stack = 1,  usable = true,  icon = '🔥', description = '' },
    burger      = { label = 'Burger',            weight = 0.3, stackable = true,  max_stack = 5,  usable = true,  icon = '🍔', description = '' },
    coffee      = { label = 'Cafe',              weight = 0.2, stackable = true,  max_stack = 5,  usable = true,  icon = '☕', description = '' },
    pistol      = { label = 'Pistolet',          weight = 1.2, stackable = false, max_stack = 1,  usable = true,  icon = '🔫', description = '' },
    medkit      = { label = 'Trousse de soins',  weight = 0.5, stackable = true,  max_stack = 5,  usable = true,  icon = '🩹', description = '' },
    rolex       = { label = 'Rolex',             weight = 0.2, stackable = false, max_stack = 1,  usable = false, icon = '⌚', description = 'Montre de luxe.' },
}

function GetItem(name)
    return Items[name]
end

function IsValidItem(name)
    return Items[name] ~= nil
end
