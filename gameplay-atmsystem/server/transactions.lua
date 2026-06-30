-- ═══════════════════════════════════════════════════════════════════════════════
-- ATM System — Transaction Processor
-- server/transactions.lua
--
-- Core transaction logic: withdrawals, deposits, transfers, cash giving.
-- All money movement goes through this module for consistent validation.
-- ═══════════════════════════════════════════════════════════════════════════════

Transactions = {}

-- ── Cooldown & Rate Limit Tracking ─────────────────────────────────────────────

local lastInteraction = {}    -- [serverId] = timestamp
local transactionCount = {}    -- [serverId] = { count, windowStart }

--- Check cooldown and rate limits for a player.
--- @param source number Player server ID
--- @return boolean allowed, string|nil reason
local function CheckAntiAbuse(source)
    -- Cooldown check
    if Config.AntiAbuse.cooldown > 0 then
        local now = os.time()
        if lastInteraction[source] and (now - lastInteraction[source]) < Config.AntiAbuse.cooldown then
            return false, Util.L('cooldown')
        end
        lastInteraction[source] = now
    end

    -- Rate limit check (per minute)
    if Config.AntiAbuse.rateLimit > 0 then
        local now = os.time()
        if not transactionCount[source] or (now - transactionCount[source].windowStart) > 60 then
            transactionCount[source] = { count = 1, windowStart = now }
        else
            transactionCount[source].count = transactionCount[source].count + 1
            if transactionCount[source].count > Config.AntiAbuse.rateLimit then
                return false, Util.L('rate_limited')
            end
        end
    end

    return true
end

-- ── Withdraw ───────────────────────────────────────────────────────────────────

--- Process a withdrawal from the player's bank account.
--- @param source number Player server ID
--- @param amount number Amount to withdraw
function Transactions.Withdraw(source, amount)
    local allowed, reason = CheckAntiAbuse(source)
    if not allowed then
        TriggerClientEvent('atmsystem:client:notify', source, reason, 'error')
        return
    end

    -- Validate amount
    local valid, err = Util.ValidateAmount(amount)
    if not valid then
        TriggerClientEvent('atmsystem:client:notify', source, err, 'error')
        return
    end

    -- Check withdrawal limit
    if amount > Config.Transactions.maxWithdrawal then
        TriggerClientEvent('atmsystem:client:notify', source, Util.L('withdraw_limit', Util.FormatMoney(Config.Transactions.maxWithdrawal)), 'error')
        return
    end

    local data = Database.Get(source)
    if not data then return end

    -- Calculate fee
    local fee = 0
    if Config.ATMFee.enabled then
        fee = Config.ATMFee.amount
    end

    local totalDeduction = amount + fee

    -- Check balance (with overdraft if enabled)
    if not Config.Overdraft.enabled and data.bank < totalDeduction then
        TriggerClientEvent('atmsystem:client:notify', source, Util.L('withdraw_fail', Util.FormatMoney(data.bank)), 'error')
        return
    end

    if Config.Overdraft.enabled and (data.bank - totalDeduction) < Config.Overdraft.limit then
        TriggerClientEvent('atmsystem:client:notify', source, Util.L('overdraft_denied'), 'error')
        return
    end

    -- Process transaction
    data.bank = data.bank - totalDeduction
    data.cash = data.cash + amount

    Database.SavePlayer(source)
    Database.LogTransaction(source, 'withdrawal', amount, data.bank)

    local msg = Util.L('withdraw_success', Util.FormatMoney(amount), Util.FormatMoney(fee))
    if fee > 0 then
        msg = msg .. ' ' .. Util.L('fee_charged', Util.FormatMoney(fee))
    end
    TriggerClientEvent('atmsystem:client:notify', source, msg, 'success')
end

-- ── Deposit ───────────────────────────────────────────────────────────────────

--- Process a cash deposit into the player's bank account.
--- @param source number Player server ID
--- @param amount number Amount to deposit
function Transactions.Deposit(source, amount)
    local allowed, reason = CheckAntiAbuse(source)
    if not allowed then
        TriggerClientEvent('atmsystem:client:notify', source, reason, 'error')
        return
    end

    local valid, err = Util.ValidateAmount(amount)
    if not valid then
        TriggerClientEvent('atmsystem:client:notify', source, err, 'error')
        return
    end

    if amount > Config.Transactions.maxDeposit then
        TriggerClientEvent('atmsystem:client:notify', source, Util.L('deposit_limit', Util.FormatMoney(Config.Transactions.maxDeposit)), 'error')
        return
    end

    local data = Database.Get(source)
    if not data then return end

    -- Check cash
    if data.cash < amount then
        TriggerClientEvent('atmsystem:client:notify', source, Util.L('deposit_fail', Util.FormatMoney(data.cash)), 'error')
        return
    end

    -- Process
    data.cash = data.cash - amount
    data.bank = data.bank + amount

    Database.SavePlayer(source)
    Database.LogTransaction(source, 'deposit', amount, data.bank)

    TriggerClientEvent('atmsystem:client:notify', source, Util.L('deposit_success', Util.FormatMoney(amount)), 'success')
end

-- ── Transfer (Bank to Bank) ────────────────────────────────────────────────────

--- Process a bank-to-bank transfer between two players.
--- @param source number Sender server ID
--- @param targetId number Recipient server ID
--- @param amount number Amount to transfer
function Transactions.Transfer(source, targetId, amount)
    local allowed, reason = CheckAntiAbuse(source)
    if not allowed then
        TriggerClientEvent('atmsystem:client:notify', source, reason, 'error')
        return
    end

    -- Validate target
    if targetId == source then
        TriggerClientEvent('atmsystem:client:notify', source, Util.L('transfer_self'), 'error')
        return
    end

    local targetPed = GetPlayer(targetId)
    if not targetPed then
        TriggerClientEvent('atmsystem:client:notify', source, Util.L('transfer_invalid'), 'error')
        return
    end

    local valid, err = Util.ValidateAmount(amount)
    if not valid then
        TriggerClientEvent('atmsystem:client:notify', source, err, 'error')
        return
    end

    local senderData = Database.Get(source)
    local targetData = Database.Get(targetId)
    if not senderData or not targetData then
        TriggerClientEvent('atmsystem:client:notify', source, Util.L('transfer_invalid'), 'error')
        return
    end

    -- Calculate fee
    local fee = Util.CalculateTransferFee(amount)
    local totalDeduction = amount + fee

    -- Check sender balance
    if not Config.Overdraft.enabled and senderData.bank < totalDeduction then
        TriggerClientEvent('atmsystem:client:notify', source, Util.L('transfer_fail'), 'error')
        return
    end

    -- Process transfer
    senderData.bank = senderData.bank - totalDeduction
    targetData.bank = targetData.bank + amount

    Database.SavePlayer(source)
    Database.SavePlayer(targetId)

    Database.LogTransaction(source, 'transfer_out', amount, senderData.bank, targetData.identifier)
    Database.LogTransaction(targetId, 'transfer_in', amount, targetData.bank, senderData.identifier)

    -- Notify both parties
    TriggerClientEvent('atmsystem:client:notify', source, Util.L('transfer_success', Util.FormatMoney(amount), GetPlayerName(targetId), Util.FormatMoney(fee)), 'success')
    TriggerClientEvent('atmsystem:client:notify', targetId, string.format('Received %s from %s', Util.FormatMoney(amount), GetPlayerName(source)), 'success')
end

-- ── Give Cash (In-Person) ─────────────────────────────────────────────────────

--- Process giving cash to another player (in-person, no bank involved).
--- @param source number Sender server ID
--- @param targetId number Recipient server ID
--- @param amount number Amount to give
function Transactions.GiveCash(source, targetId, amount)
    local allowed, reason = CheckAntiAbuse(source)
    if not allowed then
        TriggerClientEvent('atmsystem:client:notify', source, reason, 'error')
        return
    end

    if targetId == source then
        TriggerClientEvent('atmsystem:client:notify', source, Util.L('givecash_self'), 'error')
        return
    end

    local targetPed = GetPlayer(targetId)
    if not targetPed then
        TriggerClientEvent('atmsystem:client:notify', source, Util.L('player_not_found'), 'error')
        return
    end

    local valid, err = Util.ValidateAmount(amount)
    if not valid then
        TriggerClientEvent('atmsystem:client:notify', source, err, 'error')
        return
    end

    local senderData = Database.Get(source)
    local targetData = Database.Get(targetId)
    if not senderData or not targetData then
        TriggerClientEvent('atmsystem:client:notify', source, Util.L('player_not_found'), 'error')
        return
    end

    -- Check cash
    if senderData.cash < amount then
        TriggerClientEvent('atmsystem:client:notify', source, Util.L('givecash_fail', Util.FormatMoney(senderData.cash)), 'error')
        return
    end

    -- Process
    senderData.cash = senderData.cash - amount
    targetData.cash = targetData.cash + amount

    Database.SavePlayer(source)
    Database.SavePlayer(targetId)

    Database.LogTransaction(source, 'give_cash', amount, senderData.cash, targetData.identifier)
    Database.LogTransaction(targetId, 'receive_cash', amount, targetData.cash, senderData.identifier)

    TriggerClientEvent('atmsystem:client:notify', source, Util.L('givecash_success', Util.FormatMoney(amount), GetPlayerName(targetId)), 'success')
    TriggerClientEvent('atmsystem:client:notify', targetId, string.format('Received %s cash from %s', Util.FormatMoney(amount), GetPlayerName(source)), 'success')
end

-- ── Cleanup ────────────────────────────────────────────────────────────────────

function Transactions.CleanupPlayer(source)
    lastInteraction[source] = nil
    transactionCount[source] = nil
end

return Transactions