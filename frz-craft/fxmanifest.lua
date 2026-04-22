fx_version 'cerulean'
game 'gta5'

name 'frz-craft'
author 'Dead Zone RP'
description 'Dead Zone RP - Craft (bandages, batte, medkits, barricades, munitions)'
version '1.0.0'

lua54 'yes'

dependency 'frz-core'

-- On partage la config de frz-core (FrzCore.Config.ItemLabels, ...) car chaque
-- ressource FiveM a sa propre VM Lua (globals isoles). Sans ce @, FrzCore est
-- nil ici et on crash sur chaque index.
shared_scripts {
    '@frz-core/config.lua',
    'config.lua',
}

client_scripts {
    'client/menu.lua',
    'client/barricade.lua',
}

server_scripts {
    'server/craft.lua',
}
