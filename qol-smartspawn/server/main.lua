-- ═══════════════════════════════════════════════════════════════════════════════
-- SmartSpawn — Server Main
-- server/main.lua
--
-- Handles permission checks, cooldown management, vehicle tracking,
-- and validation callbacks to the client.
-- ═══════════════════════════════════════════════════════════════════════════════

-- Cooldown module is loaded via fxmanifest.lua as a server_script before this file.
-- cooldown.lua sets the global `Cooldown` table with:
--   Cooldown.Set(source, seconds)       — set a player's cooldown
--   Cooldown.GetRemaining(source)        — get seconds remaining (0 if none)
--   Cooldown.IsOnCooldown(source)       — boolean
--   Cooldown.Clear(source)               — clear a player's cooldown
--   Cooldown.Cleanup()                    — remove expired entries
-- The module pattern (return Cooldown) also works with FiveM's require() if enabled.

-- Track vehicles spawned by each player: { [serverId] = { netIds = {}, models = {} } }
local PlayerVehicles = {}

-- ── Helper: Determine Player Tier ─────────────────────────────────────────────

--- Get the player's tier based on ACE permissions.
--- @param source number The player's server ID
--- @return string tier 'admin' | 'vip' | 'default'
local function GetPlayerTier(source)
    -- Check from highest to lowest priority
    for perm, tier in pairs(Config.Tiers) do
        if IsPlayerAceAllowed(source, perm) then
            -- Return the highest tier found
            -- (Iterate in priority order: admin, vip, default)
            if tier == 'admin' then return 'admin' end
        end
    end

    -- Check VIP
    if IsPlayerAceAllowed(source, 'smartspawn.tier.vip') then
        return 'vip'
    end

    return 'default'
end

-- ── Helper: Get Cooldown for Tier ──────────────────────────────────────────────

--- Get the cooldown duration for a given tier.
--- @param tier string The player's tier
--- @return number cooldownSeconds
local function GetCooldownForTier(tier)
    if tier == 'admin' then
        return Config.Cooldown.admin
    elseif tier == 'vip' then
        return Config.Cooldown.vip
    else
        return Config.Cooldown.default
    end
end

-- ── ox_lib Callback: Validate Spawn Request ───────────────────────────────────

if GetResourceState('ox_lib') == 'started' then
    lib.callback.register('smartspawn:server:validate', function(source, model)
        local tier = GetPlayerTier(source)

        -- Check category permission
        local category = Util.GetVehicleCategory(joaat(model))
        if not Util.IsCategoryAllowed(category, tier) then
            return {
                allowed = false,
                reason = Util.L('category_denied', category),
                tier = tier,
            }
        end

        -- Check cooldown
        local cooldownRemaining = Cooldown.GetRemaining(source)
        if Config.Cooldown.enabled and cooldownRemaining > 0 then
            return {
                allowed = false,
                reason = Util.L('cooldown_active', math.ceil(cooldownRemaining)),
                tier = tier,
            }
        end

        -- Check max vehicles
        local playerVehs = PlayerVehicles[source]
        if playerVehs and #playerVehs.netIds >= Config.MaxVehiclesPerPlayer then
            return {
                allowed = false,
                reason = Util.L('max_vehicles', Config.MaxVehiclesPerPlayer),
                tier = tier,
            }
        end

        -- All checks passed — set cooldown
        local cdTime = GetCooldownForTier(tier)
        if cdTime > 0 then
            Cooldown.Set(source, cdTime)
        end

        return {
            allowed = true,
            tier = tier,
        }
    end)
end

-- ── Net Event Fallback (no ox_lib) ─────────────────────────────────────────────

RegisterNetEvent('smartspawn:server:requestSpawn', function(model)
    local source = source

    -- Validate model is a string (anti-exploit)
    if type(model) ~= 'string' or #model > 30 then
        return
    end

    local tier = GetPlayerTier(source)
    local category = Util.GetVehicleCategory(joaat(model))

    local response = { model = model, allowed = false, reason = '', tier = tier }

    -- Category check
    if not Util.IsCategoryAllowed(category, tier) then
        response.reason = Util.L('category_denied', category)
        TriggerClientEvent('smartspawn:client:spawnResponse', source, response)
        return
    end

    -- Cooldown check
    local cooldownRemaining = Cooldown.GetRemaining(source)
    if Config.Cooldown.enabled and cooldownRemaining > 0 then
        response.reason = Util.L('cooldown_active', math.ceil(cooldownRemaining))
        TriggerClientEvent('smartspawn:client:spawnResponse', source, response)
        return
    end

    -- Max vehicles check
    local playerVehs = PlayerVehicles[source]
    if playerVehs and #playerVehs.netIds >= Config.MaxVehiclesPerPlayer then
        response.reason = Util.L('max_vehicles', Config.MaxVehiclesPerPlayer)
        TriggerClientEvent('smartspawn:client:spawnResponse', source, response)
        return
    end

    -- Approved
    response.allowed = true
    local cdTime = GetCooldownForTier(tier)
    if cdTime > 0 then
        Cooldown.Set(source, cdTime)
    end

    TriggerClientEvent('smartspawn:client:spawnResponse', source, response)
end)

-- ── Track Spawned Vehicles ─────────────────────────────────────────────────────

RegisterNetEvent('smartspawn:server:spawnComplete', function(netId, model)
    local source = source

    if not PlayerVehicles[source] then
        PlayerVehicles[source] = { netIds = {}, models = {} }
    end

    table.insert(PlayerVehicles[source].netIds, netId)
    table.insert(PlayerVehicles[source].models, model)

    -- Validate the entity exists and is a vehicle
    local entity = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(entity) or not IsEntityAVehicle(entity) then
        -- Remove invalid entry
        for i = #PlayerVehicles[source].netIds, 1, -1 do
            if PlayerVehicles[source].netIds[i] == netId then
                table.remove(PlayerVehicles[source].netIds, i)
                table.remove(PlayerVehicles[source].models, i)
            end
        end
    end
end)

-- ── Refund Cooldown (when client-side validation fails) ────────────────────────

RegisterNetEvent('smartspawn:server:refundCooldown', function()
    Cooldown.Clear(source)
end)

-- ── Cleanup on Player Disconnect ──────────────────────────────────────────────

AddEventHandler('playerDropped', function()
    local source = source

    -- Clear cooldown
    Cooldown.Clear(source)

    -- Optionally delete vehicles (they'll despawn if no one is near, but let's clean up)
    if PlayerVehicles[source] then
        for _, netId in ipairs(PlayerVehicles[source].netIds) do
            local entity = NetworkGetEntityFromNetworkId(netId)
            if DoesEntityExist(entity) then
                DeleteEntity(entity)
            end
        end
        PlayerVehicles[source] = nil
    end
end)

-- ── Admin Command: Clear Cooldown ─────────────────────────────────────────────

RegisterCommand('spawnclear', function(source, args)
    local targetId = tonumber(args[1])
    if not targetId then
        -- Clear self if admin
        if IsPlayerAceAllowed(source, 'smartspawn.tier.admin') then
            Cooldown.Clear(source)
            Notify.Send('Cooldown cleared.', 'success')
        end
        return
    end

    -- Admin clearing another player's cooldown
    if IsPlayerAceAllowed(source, 'smartspawn.tier.admin') then
        Cooldown.Clear(targetId)
    end
end, true)

-- ── Exports for Other Resources ────────────────────────────────────────────────

exports('clearCooldown', function(playerId)
    Cooldown.Clear(playerId)
end)

exports('getCooldown', function(playerId)
    return Cooldown.GetRemaining(playerId)
end)

exports('getPlayerVehicles', function(playerId)
    return PlayerVehicles[playerId] or { netIds = {}, models = {} }
end)