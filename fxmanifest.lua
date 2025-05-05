fx_version 'cerulean'
game 'gta5'

description 'Skripta za davke'
author 'DarkDaVinci'
version '1.0.0'

server_scripts {
    '@es_extended/imports.lua',     --- SAMO ZA ESx!!!!
    '@oxmysql/lib/MySQL.lua',      -- oxmysql obvezen
    '@ox_lib/init.lua',            -- ox_lib obvezen
    'config.lua',
    'server.lua'
}


lua54 'yes'
dependency 'ox_lib'