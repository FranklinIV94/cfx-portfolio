-- ═════════════════════════════════════════════════════════════════════
-- Prospyr Business Manager — Client Employee Logic
-- Employee list rendering, hire/fire UI interactions
-- ═════════════════════════════════════════════════════════════════════

-- Employee data received from server
RegisterNetEvent('prospyr-business:client:setEmployees', function(businessId, employees)
    if BusinessState.selectedBusiness == businessId then
        SendNUIMessage({
            action = 'updateEmployees',
            employees = employees,
        })
    end
end)

-- Hire employee flow — opens NUI search
RegisterNetEvent('prospyr-business:client:openHireDialog', function(businessId)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'showHireDialog',
        businessId = businessId,
        roles = Config.BusinessTypes['general'].roles, -- will be refined by server
    })
end)

-- Employee hired notification
RegisterNetEvent('prospyr-business:client:employeeHired', function(businessName, employeeName)
    TriggerEvent('prospyr-business:client:notify',
        employeeName .. ' has been hired at ' .. businessName .. '.', 'success')
end)

-- Employee fired notification
RegisterNetEvent('prospyr-business:client:employeeFired', function(businessName, employeeName)
    TriggerEvent('prospyr-business:client:notify',
        employeeName .. ' has been fired from ' .. businessName .. '.', 'info')
end)

-- Role updated notification
RegisterNetEvent('prospyr-business:client:roleUpdated', function(employeeName, newRole)
    TriggerEvent('prospyr-business:client:notify',
        employeeName .. "'s role updated to " .. newRole .. '.', 'success')
end)

-- Salary updated notification
RegisterNetEvent('prospyr-business:client:salaryUpdated', function(employeeName, newSalary)
    TriggerEvent('prospyr-business:client:notify',
        employeeName .. "'s salary updated to " .. Config.Finance.currencyFormat:format(newSalary) .. '.', 'success')
end)

-- You were hired (notification to the hired player)
RegisterNetEvent('prospyr-business:client:youWereHired', function(businessName, role, salary)
    lib.notify({
        title = 'Hired!',
        description = 'You\'ve been hired at ' .. businessName .. ' as ' .. role .. '. Salary: ' .. Config.Finance.currencyFormat:format(salary),
        type = 'success',
        duration = 8000,
    })
end)

-- You were fired
RegisterNetEvent('prospyr-business:client:youWereFired', function(businessName)
    lib.notify({
        title = 'Terminated',
        description = 'You\'ve been let go from ' .. businessName .. '.',
        type = 'error',
        duration = 8000,
    })
end)

-- Payroll processed notification
RegisterNetEvent('prospyr-business:client:payrollProcessed', function(businessName, amount)
    lib.notify({
        title = 'Payroll',
        description = 'Payroll processed at ' .. businessName .. '. You received ' .. Config.Finance.currencyFormat:format(amount),
        type = 'success',
        duration = 6000,
    })
end)

-- Payroll failed (insufficient funds)
RegisterNetEvent('prospyr-business:client:payrollFailed', function(businessName)
    lib.notify({
        title = 'Payroll Failed',
        description = businessName .. ' has insufficient funds for payroll.',
        type = 'error',
        duration = 6000,
    })
end)