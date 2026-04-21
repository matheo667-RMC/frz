fx_version 'cerulean'
game 'gta5'

name 'frz-survival'
author 'FRZ'
description 'FRZ RP - Mecaniques de survie (faim, soif, fatigue, infection) + HUD'
version '1.0.0'

lua54 'yes'

dependency 'frz-core'

shared_script 'config.lua'

client_scripts {
    'client/ticks.lua',
    'client/effects.lua',
    'client/consume.lua',
    'client/hud.lua',
}

server_scripts {
    'server/consume.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
}
