fx_version 'cerulean'
game 'gta5'

name 'frz-safezones'
author 'Dead Zone RP'
description 'Dead Zone RP - Zones refuges (LSIA, Altruist camp, Fort Zancudo) : pas de rodeurs, soin lent'
version '1.0.0'

lua54 'yes'

dependency 'frz-core'
dependency 'frz-walkers'

shared_script 'config.lua'

client_scripts {
    'client/detection.lua',
    'client/indicators.lua',
    'client/regen.lua',
    'client/bridge_walkers.lua',
}
