-- ═══════════════════════════════════════════════════════════════════════════════
-- SmartSpawn — Client Notification Wrapper
-- client/notify.lua
--
-- Provides a unified notify function that uses ox_lib if available,
-- otherwise falls back to native GTA V notifications.
-- ═══════════════════════════════════════════════════════════════════════════════

Notify = {}

--- Send a notification to the player.
--- @param message string The message to display
--- @param type string 'info' | 'success' | 'error' | 'warning'
--- @param duration number|nil Duration in ms (defaults to Config.NotifyDuration)
function Notify.Send(message, type, duration)
    duration = duration or Config.NotifyDuration

    if Config.UseOxLib and GetResourceState('ox_lib') == 'started' then
        -- ox_lib is available — use its notify system
        lib.notify({
            title = 'SmartSpawn',
            description = message,
            type = type or 'info',
            duration = duration,
            position = 'top-right',
        })
    else
        -- Fall back to native GTA V notification
        local icon = 'CHAR_CARSITE2'
        local hudColor = {
            info    = 0,  -- default
            success = 18, -- green
            error   = 6,  -- red
            warning = 7,  -- amber
        }

        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(message)
        EndTextCommandThefeedPostMessyText(false)
        ThefeedSetNextPostNotificationType(hudColor[type] or 0)
    end
end