-- ═════════════════════════════════════════════════════════════════════
-- Prospyr Business Manager — Server Employee Logic
-- Hire, fire, role update, salary update
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
-- Hire Employee
-- ═════════════════════════════════════════════════════════════════════

RegisterNetEvent('prospyr-business:server:hireEmployee', function(data)
    local source = source
    local cid = getPlayerIdentifier(source)
    local name = getPlayerName(source)
    local businessId = tonumber(data.businessId)
    local targetCid = data.citizenid
    local targetName = data.playerName or 'Unknown'
    local role = data.role or 'employee'
    local salary = tonumber(data.salary) or Config.DefaultSalaries[role] or 100

    -- Verify caller is owner or manager
    local business = MySQL.single.await('SELECT * FROM prospyr_businesses WHERE id = ?', { businessId })
    if not business then return end

    local emp = MySQL.single.await(
        'SELECT * FROM prospyr_employees WHERE business_id = ? AND citizenid = ? AND active = 1',
        { businessId, cid }
    )

    local canHire = false
    if business.owner_cid == cid then
        canHire = true
    elseif emp and Config.Permissions[emp.role] and Config.Permissions[emp.role].canManageEmployees then
        canHire = true
    end

    if not canHire then
        TriggerClientEvent('prospyr-business:client:notify', source, 'You do not have permission to hire.', 'error')
        return
    end

    -- Check if already employed
    local existing = MySQL.single.await(
        'SELECT * FROM prospyr_employees WHERE business_id = ? AND citizenid = ? AND active = 1',
        { businessId, targetCid }
    )

    if existing then
        TriggerClientEvent('prospyr-business:client:notify', source, 'This person is already employed here.', 'error')
        return
    end

    MySQL.insert.await(
        'INSERT INTO prospyr_employees (business_id, citizenid, player_name, role, salary) VALUES (?, ?, ?, ?, ?)',
        { businessId, targetCid, targetName, role, salary }
    )

    -- Log
    MySQL.insert.await(
        'INSERT INTO prospyr_transactions (business_id, type, amount, description, performed_by, performed_name) VALUES (?, ?, ?, ?, ?, ?)',
        { businessId, 'expense', 0, 'Hired ' .. targetName .. ' as ' .. role, cid, name }
    )

    -- Notify caller
    TriggerClientEvent('prospyr-business:client:employeeHired', source, business.name, targetName)

    -- Notify target if online
    local players = GetPlayers()
    for _, pid in ipairs(players) do
        if getPlayerIdentifier(pid) == targetCid then
            TriggerClientEvent('prospyr-business:client:youWereHired', pid, business.name, role, salary)
            break
        end
    end

    -- Refresh employees
    local employees = MySQL.query.await(
        'SELECT * FROM prospyr_employees WHERE business_id = ? AND active = 1 ORDER BY hired_at DESC',
        { businessId }
    ) or {}
    TriggerClientEvent('prospyr-business:client:setEmployees', source, businessId, employees)
end)

-- ═════════════════════════════════════════════════════════════════════
-- Fire Employee
-- ═════════════════════════════════════════════════════════════════════

RegisterNetEvent('prospyr-business:server:fireEmployee', function(data)
    local source = source
    local cid = getPlayerIdentifier(source)
    local name = getPlayerName(source)
    local businessId = tonumber(data.businessId)
    local empId = tonumber(data.employeeId)

    local business = MySQL.single.await('SELECT * FROM prospyr_businesses WHERE id = ?', { businessId })
    if not business then return end

    -- Check permissions
    local emp = MySQL.single.await(
        'SELECT * FROM prospyr_employees WHERE business_id = ? AND citizenid = ? AND active = 1',
        { businessId, cid }
    )

    local canFire = false
    if business.owner_cid == cid then
        canFire = true
    elseif emp and Config.Permissions[emp.role] and Config.Permissions[emp.role].canManageEmployees then
        canFire = true
    end

    if not canFire then
        TriggerClientEvent('prospyr-business:client:notify', source, 'You do not have permission to fire employees.', 'error')
        return
    end

    -- Can't fire the owner
    local targetEmp = MySQL.single.await('SELECT * FROM prospyr_employees WHERE id = ? AND business_id = ?', { empId, businessId })
    if not targetEmp then return end

    if targetEmp.role == 'owner' then
        TriggerClientEvent('prospyr-business:client:notify', source, 'Cannot fire the business owner.', 'error')
        return
    end

    MySQL.update.await(
        'UPDATE prospyr_employees SET active = 0 WHERE id = ?',
        { empId }
    )

    -- Log
    MySQL.insert.await(
        'INSERT INTO prospyr_transactions (business_id, type, amount, description, performed_by, performed_name) VALUES (?, ?, ?, ?, ?, ?)',
        { businessId, 'expense', 0, 'Fired ' .. targetEmp.player_name, cid, name }
    )

    TriggerClientEvent('prospyr-business:client:employeeFired', source, business.name, targetEmp.player_name)

    -- Notify target if online
    local players = GetPlayers()
    for _, pid in ipairs(players) do
        if getPlayerIdentifier(pid) == targetEmp.citizenid then
            TriggerClientEvent('prospyr-business:client:youWereFired', pid, business.name)
            break
        end
    end

    -- Refresh employees
    local employees = MySQL.query.await(
        'SELECT * FROM prospyr_employees WHERE business_id = ? AND active = 1 ORDER BY hired_at DESC',
        { businessId }
    ) or {}
    TriggerClientEvent('prospyr-business:client:setEmployees', source, businessId, employees)
end)

-- ═════════════════════════════════════════════════════════════════════
-- Update Role
-- ═════════════════════════════════════════════════════════════════════

RegisterNetEvent('prospyr-business:server:updateRole', function(data)
    local source = source
    local cid = getPlayerIdentifier(source)
    local businessId = tonumber(data.businessId)
    local empId = tonumber(data.employeeId)
    local newRole = data.role

    local business = MySQL.single.await('SELECT * FROM prospyr_businesses WHERE id = ?', { businessId })
    if not business then return end

    -- Only owner can change roles
    if business.owner_cid ~= cid then
        TriggerClientEvent('prospyr-business:client:notify', source, 'Only the owner can change roles.', 'error')
        return
    end

    local targetEmp = MySQL.single.await('SELECT * FROM prospyr_employees WHERE id = ? AND business_id = ?', { empId, businessId })
    if not targetEmp then return end

    if targetEmp.role == 'owner' then
        TriggerClientEvent('prospyr-business:client:notify', source, 'Cannot change the owner\'s role.', 'error')
        return
    end

    -- Update salary to match role default if not custom
    local newSalary = Config.DefaultSalaries[newRole] or tonumber(targetEmp.salary)

    MySQL.update.await(
        'UPDATE prospyr_employees SET role = ?, salary = ? WHERE id = ?',
        { newRole, newSalary, empId }
    )

    TriggerClientEvent('prospyr-business:client:roleUpdated', source, targetEmp.player_name, newRole)

    -- Notify target if online
    local players = GetPlayers()
    for _, pid in ipairs(players) do
        if getPlayerIdentifier(pid) == targetEmp.citizenid then
            TriggerClientEvent('prospyr-business:client:notify', pid,
                'Your role at ' .. business.name .. ' changed to ' .. newRole .. '.', 'info')
            break
        end
    end

    -- Refresh employees
    local employees = MySQL.query.await(
        'SELECT * FROM prospyr_employees WHERE business_id = ? AND active = 1 ORDER BY hired_at DESC',
        { businessId }
    ) or {}
    TriggerClientEvent('prospyr-business:client:setEmployees', source, businessId, employees)
end)

-- ═════════════════════════════════════════════════════════════════════
-- Update Salary
-- ═════════════════════════════════════════════════════════════════════

RegisterNetEvent('prospyr-business:server:updateSalary', function(data)
    local source = source
    local cid = getPlayerIdentifier(source)
    local businessId = tonumber(data.businessId)
    local empId = tonumber(data.employeeId)
    local newSalary = tonumber(data.salary)

    if not newSalary or newSalary < 0 then
        TriggerClientEvent('prospyr-business:client:notify', source, 'Invalid salary amount.', 'error')
        return
    end

    local business = MySQL.single.await('SELECT * FROM prospyr_businesses WHERE id = ?', { businessId })
    if not business then return end

    -- Only owner can change salary
    if business.owner_cid ~= cid then
        TriggerClientEvent('prospyr-business:client:notify', source, 'Only the owner can change salaries.', 'error')
        return
    end

    local targetEmp = MySQL.single.await('SELECT * FROM prospyr_employees WHERE id = ? AND business_id = ?', { empId, businessId })
    if not targetEmp then return end

    if targetEmp.role == 'owner' then
        TriggerClientEvent('prospyr-business:client:notify', source, 'Cannot change the owner\'s salary this way.', 'error')
        return
    end

    MySQL.update.await(
        'UPDATE prospyr_employees SET salary = ? WHERE id = ?',
        { newSalary, empId }
    )

    TriggerClientEvent('prospyr-business:client:salaryUpdated', source, targetEmp.player_name, newSalary)

    -- Refresh employees
    local employees = MySQL.query.await(
        'SELECT * FROM prospyr_employees WHERE business_id = ? AND active = 1 ORDER BY hired_at DESC',
        { businessId }
    ) or {}
    TriggerClientEvent('prospyr-business:client:setEmployees', source, businessId, employees)
end)