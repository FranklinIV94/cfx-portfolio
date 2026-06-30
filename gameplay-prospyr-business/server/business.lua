-- ═════════════════════════════════════════════════════════════════════
-- Prospyr Business Manager — Server Business Logic
-- Create, delete, deposit, withdraw
-- ═════════════════════════════════════════════════════════════════════

local function getPlayerIdentifier(source)
    local identifiers = GetPlayerIdentifiers(source)
    for _, id in ipairs(identifiers) do
        if string.match(id, 'license:') then
            return string.gsub(id, 'license:', '')
        end
    end
    return identifiers[1] or tostring(source)
end

local function getPlayerName(source)
    return GetPlayerName(source) or 'Unknown'
end

-- ═════════════════════════════════════════════════════════════════════
-- Create Business
-- ═════════════════════════════════════════════════════════════════════

RegisterNetEvent('prospyr-business:server:createBusiness', function(data)
    local source = source
    local cid = getPlayerIdentifier(source)
    local name = getPlayerName(source)

    if not data.name or data.name == '' then
        TriggerClientEvent('prospyr-business:client:notify', source, 'Business name is required.', 'error')
        return
    end

    local bizConfig = Config.BusinessTypes[data.type]
    if not bizConfig then
        TriggerClientEvent('prospyr-business:client:notify', source, 'Invalid business type.', 'error')
        return
    end

    local id = MySQL.insert.await(
        'INSERT INTO prospyr_businesses (name, type, owner_cid, balance, blip_coords) VALUES (?, ?, ?, ?, ?)',
        { data.name, data.type, cid, bizConfig.defaultBalance, data.blipCoords or nil }
    )

    -- Add owner as first employee
    MySQL.insert.await(
        'INSERT INTO prospyr_employees (business_id, citizenid, player_name, role, salary) VALUES (?, ?, ?, ?, ?)',
        { id, cid, name, 'owner', Config.DefaultSalaries['owner'] or 500 }
    )

    -- Log transaction
    MySQL.insert.await(
        'INSERT INTO prospyr_transactions (business_id, type, amount, description, performed_by, performed_name) VALUES (?, ?, ?, ?, ?, ?)',
        { id, 'deposit', bizConfig.defaultBalance, 'Initial business balance', cid, name }
    )

    -- Fetch the created business
    local business = MySQL.single.await('SELECT * FROM prospyr_businesses WHERE id = ?', { id })

    TriggerClientEvent('prospyr-business:client:businessCreated', source, business)

    -- Refresh business list
    local businesses = MySQL.query.await('SELECT * FROM prospyr_businesses WHERE owner_cid = ?', { cid }) or {}
    TriggerClientEvent('prospyr-business:client:updateBusinessList', source, businesses)
    TriggerClientEvent('prospyr-business:client:updateBlips', source, businesses)
end)

-- ═════════════════════════════════════════════════════════════════════
-- Delete Business
-- ═════════════════════════════════════════════════════════════════════

RegisterNetEvent('prospyr-business:server:deleteBusiness', function(businessId)
    local source = source
    local cid = getPlayerIdentifier(source)

    local business = MySQL.single.await('SELECT * FROM prospyr_businesses WHERE id = ?', { businessId })
    if not business then return end

    if business.owner_cid ~= cid then
        TriggerClientEvent('prospyr-business:client:notify', source, 'Only the owner can delete this business.', 'error')
        return
    end

    MySQL.update.await('DELETE FROM prospyr_businesses WHERE id = ?', { businessId })

    TriggerClientEvent('prospyr-business:client:businessDeleted', source, businessId)

    local businesses = MySQL.query.await('SELECT * FROM prospyr_businesses WHERE owner_cid = ?', { cid }) or {}
    TriggerClientEvent('prospyr-business:client:updateBusinessList', source, businesses)
    TriggerClientEvent('prospyr-business:client:updateBlips', source, businesses)
end)

-- ═════════════════════════════════════════════════════════════════════
-- Deposit
-- ═════════════════════════════════════════════════════════════════════

RegisterNetEvent('prospyr-business:server:deposit', function(data)
    local source = source
    local cid = getPlayerIdentifier(source)
    local name = getPlayerName(source)
    local amount = tonumber(data.amount)
    local businessId = tonumber(data.businessId)

    if not amount or amount <= 0 then
        TriggerClientEvent('prospyr-business:client:notify', source, 'Invalid amount.', 'error')
        return
    end

    local business = MySQL.single.await('SELECT * FROM prospyr_businesses WHERE id = ?', { businessId })
    if not business then return end

    -- Check permissions
    local emp = MySQL.single.await(
        'SELECT * FROM prospyr_employees WHERE business_id = ? AND citizenid = ? AND active = 1',
        { businessId, cid }
    )

    local canDeposit = false
    if business.owner_cid == cid then
        canDeposit = true
    elseif emp and (Config.Permissions[emp.role] and Config.Permissions[emp.role].canDeposit) then
        canDeposit = true
    end

    if not canDeposit then
        TriggerClientEvent('prospyr-business:client:notify', source, 'You do not have permission to deposit.', 'error')
        return
    end

    MySQL.update.await(
        'UPDATE prospyr_businesses SET balance = balance + ?, revenue = revenue + ? WHERE id = ?',
        { amount, amount, businessId }
    )

    MySQL.insert.await(
        'INSERT INTO prospyr_transactions (business_id, type, amount, description, performed_by, performed_name) VALUES (?, ?, ?, ?, ?, ?)',
        { businessId, 'deposit', amount, data.description or 'Deposit', cid, name }
    )

    TriggerClientEvent('prospyr-business:client:notify', source,
        'Deposited ' .. Config.Finance.currencyFormat:format(amount) .. '.', 'success')
end)

-- ═════════════════════════════════════════════════════════════════════
-- Withdraw
-- ═════════════════════════════════════════════════════════════════════

RegisterNetEvent('prospyr-business:server:withdraw', function(data)
    local source = source
    local cid = getPlayerIdentifier(source)
    local name = getPlayerName(source)
    local amount = tonumber(data.amount)
    local businessId = tonumber(data.businessId)

    if not amount or amount <= 0 then
        TriggerClientEvent('prospyr-business:client:notify', source, 'Invalid amount.', 'error')
        return
    end

    local business = MySQL.single.await('SELECT * FROM prospyr_businesses WHERE id = ?', { businessId })
    if not business then return end

    -- Only owner can withdraw
    if business.owner_cid ~= cid then
        TriggerClientEvent('prospyr-business:client:notify', source, 'Only the owner can withdraw.', 'error')
        return
    end

    if tonumber(business.balance) < amount then
        TriggerClientEvent('prospyr-business:client:notify', source, 'Insufficient business funds.', 'error')
        return
    end

    MySQL.update.await(
        'UPDATE prospyr_businesses SET balance = balance - ?, expenses = expenses + ? WHERE id = ?',
        { amount, amount, businessId }
    )

    MySQL.insert.await(
        'INSERT INTO prospyr_transactions (business_id, type, amount, description, performed_by, performed_name) VALUES (?, ?, ?, ?, ?, ?)',
        { businessId, 'withdrawal', amount, data.description or 'Withdrawal', cid, name }
    )

    TriggerClientEvent('prospyr-business:client:notify', source,
        'Withdrew ' .. Config.Finance.currencyFormat:format(amount) .. '.', 'success')
end)

-- ═════════════════════════════════════════════════════════════════════
-- Get Transactions (paginated)
-- ═════════════════════════════════════════════════════════════════════

RegisterNetEvent('prospyr-business:server:getTransactions', function(businessId, page)
    local source = source
    local cid = getPlayerIdentifier(source)
    local offset = ((page or 1) - 1) * 25

    local business = MySQL.single.await('SELECT * FROM prospyr_businesses WHERE id = ?', { businessId })
    if not business then return end

    -- Verify access
    local hasAccess = business.owner_cid == cid
    if not hasAccess then
        local emp = MySQL.single.await(
            'SELECT * FROM prospyr_employees WHERE business_id = ? AND citizenid = ? AND active = 1',
            { businessId, cid }
        )
        hasAccess = emp ~= nil
    end

    if not hasAccess then return end

    local transactions = MySQL.query.await(
        'SELECT * FROM prospyr_transactions WHERE business_id = ? ORDER BY created_at DESC LIMIT 25 OFFSET ?',
        { businessId, offset }
    ) or {}

    local totalCount = MySQL.single.await(
        'SELECT COUNT(*) as count FROM prospyr_transactions WHERE business_id = ?',
        { businessId }
    )

    TriggerClientEvent('prospyr-business:client:updateBusinessData', source, {
        transactions = transactions,
        transactionTotal = totalCount and tonumber(totalCount.count) or 0,
    })
end)