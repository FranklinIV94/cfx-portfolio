-- ═════════════════════════════════════════════════════════════════════
-- Prospyr Business Manager — Client Business Logic
-- Blip management, business creation flow, location setup
-- ═════════════════════════════════════════════════════════════════════

local blips = {}

-- Create/update blips for all owned businesses
RegisterNetEvent('prospyr-business:client:updateBlips', function(businesses)
    -- Remove existing blips
    for id, blip in pairs(blips) do
        RemoveBlip(blip)
        blips[id] = nil
    end

    if not Config.Blips.showBlips then return end

    for _, biz in ipairs(businesses) do
        if biz.blip_coords then
            local coords = json.decode(biz.blip_coords)
            if coords and coords.x then
                local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
                local bizType = Config.BusinessTypes[biz.type] or Config.BusinessTypes['general']
                SetBlipSprite(blip, bizType.blipSprite)
                SetBlipColour(blip, bizType.blipColor)
                SetBlipScale(blip, Config.Blips.blipScale)
                SetBlipDisplay(blip, Config.Blips.blipDisplay)
                SetBlipAsShortRange(blip, true)
                BeginTextCommandSetBlipName('STRING')
                AddTextComponentSubstringPlayerName(biz.name)
                EndTextCommandSetBlipName(blip)
                blips[biz.id] = blip
            end
        end
    end
end)

-- Business creation flow — player selects location on foot
RegisterNetEvent('prospyr-business:client:createBusinessFlow', function()
    lib.notify({
        title = 'Business Manager',
        description = 'Stand where you want your business blip, then press [ENTER]. Press [ESC] to cancel.',
        type = 'info',
        duration = 8000,
    })

    -- Wait for player to confirm location
    local confirmed = false
    local cancelled = false

    -- Key handlers
    RegisterCommand('+bizConfirmLocation', function()
        confirmed = true
    end, false)
    RegisterKeyMapping('+bizConfirmLocation', 'Confirm Business Location', 'keyboard', 'RETURN')

    RegisterCommand('+bizCancelLocation', function()
        cancelled = true
    end, false)
    RegisterKeyMapping('+bizCancelLocation', 'Cancel Business Creation', 'keyboard', 'ESCAPE')

    -- Wait for input
    CreateThread(function()
        while not confirmed and not cancelled do
            Wait(0)
        end

        if cancelled then
            lib.notify({ title = 'Business Manager', description = 'Business creation cancelled.', type = 'info' })
            return
        end

        -- Get player coords
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local blipCoords = json.encode({ x = coords.x, y = coords.y, z = coords.z })

        -- Open creation form via NUI
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'showCreateForm',
            blipCoords = blipCoords,
            businessTypes = Config.BusinessTypes,
        })
    end)
end)

-- Receive creation form submission from NUI
RegisterNUICallback('submitCreateBusiness', function(data, cb)
    -- Validate
    if not data.name or data.name == '' then
        TriggerEvent('prospyr-business:client:notify', 'Business name is required.', 'error')
        cb({ ok = false, error = 'Name required' })
        return
    end

    if not data.type or not Config.BusinessTypes[data.type] then
        TriggerEvent('prospyr-business:client:notify', 'Invalid business type.', 'error')
        cb({ ok = false, error = 'Invalid type' })
        return
    end

    -- Send to server with location data
    TriggerServerEvent('prospyr-business:server:createBusiness', {
        name = data.name,
        type = data.type,
        blipCoords = data.blipCoords,
    })

    SetNuiFocus(false, false)
    cb({ ok = true })
end)

-- Business created confirmation
RegisterNetEvent('prospyr-business:client:businessCreated', function(business)
    table.insert(BusinessState.businesses, business)
    TriggerEvent('prospyr-business:client:updateBlips', BusinessState.businesses)
    TriggerEvent('prospyr-business:client:notify', 'Business "' .. business.name .. '" created successfully!', 'success')
end)

-- Business deleted
RegisterNetEvent('prospyr-business:client:businessDeleted', function(businessId)
    for i, biz in ipairs(BusinessState.businesses) do
        if biz.id == businessId then
            table.remove(BusinessState.businesses, i)
            break
        end
    end
    if blips[businessId] then
        RemoveBlip(blips[businessId])
        blips[businessId] = nil
    end
    TriggerEvent('prospyr-business:client:notify', 'Business deleted.', 'info')
end)