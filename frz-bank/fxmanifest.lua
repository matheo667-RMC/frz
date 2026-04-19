fx_version 'cerulean'
game 'gta5'

name 'frz-bank'
author 'FRZ'
description 'FRZ Bank - comptes bancaires, ATMs, interieur banque, integration phone & inventaire'
version '1.0.0'

lua54 'yes'

shared_script 'config.lua'

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
}
