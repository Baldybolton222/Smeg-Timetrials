fx_version 'cerulean'
game 'gta5'

description 'Smeg Timetrials'
version '1.0.0'

ui_page 'html/index.html'

shared_scripts {
    'config.lua',
    'utils.lua'
}

client_scripts {
    "client/client.lua",
    "tracks.lua",
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    "server/server.lua"
}

files {
    'html/*.html',
    'html/*.css',
    'html/*.js',
}

lua54 'yes'
