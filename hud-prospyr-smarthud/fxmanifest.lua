fx_version 'cerulean'
lua54 'yes'

game 'gta5'

name 'prospyr-smarthud'
author 'Prospyr 305'
description 'Clean, modern, customizable HUD for FiveM servers — ox_status compatible, NUI settings panel, performance-optimized.'
version '1.0.0'

shared_scripts {
    'config/config.lua',
    'config/positions.lua',
}

client_scripts {
    'client/main.lua',
    'client/hud.lua',
    'client/settings.lua',
    'client/voice.lua',
    'client/vehicle.lua',
}

server_scripts {
    'server/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
}

dependencies {
    'ox_lib',
    'ox_status',
}

-- Provide exports for other resources
exports {
    'GetHUDConfig',
    'ToggleHUD',
    'SetHUDElement',
}