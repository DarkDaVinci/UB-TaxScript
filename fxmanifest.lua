fx_version 'cerulean'
game 'gta5'

author 'DarkDaVinci'
description 'ESX Davcna Skripta za dinamicno upravljanje'
version '1.3.0'

lua54 'yes'

shared_script 'config.lua'

client_scripts {
  '@es_extended/locale.lua',
  '@ox_lib/init.lua',
  'client.lua'
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  '@ox_lib/init.lua',
  'server.lua'
}

ui_page 'web/index.html'

files {
  'web/index.html',
  'web/style.css',
  'web/script.js'
}

dependencies {
  'ox_lib',
  'es_extended'
}
