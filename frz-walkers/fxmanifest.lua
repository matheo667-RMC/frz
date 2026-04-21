fx_version 'cerulean'
game 'gta5'

name 'frz-walkers'
author 'FRZ'
description 'FRZ RP - Rodeurs (zombies) : spawn dynamique, IA hostile, morsures, sons'
version '1.0.0'

lua54 'yes'

dependency 'frz-core'

shared_script 'config.lua'

client_scripts {
    'client/relationships.lua',
    'client/director.lua',
    'client/ai.lua',
    'client/bite.lua',
    'client/cleanup.lua',
    'client/sounds.lua',
}

server_scripts {
    'server/sync.lua',
}
