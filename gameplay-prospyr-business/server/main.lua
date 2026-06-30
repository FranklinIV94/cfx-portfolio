-- ═════════════════════════════════════════════════════════════════════
-- Prospyr Business Manager — Server Main
-- Player identification, init, payroll loop
-- ═════════════════════════════════════════════════════════════════════

local function getPlayerIdentifier(source)
    -- Works with most frameworks — tries citizenid (qb), identifier (ESX), license
    local identifiers = GetPlayerIdentifiers(source)
    for _, id in ipairs(identifiers) do
        if string.match(id, 'license:') then
            return string.gsub(id, 'license:', '')
        end
    end
    -- Fallback: use first available identifier
    return identifiers[1] or tostring(source)
end

local function getPlayerName(source)
    return GetPlayerName(source) or 'Unknown'
end

-- Send initial player data on join
RegisterNetEvent('prospyr-business:server:init', function()
    local source = source
    local cid = getPlayerIdentifier(source)
    local name = getPlayerName(source)

    -- Fetch businesses owned by or employing this player
    local businesses = MySQL.query.await(
        'SELECT * FROM prospyr_businesses WHERE owner_cid = ? ORDER BY created_at DESC',
        { cid }
    )

    if not businesses then businesses = {} end

    -- Also check if they're an employee at any business
    local employedAt = MySQL.query.await(
        [[SELECT b.* FROM prospyr_businesses b
          INNER JOIN prospyr_employees e ON e.business_id = b.id
          WHERE e.citizenid = ? AND e.active = 1]],
        { cid }
    )

    if employedAt then
        for _, biz in ipairs(employedAt) do
            -- Avoid duplicates
            local found = false
            for _, owned in ipairs(businesses) do
                if owned.id == biz.id then found = true break end
            end
            if not found then
                table.insert(businesses, biz)
            end
        end
    end

    TriggerClientEvent('prospyr-business:client:setPlayerData', source, {
        citizenid = cid,
        name = name,
        businesses = businesses,
    })

    -- Send blips
    TriggerClientEvent('prospyr-business:client:updateBlips', source, businesses)
end)

-- ═════════════════════════════════════════════════════════════════════
-- Get Business Data (for dashboard)
-- ═════════════════════════════════════════════════════════════════════

RegisterNetEvent('prospyr-business:server:getBusinessData', function(businessId)
    local source = source
    local cid = getPlayerIdentifier(source)

    local business = MySQL.single.await(
        'SELECT * FROM prospyr_businesses WHERE id = ?',
        { businessId }
    )

    if not business then
        TriggerClientEvent('prospyr-business:client:notify', source, 'Business not found.', 'error')
        return
    end

    -- Verify access (owner or employee)
    local hasAccess = false
    if business.owner_cid == cid then
        hasAccess = true
    else
        local emp = MySQL.single.await(
            'SELECT * FROM prospyr_employees WHERE business_id = ? AND citizenid = ? AND active = 1',
            { businessId, cid }
        )
        hasAccess = emp ~= nil
    end

    if not hasAccess then
        TriggerClientEvent('prospyr-business:client:notify', source, 'You do not have access to this business.', 'error')
        return
    end

    local employees = MySQL.query.await(
        'SELECT * FROM prospyr_employees WHERE business_id = ? AND active = 1 ORDER BY hired_at DESC',
        { businessId }
    ) or {}

    local transactions = MySQL.query.await(
        'SELECT * FROM prospyr_transactions WHERE business_id = ? ORDER BY created_at DESC LIMIT 50',
        { businessId }
    ) or {}

    TriggerClientEvent('prospyr-business:client:updateBusinessData', source, {
        business = business,
        employees = employees,
        transactions = transactions,
        balance = tonumber(business.balance),
    })
end)

-- ═════════════════════════════════════════════════════════════════════
-- Payroll Loop
-- ═════════════════════════════════════════════════════════════════════

if Config.Payroll.enabled then
    CreateThread(function()
        while true do
            Wait(Config.Payroll.interval * 60 * 1000)

            local businesses = MySQL.query.await('SELECT * FROM prospyr_businesses', {})
            if not businesses then goto continue end

            for _, biz in ipairs(businesses) do
                if tonumber(biz.balance) >= Config.Payroll.minBalance then
                    local employees = MySQL.query.await(
                        'SELECT * FROM prospyr_employees WHERE business_id = ? AND active = 1',
                        { biz.id }
                    )

                    if not employees then goto next_biz end

                    local totalPayroll = 0
                    for _, emp in ipairs(employees) do
                        totalPayroll = totalPayroll + tonumber(emp.salary)
                    end

                    local tax = totalPayroll * Config.Payroll.taxRate
                    local totalWithTax = totalPayroll + tax

                    if tonumber(biz.balance) >= totalWithTax then
                        -- Process payroll
                        MySQL.update.await(
                            'UPDATE prospyr_businesses SET balance = balance - ?, expenses = expenses + ? WHERE id = ?',
                            { totalWithTax, totalWithTax, biz.id }
                        )

                        -- Log transaction
                        MySQL.insert.await(
                            'INSERT INTO prospyr_transactions (business_id, type, amount, description, performed_by, performed_name) VALUES (?, ?, ?, ?, ?, ?)',
                            { biz.id, 'payroll', totalWithTax, 'Payroll cycle', 'system', 'Payroll System' }
                        )

                        -- Pay each employee
                        for _, emp in ipairs(employees) do
                            local player = GetPlayers()
                            for _, pid in ipairs(player) do
                                if getPlayerIdentifier(pid) == emp.citizenid then
                                    TriggerClientEvent('prospyr-business:client:payrollProcessed', pid, biz.name, tonumber(emp.salary))
                                    break
                                end
                            end
                        end
                    else
                        -- Insufficient funds — notify online owner
                        local player = GetPlayers()
                        for _, pid in ipairs(player) do
                            if getPlayerIdentifier(pid) == biz.owner_cid then
                                TriggerClientEvent('prospyr-business:client:payrollFailed', pid, biz.name)
                                break
                            end
                        end
                    end

                    ::next_biz::
                end
            end

            ::continue::
        end
    end)
end

-- Export helper for other resources
exports('GetBusinesses', function(cid)
    return MySQL.query.await('SELECT * FROM prospyr_businesses WHERE owner_cid = ?', { cid }) or {}
end)

exports('CreateBusiness', function(name, bizType, ownerCid, balance)
    local bizConfig = Config.BusinessTypes[bizType] or Config.BusinessTypes['general']
    local startingBalance = balance or bizConfig.defaultBalance
    local id = MySQL.insert.await(
        'INSERT INTO prospyr_businesses (name, type, owner_cid, balance) VALUES (?, ?, ?, ?)',
        { name, bizType, ownerCid, startingBalance }
    )
    return id
end)

exports('GetEmployees', function(businessId)
    return MySQL.query.await(
        'SELECT * FROM prospyr_employees WHERE business_id = ? AND active = 1',
        { businessId }
    ) or {}
end)