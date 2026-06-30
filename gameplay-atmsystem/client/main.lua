-- ═══════════════════════════════════════════════════════════════════════════════
-- ATM System — Client Main
-- client/main.lua
--
-- Client-side command registration for chat commands.
-- Handles /balance, /cash, /givecash commands (client-side validation + server events).
-- ═══════════════════════════════════════════════════════════════════════════════

-- ── /balance Command ──────────────────────────────────────────────────────────

RegisterCommand(Config.Commands.balance, function()
    if not Config.Enabled then
        Notify.Send(Util.L('resource_disabled'), 'error')
        return
    end
    TriggerServerEvent('atmsystem:server:checkBalance')
end, false)

-- ── /cash Command ─────────────────────────────────────────────────────────────

RegisterCommand(Config.Commands.cash, function()
    if not Config.Enabled then
        Notify.Send(Util.L('resource_disabled'), 'error')
        return
    end
    TriggerServerEvent('atmsystem:server:checkBalance')
end, false)

-- ── /transfer Command ──────────────────────────────────────────────────────────

RegisterCommand(Config.Commands.transfer, function(_, args)
    if not Config.Enabled then return end

    local targetId = tonumber(args[1])
    local amount = tonumber(args[2])

    if not targetId or not amount then
        Notify.Send(Util.L('usage_transfer', Config.Commands.transfer), 'warning')
        return
    end

    if targetId == cache.serverId then
        Notify.Send(Util.L('transfer_self'), 'error')
        return
    end

    TriggerServerEvent('atmsystem:server:transfer', targetId, amount)
end, false)

-- ── /givecash Command ──────────────────────────────────────────────────────────

RegisterCommand(Config.Commands.givecash, function(_, args)
    if not Config.Enabled then return end

    local targetId = tonumber(args[1])
    local amount = tonumber(args[2])

    if not targetId or not amount then
        Notify.Send(Util.L('usage_givecash', Config.Commands.givecash), 'warning')
        return
    end

    if targetId == cache.serverId then
        Notify.Send(Util.L('givecash_self'), 'error')
        return
    end

    -- Check if target is nearby (optional proximity check for cash)
    local targetPed = GetPlayerPed(GetPlayerFromServerId(targetId))
    if not DoesEntityExist(targetPed) then
        Notify.Send(Util.L('player_not_found'), 'error')
        return
    end

    local playerCoords = GetEntityCoords(cache.ped)
    local targetCoords = GetEntityCoords(targetPed)
    if #(playerCoords - targetCoords) > 10.0 then
        Notify.Send('Player is too far away.', 'error')
        return
    end

    TriggerServerEvent('atmsystem:server:giveCash', targetId, amount)
end, false)

-- ── Cleanup on Resource Stop ──────────────────────────────────────────────────

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    -- Nothing to clean up on client side; server handles all state
end)