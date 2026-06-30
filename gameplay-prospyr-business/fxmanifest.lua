fx_version 'cerulean'
lua54 'yes'

game 'gta5'

name 'prospyr-business-manager'
author 'Prospyr 305'
description 'In-game business management system for RP servers — employee management, payroll, financial dashboard, admin panel, oxmysql + ox_lib powered.'
version '1.0.0'

shared_scripts {
    'config/config.lua',
}

client_scripts {
    'client/main.lua',
    'client/dashboard.lua',
    'client/business.lua',
    'client/employees.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/business.lua',
    'server/employees.lua',
    'server/finance.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
}

dependencies {
    'ox_lib',
    'oxmysql',
}

exports {
    'GetBusinesses',
    'CreateBusiness',
    'GetEmployees',
}