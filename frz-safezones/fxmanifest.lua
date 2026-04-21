fx_version 'cerulean'
game 'gta5'

name 'frz-safezones'
author 'FRZ'
description 'FRZ RP - Zones refuges (LSIA, Altruist camp, Fort Zancudo) : pas de rodeurs, soin lent'
version '1.0.0'

lua54 'yes'

dependency 'frz-core'

shared_script 'config.lua'

client_scripts {
    'client/detection.lua',
    'client/indicators.lua',
    'client/regen.lua',
    'client/bridge_walkers.lua',
}
