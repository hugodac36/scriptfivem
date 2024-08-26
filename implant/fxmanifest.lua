fx_version 'cerulean'
game 'gta5'

author 'KiKu'
description 'Script d\'implant'
version '1.0.0'

lua54 'yes'  -- Activer Lua 5.4

dependencies {
    'ox_lib',  -- Ajouter ox_lib comme dépendance
    'ox_target',
}

shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',  -- Charger ox_lib ici
    'config.lua',
}

client_scripts {
    '@esx_menu_default/esx_menu_default.lua',
    'client.lua',
}

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

ui_page 'html/index.html'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua',
}
