fx_version 'cerulean'
game 'gta5'

name 'frz-phone'
author 'FRZ'
description 'FRZ Phone - smartphone FiveM (iPhone / Android) : appels, SMS, banque, parametres'
version '1.0.0'

lua54 'yes'

shared_script 'config.lua'

client_scripts {
    'client/main.lua',
    'client/calls.lua',
}

server_scripts {
    'server/main.lua',
    'server/calls.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
}
