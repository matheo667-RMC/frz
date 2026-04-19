fx_version 'cerulean'
game 'gta5'

name 'frz-rp-spawn'
author 'FRZ'
description 'FRZ RP - Spawn a LSIA au premier join, cinematique atterrissage avion, annonce vocale FR'
version '1.0.0'

lua54 'yes'

-- Doit etre start-apres spawnmanager : on y attache notre callback d'autospawn
-- (fait le meme job que basic-gamemode, qui est deliberement desactive pour
-- ne pas ecraser notre spawn LSIA).
dependency 'spawnmanager'

shared_script 'config.lua'

client_scripts {
    'client/plane.lua',
    'client/camera.lua',
    'client/announcement.lua',
    'client/main.lua',
    'client/position_tracker.lua',
    'client/car_rental.lua',
}

server_scripts {
    'server/main.lua',
    'server/car_rental.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/welcome_fr.ogg',
    'html/plane_landing.ogg',
}
