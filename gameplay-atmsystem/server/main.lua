-- ═══════════════════════════════════════════════════════════════════════════════
-- ATM System — Server Main
-- server/main.lua
--
-- Coordinates player connection, event handling, commands, and admin tools.
-- ═══════════════════════════════════════════════════════════════════════════════

-- Transactions module is loaded via fxmanifest.lua as a server_script before this file.
-- transactions.lua sets the global `Transactions` table with:
--   Transactions.Withdraw(source, amount)     — process a withdrawal
--   Transactions.Deposit(source, amount)      — process a deposit
--   Transactions.Transfer(source, target, amt) — process a bank transfer
--   Transactions.GiveCash(source, target, amt)  — give cash in person
--   Transactions.CleanupPlayer(source)        — clean up on disconnect
-- The module pattern (return Transactions) also works with require().

-- ── Initialize Database on Resource Start ─────────────────────────────────────

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    Database.Init()
    print('[ATM System] Resource started — storage: ' .. Config.Storage)
end)

-- ── Player Connection Handler ──────────────────────────────────────────────────

AddEventHandler('playerJoining', function()
    local source = source
    -- Load player data (or create new account)
    local data = Database.LoadPlayer(source)
    if data then
        print(('[ATM System] Loaded account for %s (Bank: %s, Cash: %s)'):format(
            GetPlayerName(source),
            Util.FormatMoney(data.bank),
            Util.FormatMoney(data.cash)
        ))
    end
end)

-- Also handle players already on the server when resource starts
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    -- Load data for all currently connected players
    for _, playerId in ipairs(GetPlayers()) do
        local source = tonumber(playerId)
        if source then
            Database.LoadPlayer(source)
        end
    end
end)

-- ── Player Disconnect Handler ──────────────────────────────────────────────────

AddEventHandler('playerDropped', function()
    local source = source
    Transactions.CleanupPlayer(source)
    Database.RemovePlayer(source)
end)

-- ── Balance Check Event ────────────────────────────────────────────────────────

RegisterNetEvent('atmsystem:server:checkBalance', function()
    local source = source
    local data = Database.Get(source)
    if not data then
        -- Try loading
        data = Database.LoadPlayer(source)
    end
    if not data then return end

    TriggerClientEvent('atmsystem:client:showBalance', source, data.bank, data.cash, data.accountNumber)
end)

-- ── Withdraw Event ────────────────────────────────────────────────────────────

RegisterNetEvent('atmsystem:server:withdraw', function(amount)
    local source = source
    if type(amount) ~= 'number' or amount <= 0 then
        TriggerClientEvent('atmsystem:client:notify', source, Util.L('invalid_amount'), 'error')
        return
    end
    Transactions.Withdraw(source, amount)
end)

-- ── Deposit Event ──────────────────────────────────────────────────────────────

RegisterNetEvent('atmsystem:server:deposit', function(amount)
    local source = source
    if type(amount) ~= 'number' or amount <= 0 then
        TriggerClientEvent('atmsystem:client:notify', source, Util.L('invalid_amount'), 'error')
        return
    end
    Transactions.Deposit(source, amount)
end)

-- ── Transfer Event ──────────────────────────────────────────────────────────────

RegisterNetEvent('atmsystem:server:transfer', function(targetId, amount)
    local source = source
    if type(targetId) ~= 'number' or type(amount) ~= 'number' or amount <= 0 then
        TriggerClientEvent('atmsystem:client:notify', source, Util.L('invalid_amount'), 'error')
        return
    end
    Transactions.Transfer(source, targetId, amount)
end)

-- ── Give Cash Event ──────────────────────────────────────────────────────────────

RegisterNetEvent('atmsystem:server:giveCash', function(targetId, amount)
    local source = source
    if type(targetId) ~= 'number' or type(amount) ~= 'number' or amount <= 0 then
        TriggerClientEvent('atmsystem:client:notify', source, Util.L('invalid_amount'), 'error')
        return
    end
    Transactions.GiveCash(source, targetId, amount)
end)

-- ── Transaction History Event ──────────────────────────────────────────────────

RegisterNetEvent('atmsystem:server:getHistory', function()
    local source = source
    local data = Database.Get(source)
    if not data then return end

    TriggerClientEvent('atmsystem:client:showHistory', source, data.history or {})
end)

-- ── Admin: View Player Balance ─────────────────────────────────────────────────

RegisterCommand(Config.Commands.bank, function(source, args)
    local targetId = tonumber(args[1])
    if not targetId then
        Notify.Send(Util.L('usage_bank', Config.Commands.bank), 'warning')
        return
    end

    if not IsPlayerAceAllowed(source, Config.AdminPermission) then
        Notify.Send(Util.L('no_permission'), 'error')
        return
    end

    local data = Database.Get(targetId)
    if not data then
        Notify.Send(Util.L('player_not_found'), 'error')
        return
    end

    local name = GetPlayerName(targetId) or 'Unknown'
    Notify.Send(Util.L('admin_view', name, targetId, Util.FormatMoney(data.bank), Util.FormatMoney(data.cash)), 'info', 10000)
end, true)

-- ── Admin: Set Player Balance ──────────────────────────────────────────────────

RegisterCommand(Config.Commands.setmoney, function(source, args)
    local targetId = tonumber(args[1])
    local accountType = args[2]
    local amount = tonumber(args[3])

    if not targetId or not accountType or not amount then
        Notify.Send(Util.L('usage_setmoney', Config.Commands.setmoney), 'warning')
        return
    end

    if not IsPlayerAceAllowed(source, Config.AdminPermission) then
        Notify.Send(Util.L('no_permission'), 'error')
        return
    end

    if accountType ~= 'bank' and accountType ~= 'cash' then
        Notify.Send('Invalid account type. Use "bank" or "cash".', 'error')
        return
    end

    local data = Database.Get(targetId)
    if not data then
        Notify.Send(Util.L('player_not_found'), 'error')
        return
    end

    local success = Database.SetBalance(targetId, accountType, amount)
    if success then
        local name = GetPlayerName(targetId) or 'Unknown'
        Notify.Send(Util.L('admin_set', name, accountType, Util.FormatMoney(amount)), 'success')

        -- Notify the target player
        TriggerClientEvent('atmsystem:client:notify', targetId,
            string.format('Admin set your %s balance to %s', accountType, Util.FormatMoney(amount)), 'info')
    end
end, true)

-- ── Interest System ────────────────────────────────────────────────────────────

if Config.Interest.enabled then
    CreateThread(function()
        while true do
            Wait(Config.Interest.interval * 60000) -- Convert minutes to ms

            local allData = Database.GetAll()
            for source, data in pairs(allData) do
                if data.bank > 0 and data.bank <= Config.Interest.maxBalance then
                    local interest = math.floor(data.bank * (Config.Interest.rate / 100))
                    if interest > 0 then
                        data.bank = data.bank + interest
                        Database.SavePlayer(source)
                        Database.LogTransaction(source, 'interest', interest, data.bank)
                        TriggerClientEvent('atmsystem:client:notify', source,
                            Util.L('interest_paid', Util.FormatMoney(interest)), 'success')
                    end
                end
            end
        end
    end)
end

-- ── Auto-Save (JSON mode) ──────────────────────────────────────────────────────

if Config.Storage == 'json' then
    CreateThread(function()
        while true do
            Wait(300000) -- Save every 5 minutes
            local allData = Database.GetAll()
            for source, _ in pairs(allData) do
                Database.SavePlayer(source)
            end
        end
    end)
end

-- ── Exports ────────────────────────────────────────────────────────────────────

exports('getBalance', function(playerId)
    local data = Database.Get(playerId)
    if not data then return nil end
    return { bank = data.bank, cash = data.cash, accountNumber = data.accountNumber }
end)

exports('addMoney', function(playerId, accountType, amount)
    local data = Database.Get(playerId)
    if not data then return false end
    if accountType == 'bank' then
        data.bank = data.bank + amount
    elseif accountType == 'cash' then
        data.cash = data.cash + amount
    else
        return false
    end
    Database.SavePlayer(playerId)
    Database.LogTransaction(playerId, 'admin_add', amount, accountType == 'bank' and data.bank or data.cash)
    return true
end)

exports('removeMoney', function(playerId, accountType, amount)
    local data = Database.Get(playerId)
    if not data then return false end
    if accountType == 'bank' then
        if data.bank < amount then return false end
        data.bank = data.bank - amount
    elseif accountType == 'cash' then
        if data.cash < amount then return false end
        data.cash = data.cash - amount
    else
        return false
    end
    Database.SavePlayer(playerId)
    Database.LogTransaction(playerId, 'admin_remove', amount, accountType == 'bank' and data.bank or data.cash)
    return true
end)

exports('getHistory', function(playerId)
    local data = Database.Get(playerId)
    if not data then return {} end
    return data.history or {}
end)