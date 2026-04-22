fx_version 'cerulean'
game 'gta5'

name 'frz-loot'
author 'Dead Zone RP'
description 'Dead Zone RP - Loot de ressources (dumpsters, epaves, corps de rodeurs)'
version '1.0.0'

lua54 'yes'

dependency 'frz-core'
dependency 'frz-walkers'

-- FrzCore.Config est partage depuis frz-core (VM Lua isolee sinon).
shared_scripts {
    '@frz-core/config.lua',
    'config.lua',
}

client_scripts {
    'client/world_containers.lua',
    'client/corpse_loot.lua',
}

server_scripts {
    'server/loot_tables.lua',
    'server/roll.lua',
}
