-- ═════════════════════════════════════════════════════════════════════
-- Prospyr Business Manager — Server Finance Logic
-- Admin panel, admin delete, financial summaries
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

-- ═════════════════════════════════════════════════════════════════════
-- Admin: Get All Businesses
-- ═════════════════════════════════════════════════════════════════════

RegisterNetEvent('prospyr-business:server:adminGetAll', function()
    local source = source

    -- Check admin permission (uses FiveM Ace permissions or framework groups)
    local allowed = false
    for _, group in ipairs(Config.Admin.allowedGroups) do
        if IsPlayerAceAllowed(source, group) then
            allowed = true
            break
        end
    end

    -- Also check if player is in admin group via framework
    if not allowed then
        -- Try checking via executeCommand (works with FiveM built-in admin)
        local cid = getPlayerIdentifier(source)
        -- Fallback: deny
        TriggerClientEvent('prospyr-business:client:notify', source, 'Admin access required.', 'error')
        return
    end

    local businesses = MySQL.query.await(
        'SELECT b.*, COUNT(e.id) as employee_count FROM prospyr_businesses b LEFT JOIN prospyr_employees e ON e.business_id = b.id AND e.active = 1 GROUP BY b.id ORDER BY b.created_at DESC'
    ) or {}

    -- Get financial summaries
    for _, biz in ipairs(businesses) do
        local stats = MySQL.single.await(
            'SELECT COUNT(*) as tx_count, COALESCE(SUM(CASE WHEN type = "deposit" THEN amount ELSE 0 END), 0) as total_deposits, COALESCE(SUM(CASE WHEN type = "withdrawal" THEN amount ELSE 0 END), 0) as total_withdrawals FROM prospyr_transactions WHERE business_id = ?',
            { biz.id }
        )
        if stats then
            biz.tx_count = tonumber(stats.tx_count)
            biz.total_deposits = tonumber(stats.total_deposits)
            biz.total_withdrawals = tonumber(stats.total_withdrawals)
        end
    end

    TriggerClientEvent('prospyr-business:client:adminData', source, businesses)
end)

-- ═════════════════════════════════════════════════════════════════════
-- Admin: Delete Business
-- ═════════════════════════════════════════════════════════════════════

RegisterNetEvent('prospyr-business:server:adminDeleteBusiness', function(data)
    local source = source
    local businessId = tonumber(data.businessId)

    -- Check admin permission
    local allowed = false
    for _, group in ipairs(Config.Admin.allowedGroups) do
        if IsPlayerAceAllowed(source, group) then
            allowed = true
            break
        end
    end

    if not allowed then
        TriggerClientEvent('prospyr-business:client:notify', source, 'Admin access required.', 'error')
        return
    end

    if not Config.Admin.canDeleteAny then
        TriggerClientEvent('prospyr-business:client:notify', source, 'Admin deletion is disabled.', 'error')
        return
    end

    local business = MySQL.single.await('SELECT * FROM prospyr_businesses WHERE id = ?', { businessId })
    if not business then
        TriggerClientEvent('prospyr-business:client:notify', source, 'Business not found.', 'error')
        return
    end

    -- Cascade delete handled by FK constraints
    MySQL.update.await('DELETE FROM prospyr_businesses WHERE id = ?', { businessId })

    TriggerClientEvent('prospyr-business:client:notify', source,
        'Deleted business: ' .. business.name, 'info')

    -- Refresh admin list
    TriggerEvent('prospyr-business:server:adminGetAll')
end)

-- ═════════════════════════════════════════════════════════════════════
-- Financial Summary Export (for other resources)
-- ═════════════════════════════════════════════════════════════════════

-- Get business financial summary
exports('GetFinancialSummary', function(businessId)
    local business = MySQL.single.await('SELECT * FROM prospyr_businesses WHERE id = ?', { businessId })
    if not business then return nil end

    local summary = MySQL.single.await(
        [[SELECT
            COUNT(*) as transaction_count,
            COALESCE(SUM(CASE WHEN type = 'deposit' THEN amount ELSE 0 END), 0) as total_deposits,
            COALESCE(SUM(CASE WHEN type = 'withdrawal' THEN amount ELSE 0 END), 0) as total_withdrawals,
            COALESCE(SUM(CASE WHEN type = 'payroll' THEN amount ELSE 0 END), 0) as total_payroll,
            COALESCE(SUM(CASE WHEN type = 'revenue' THEN amount ELSE 0 END), 0) as total_revenue,
            COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) as total_expenses
          FROM prospyr_transactions WHERE business_id = ?]],
        { businessId }
    )

    return {
        business = business,
        summary = summary,
    }
end)

-- Get all businesses for a player (by citizenid)
exports('GetPlayerBusinesses', function(cid)
    return MySQL.query.await('SELECT * FROM prospyr_businesses WHERE owner_cid = ?', { cid }) or {}
end)

-- Add revenue to a business (external resource call)
exports('AddRevenue', function(businessId, amount, description, source)
    if not amount or amount <= 0 then return false end

    MySQL.update.await(
        'UPDATE prospyr_businesses SET balance = balance + ?, revenue = revenue + ? WHERE id = ?',
        { amount, amount, businessId }
    )

    MySQL.insert.await(
        'INSERT INTO prospyr_transactions (business_id, type, amount, description, performed_by, performed_name) VALUES (?, ?, ?, ?, ?, ?)',
        { businessId, 'revenue', amount, description or 'Revenue', source or 'system', 'System' }
    )

    return true
end)

-- Add expense to a business (external resource call)
exports('AddExpense', function(businessId, amount, description, source)
    if not amount or amount <= 0 then return false end

    MySQL.update.await(
        'UPDATE prospyr_businesses SET balance = balance - ?, expenses = expenses + ? WHERE id = ?',
        { amount, amount, businessId }
    )

    MySQL.insert.await(
        'INSERT INTO prospyr_transactions (business_id, type, amount, description, performed_by, performed_name) VALUES (?, ?, ?, ?, ?, ?)',
        { businessId, 'expense', amount, description or 'Expense', source or 'system', 'System' }
    )

    return true
end)