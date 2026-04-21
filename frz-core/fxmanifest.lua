fx_version 'cerulean'
game 'gta5'

name 'frz-core'
author 'Dead Zone RP'
description 'Dead Zone RP - Noyau partage (etat joueur, inventaire, evenements) pour les ressources de survie'
version '1.0.0'

lua54 'yes'

shared_script 'config.lua'

client_scripts {
    'client/state.lua',
    'client/inventory.lua',
    'client/notify.lua',
    'client/keys.lua',
}

server_scripts {
    'server/persistence.lua',
    'server/state.lua',
    'server/inventory.lua',
    'server/commands.lua',
}
