fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'heino_netscenes'
author 'Heino'
description 'Networked synchronized scenes for heists, hacking, robberies and more'
version '1.0.0'
repository 'https://github.com/HeinoDev/heino_netscenes'

shared_scripts {
    '@ox_lib/init.lua',
}

client_scripts {
    'client/netscene.lua',
    'client/creation.lua',
    'client/scenes/*.lua',
}

server_scripts {
    'server/logs.lua',
    'server/main.lua',
}

files {
    'config.lua',
}

dependencies {
    'ox_lib',
}
