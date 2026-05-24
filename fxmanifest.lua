fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Tyler The Dev'
description 'Server-synced AOP and Priority management system developed by Tyler The Dev.'
version '1.0.0'

shared_scripts {
    'config.lua',
    'shared/utils.lua'
}

server_scripts {
    'server/permissions.lua',
    'server/state.lua',
    'server/commands.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}
