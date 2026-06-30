-- ═══════════════════════════════════════════════════════════════════════════════
-- ATM System — Gameplay Enhancement Banking Mod for FiveM
-- fxmanifest.lua — Resource manifest
-- ═══════════════════════════════════════════════════════════════════════════════

fx_version('cerulean')
game('gta5')

author('Franklin Bryant IV')
description('ATM System — Full banking system with ATM interactions, cash/wallet, transfers, deposits, withdrawals, and admin management.')
version('1.0.0')
license('MIT')
url('https://github.com/franklinbryant/cfx-portfolio')

lua54('on')

shared_script('shared/config.lua')
shared_script('shared/util.lua')

client_script('client/main.lua')
client_script('client/atm.lua')
client_script('client/notify.lua')
client_script('client/blips.lua')

server_script('server/database.lua')
server_script('server/transactions.lua')
server_script('server/main.lua')

-- Optional: ox_lib for UI callbacks and notifications
dependency('ox_lib /optional/')

-- Optional: oxmysql for persistent storage (falls back to JSON file if absent)
dependency('oxmysql /optional/')