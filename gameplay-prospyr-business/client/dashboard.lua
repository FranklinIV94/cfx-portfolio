-- ═════════════════════════════════════════════════════════════════════
-- Prospyr Business Manager — Client Dashboard
-- Handles NUI open/close, data refresh, tab routing
-- ═════════════════════════════════════════════════════════════════════

local isOpen = false
local refreshThread = nil

-- Open dashboard
RegisterNetEvent('prospyr-business:client:openDashboard', function()
    if isOpen then return end
    isOpen = true
    SetNuiFocus(true, true)

    -- Send initial data
    SendNUIMessage({
        action = 'open',
        businesses = BusinessState.businesses,
        selectedBusiness = BusinessState.selectedBusiness,
        config = {
            businessTypes = Config.BusinessTypes,
            permissions = Config.Permissions,
            currency = Config.Finance.currencyFormat,
        },
    })

    -- Start auto-refresh
    if refreshThread then return end
    refreshThread = CreateThread(function()
        while isOpen do
            Wait(Config.UI.refreshInterval)
            if BusinessState.selectedBusiness then
                TriggerServerEvent('prospyr-business:server:getBusinessData', BusinessState.selectedBusiness)
            end
        end
    end)
end)

-- Close dashboard
RegisterNetEvent('prospyr-business:client:closeDashboard', function()
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    refreshThread = nil
end)

-- Receive updated business data from server
RegisterNetEvent('prospyr-business:client:updateBusinessData', function(data)
    if not isOpen then return end
    SendNUIMessage({
        action = 'updateData',
        business = data.business,
        employees = data.employees,
        transactions = data.transactions,
        balance = data.balance,
    })
end)

-- Receive updated business list
RegisterNetEvent('prospyr-business:client:updateBusinessList', function(businesses)
    BusinessState.businesses = businesses
    if isOpen then
        SendNUIMessage({
            action = 'updateBusinessList',
            businesses = businesses,
        })
    end
end)

-- Notification helper
RegisterNetEvent('prospyr-business:client:notify', function(message, type)
    if not type then type = 'info' end
    lib.notify({
        title = 'Business Manager',
        description = message,
        type = type,
        position = 'top-right',
        duration = 5000,
    })
end)

-- Admin panel open
RegisterNetEvent('prospyr-business:client:openAdmin', function()
    isOpen = true
    SetNuiFocus(true, true)
    TriggerServerEvent('prospyr-business:server:adminGetAll')
    SendNUIMessage({
        action = 'openAdmin',
        config = {
            businessTypes = Config.BusinessTypes,
            currency = Config.Finance.currencyFormat,
        },
    })
end)

-- Admin data received
RegisterNetEvent('prospyr-business:client:adminData', function(businesses)
    if not isOpen then return end
    SendNUIMessage({
        action = 'adminData',
        businesses = businesses,
    })
end)