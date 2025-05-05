fx_version 'cerulean'
game 'gta5'

description 'Skripta za davke'
author 'DarkDaVinci'
version '1.0.1'

lua54 'yes'

shared_script 'config.lua'

client_scripts { 'client.lua' }
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/script.js'
}