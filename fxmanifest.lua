fx_version 'cerulean'
game 'gta5'

name 'frz-rp-spawn'
author 'FRZ'
description 'FRZ RP - Spawn a LSIA au premier join, cinematique atterrissage avion, annonce vocale FR'
version '1.0.0'

lua54 'yes'

shared_script 'config.lua'

client_scripts {
    'client/plane.lua',
    'client/camera.lua',
    'client/announcement.lua',
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
    'html/welcome_fr.ogg',
    'html/plane_landing.ogg',
}
