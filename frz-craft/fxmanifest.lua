fx_version 'cerulean'
game 'gta5'

name 'frz-craft'
author 'FRZ'
description 'FRZ RP - Craft (bandages, batte, medkits, barricades, munitions)'
version '1.0.0'

lua54 'yes'

dependency 'frz-core'

shared_script 'config.lua'

client_scripts {
    'client/menu.lua',
    'client/barricade.lua',
}

server_scripts {
    'server/craft.lua',
}
