-- ═══════════════════════════════════════════════════════════════════════════════
-- ATM System — Client Notification Wrapper
-- client/notify.lua
-- ═══════════════════════════════════════════════════════════════════════════════

Notify = {}

function Notify.Send(message, type, duration)
    duration = duration or Config.NotifyDuration

    if Config.UseOxLib and GetResourceState('ox_lib') == 'started' then
        lib.notify({
            title = Config.MenuTitle or 'ATM System',
            description = message,
            type = type or 'info',
            duration = duration,
            position = 'top-right',
        })
    else
        local hudColor = { info = 0, success = 18, error = 6, warning = 7 }
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(message)
        EndTextCommandThefeedPostMessyText(false)
        ThefeedSetNextPostNotificationType(hudColor[type] or 0)
    end
end