-- ═════════════════════════════════════════════════════════════════════
-- Prospyr Business Manager — Client Main
-- Entry point: commands, keybinds, NUI callbacks, initialization
-- ═════════════════════════════════════════════════════════════════════

local PlayerData = {
    citizenid = nil,
    name = nil,
    businesses = {},
    selectedBusiness = nil,
}

-- ═════════════════════════════════════════════════════════════════════
-- Initialization
-- ═════════════════════════════════════════════════════════════════════

CreateThread(function()
    while not GetResourceState('ox_lib') == 'started' do Wait(100) end
    TriggerServerEvent('prospyr-business:server:init')
end)

-- Receive initial player data from server
RegisterNetEvent('prospyr-business:client:setPlayerData', function(data)
    PlayerData.citizenid = data.citizenid
    PlayerData.name = data.name
    PlayerData.businesses = data.businesses or {}
    TriggerEvent('prospyr-business:client:ready')
end)

-- ═════════════════════════════════════════════════════════════════════
-- Commands & Keybinds
-- ═════════════════════════════════════════════════════════════════════

RegisterCommand(Config.UI.command, function()
    TriggerEvent('prospyr-business:client:openDashboard')
end, false)

RegisterKeyMapping(Config.UI.command, 'Open Business Dashboard', 'keyboard', Config.UI.keybind)

-- Admin command
RegisterCommand('businessadmin', function()
    TriggerEvent('prospyr-business:client:openAdmin')
end, false)

-- ═════════════════════════════════════════════════════════════════════
-- NUI Callbacks
-- ═════════════════════════════════════════════════════════════════════

RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    cb({ ok = true })
end)

RegisterNUICallback('getBusinesses', function(_, cb)
    cb({ businesses = PlayerData.businesses })
end)

RegisterNUICallback('selectBusiness', function(data, cb)
    local id = tonumber(data.businessId)
    PlayerData.selectedBusiness = id
    TriggerServerEvent('prospyr-business:server:getBusinessData', id)
    cb({ ok = true })
end)

RegisterNUICallback('createBusiness', function(data, cb)
    TriggerServerEvent('prospyr-business:server:createBusiness', data)
    cb({ ok = true })
end)

RegisterNUICallback('hireEmployee', function(data, cb)
    TriggerServerEvent('prospyr-business:server:hireEmployee', data)
    cb({ ok = true })
end)

RegisterNUICallback('fireEmployee', function(data, cb)
    TriggerServerEvent('prospyr-business:server:fireEmployee', data)
    cb({ ok = true })
end)

RegisterNUICallback('updateRole', function(data, cb)
    TriggerServerEvent('prospyr-business:server:updateRole', data)
    cb({ ok = true })
end)

RegisterNUICallback('updateSalary', function(data, cb)
    TriggerServerEvent('prospyr-business:server:updateSalary', data)
    cb({ ok = true })
end)

RegisterNUICallback('withdraw', function(data, cb)
    TriggerServerEvent('prospyr-business:server:withdraw', data)
    cb({ ok = true })
end)

RegisterNUICallback('deposit', function(data, cb)
    TriggerServerEvent('prospyr-business:server:deposit', data)
    cb({ ok = true })
end)

RegisterNUICallback('getTransactions', function(data, cb)
    TriggerServerEvent('prospyr-business:server:getTransactions', data.businessId, data.page or 1)
    cb({ ok = true })
end)

RegisterNUICallback('adminGetAllBusinesses', function(_, cb)
    TriggerServerEvent('prospyr-business:server:adminGetAll')
    cb({ ok = true })
end)

RegisterNUICallback('adminDeleteBusiness', function(data, cb)
    TriggerServerEvent('prospyr-business:server:adminDeleteBusiness', data)
    cb({ ok = true })
end)

-- ═════════════════════════════════════════════════════════════════════
-- Exports
-- ═════════════════════════════════════════════════════════════════════

exports('GetBusinesses', function()
    return PlayerData.businesses
end)

-- Export state
BusinessState = PlayerData