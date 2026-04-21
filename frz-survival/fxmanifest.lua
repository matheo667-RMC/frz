fx_version 'cerulean'
game 'gta5'

name 'frz-survival'
author 'Dead Zone RP'
description 'Dead Zone RP - Mecaniques de survie (faim, soif, fatigue, infection) + HUD'
version '1.0.0'

lua54 'yes'

dependency 'frz-core'

-- FrzCore.Config est partage depuis frz-core (VM Lua isolee sinon).
shared_scripts {
    '@frz-core/config.lua',
    'config.lua',
}

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
