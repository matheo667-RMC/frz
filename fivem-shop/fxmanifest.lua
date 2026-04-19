fx_version 'cerulean'
game 'gta5'

name 'frz-rp-shop'
author 'FRZ'
description 'FRZ RP - Client QBCore qui livre en jeu les items achetes sur la boutique web (frz-rp-shop site).'
version '1.0.0'

lua54 'yes'

-- config.lua est PARTAGE (cote client + serveur) mais ne contient AUCUN
-- secret. Les secrets (token API, etc.) sont dans config_server.lua qui est
-- charge uniquement cote serveur — les clients ne peuvent donc pas le dumper.
shared_script 'config.lua'

server_scripts {
    '@qb-core/shared/locale.lua',
    'config_server.lua',
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
}

dependencies {
    'qb-core',
}
