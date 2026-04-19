fx_version 'cerulean'
game 'gta5'

name 'frz-rp-shop'
author 'FRZ'
description 'FRZ RP - Client QBCore qui livre en jeu les items achetes sur la boutique web (frz-rp-shop site).'
version '1.0.0'

lua54 'yes'

shared_script 'config.lua'

server_scripts {
    '@qb-core/shared/locale.lua',
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
}

dependencies {
    'qb-core',
}
