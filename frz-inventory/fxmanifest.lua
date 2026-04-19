fx_version 'cerulean'
game 'gta5'

name 'frz-inventory'
author 'FRZ'
description 'FRZ Inventaire - inventaire grille + slots vetements + drop au sol (standalone)'
version '1.0.0'

lua54 'yes'

shared_scripts {
    'config.lua',
    'shared/items.lua',
}

client_scripts {
    'client/main.lua',
    'client/drops.lua',
}

server_scripts {
    'server/main.lua',
    'server/drops.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
}
