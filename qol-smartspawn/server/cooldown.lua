-- ═══════════════════════════════════════════════════════════════════════════════
-- SmartSpawn — Cooldown Manager
-- server/cooldown.lua
--
-- Manages per-player cooldowns with timestamp tracking.
-- Designed as a reusable module that could be imported by other resources.
-- ═══════════════════════════════════════════════════════════════════════════════

Cooldown = {} -- Global table, accessible by other server scripts in this resource

-- Store: { [serverId] = expirationTimestamp }
local cooldowns = {}

--- Set a cooldown for a player.
--- @param source number The player's server ID
--- @param seconds number Cooldown duration in seconds
function Cooldown.Set(source, seconds)
    if not source or not seconds then return end
    cooldowns[source] = os.time() + seconds
end

--- Get remaining cooldown time for a player.
--- @param source number The player's server ID
--- @return number remaining Seconds remaining (0 if no active cooldown)
function Cooldown.GetRemaining(source)
    if not cooldowns[source] then return 0 end
    local remaining = cooldowns[source] - os.time()
    if remaining <= 0 then
        cooldowns[source] = nil
        return 0
    end
    return remaining
end

--- Check if a player is currently on cooldown.
--- @param source number The player's server ID
--- @return boolean onCooldown
function Cooldown.IsOnCooldown(source)
    return Cooldown.GetRemaining(source) > 0
end

--- Clear a player's cooldown.
--- @param source number The player's server ID
function Cooldown.Clear(source)
    cooldowns[source] = nil
end

--- Clean up expired cooldowns (call periodically to free memory).
function Cooldown.Cleanup()
    local now = os.time()
    for id, expiry in pairs(cooldowns) do
        if expiry <= now then
            cooldowns[id] = nil
        end
    end
end

-- Periodic cleanup every 5 minutes
CreateThread(function()
    while true do
        Wait(300000)
        Cooldown.Cleanup()
    end
end)

-- Note: In FiveM, server scripts in the same resource share the same Lua state,
-- so the global Cooldown table is accessible from server/main.lua.
-- The `return Cooldown` also works with require() if Lua modules are enabled.
return Cooldown

-- Export for external resources that want to use this module
exports('getCooldownModule', function()
    return Cooldown
end)