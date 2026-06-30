-- ═══════════════════════════════════════════════════════════════════════════════
-- SmartSpawn — Quality-of-Life Vehicle Spawner for FiveM
-- fxmanifest.lua — Resource manifest
-- ═══════════════════════════════════════════════════════════════════════════════

fx_version('cerulean')
game('gta5')

author('Franklin Bryant IV')
description('SmartSpawn — Smart vehicle spawner with model validation, anti-abuse cooldowns, permission tiers, and full configuration.')
version('1.0.0')
license('MIT')
url('https://github.com/franklinbryant/cfx-portfolio')

lua54('on')

shared_script('shared/config.lua')
shared_script('shared/util.lua')

client_script('client/main.lua')
client_script('client/notify.lua')

server_script('server/cooldown.lua')
server_script('server/main.lua')

-- Optional dependency: ox_lib for enhanced notifications (falls back to native if absent)
dependency('ox_lib /optional/')