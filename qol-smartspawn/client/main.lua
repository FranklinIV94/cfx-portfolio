-- ═══════════════════════════════════════════════════════════════════════════════
-- SmartSpawn — Client Main
-- client/main.lua
--
-- Handles the client-side command, model loading, vehicle creation,
-- and communication with the server for validation + cooldown.
-- ═══════════════════════════════════════════════════════════════════════════════

local spawnedVehicle = nil -- Track the player's last spawned vehicle (client side)

-- ── Command Registration ───────────────────────────────────────────────────────

RegisterCommand(Config.Command, function(_, args)
    if not Config.Enabled then
        Notify.Send(Util.L('resource_disabled'), 'error')
        return
    end

    local model = args[1]
    if not model or model == '' then
        Notify.Send(Util.L('usage', Config.Command), 'warning')
        return
    end

    model = string.lower(model)

    -- Basic input sanitization: only alphanumeric and underscore
    if not string.match(model, '^[a-z0-9_]+$') then
        Notify.Send('Invalid model name format.', 'error')
        return
    end

    -- Check blocklist on client first (fast-fail)
    if Util.IsBlocklisted(model) then
        Notify.Send(Util.L('blocklisted'), 'error')
        return
    end

    -- Request server validation (permission tier, cooldown, category)
    -- Using ox_lib callback if available, otherwise standard net event
    if GetResourceState('ox_lib') == 'started' then
        local response = lib.callback.await('smartspawn:server:validate', false, model)
        HandleValidationResponse(response, model)
    else
        -- Fallback: use a net event + net event response
        TriggerServerEvent('smartspawn:server:requestSpawn', model)
    end
end, false)

-- Fallback response handler (when ox_lib not present)
RegisterNetEvent('smartspawn:client:spawnResponse', function(response)
    local model = response.model
    HandleValidationResponse(response, model)
end)

--- Handle the server's validation response and spawn the vehicle if approved.
--- @param response table Contains: { allowed = boolean, reason = string, tier = string }
--- @param model string The requested model name
function HandleValidationResponse(response, model)
    if not response.allowed then
        Notify.Send(response.reason or 'Spawn denied.', 'error')
        return
    end

    -- Validate model on client (server can't load models)
    local modelHash = joaat(model)
    if not Util.IsValidVehicleModel(modelHash) then
        Notify.Send(Util.L('invalid_model', model), 'error')
        -- Notify server to refund the cooldown
        TriggerServerEvent('smartspawn:server:refundCooldown')
        return
    end

    -- Check no-spawn zone
    local playerCoords = GetEntityCoords(cache.ped)
    if Util.IsInNoSpawnZone(playerCoords) then
        Notify.Send(Util.L('no_spawn_zone'), 'error')
        TriggerServerEvent('smartspawn:server:refundCooldown')
        return
    end

    -- Request model load
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 100 do
        Wait(100)
        timeout = timeout + 1
    end

    if not HasModelLoaded(modelHash) then
        Notify.Send('Failed to load vehicle model. Try again.', 'error')
        TriggerServerEvent('smartspawn:server:refundCooldown')
        return
    end

    -- Delete previous vehicle if enabled
    if Config.DeletePrevious and spawnedVehicle and DoesEntityExist(spawnedVehicle) then
        -- Only delete if the player owns it
        local owner = NetworkGetEntityOwner(spawnedVehicle)
        if owner == cache.playerId then
            SetEntityAsMissionEntity(spawnedVehicle, true, true)
            DeleteVehicle(spawnedVehicle)
            spawnedVehicle = nil
            Notify.Send(Util.L('deleted_previous'), 'info')
        end
    end

    -- Calculate spawn position
    local spawnCoords, spawnHeading
    if Config.SpawnMethod == 'front' then
        local forward = GetEntityForwardVector(cache.ped)
        spawnCoords = playerCoords + forward * Config.SpawnDistance
        spawnHeading = GetEntityHeading(cache.ped)
    else
        spawnCoords = playerCoords
        spawnHeading = GetEntityHeading(cache.ped)
    end

    -- Create the vehicle
    local vehicle = CreateVehicle(modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnHeading, true, false)

    -- Wait for vehicle to be fully created
    local vehTimeout = 0
    while not DoesEntityExist(vehicle) and vehTimeout < 50 do
        Wait(50)
        vehTimeout = vehTimeout + 1
    end

    if not DoesEntityExist(vehicle) then
        Notify.Send('Failed to create vehicle. Try again.', 'error')
        SetModelAsNoLongerNeeded(modelHash)
        TriggerServerEvent('smartspawn:server:refundCooldown')
        return
    end

    -- Configure vehicle
    SetVehicleDirtLevel(vehicle, 0.0)
    SetVehicleFuelLevel(vehicle, 100.0)
    SetVehicleNumberPlateText(vehicle, 'SMART ' .. math.random(1000, 9999))

    if Config.HeadlightColor > 0 then
        SetVehicleHeadlightsColour(vehicle, Config.HeadlightColor)
    end

    -- Mark model as no longer needed (free memory)
    SetModelAsNoLongerNeeded(modelHash)

    -- Auto-seat player
    if Config.AutoSeat then
        TaskWarpPedIntoVehicle(cache.ped, vehicle, -1)
    end

    -- Track spawned vehicle
    spawnedVehicle = vehicle

    -- Set vehicle as a state bag for server tracking
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    Entity(vehicle).state:set('smartspawn_owner', cache.serverId, true)

    Notify.Send(Util.L('spawned', model), 'success')

    -- Notify server of successful spawn for tracking
    TriggerServerEvent('smartspawn:server:spawnComplete', netId, model)
end

-- ── Cleanup on Resource Stop ───────────────────────────────────────────────────

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    if spawnedVehicle and DoesEntityExist(spawnedVehicle) then
        SetEntityAsMissionEntity(spawnedVehicle, true, true)
        DeleteVehicle(spawnedVehicle)
    end
end)

-- ── Cleanup on Player Death/Disconnect ─────────────────────────────────────────

AddEventHandler('playerDropped', function()
    if spawnedVehicle and DoesEntityExist(spawnedVehicle) then
        SetEntityAsMissionEntity(spawnedVehicle, true, true)
        DeleteVehicle(spawnedVehicle)
    end
end)

-- ── Keybind Suggestion ─────────────────────────────────────────────────────────
-- Register a key mapping so players can bind it in settings (default: no key)
RegisterKeyMapping(Config.Command .. '_quick', 'SmartSpawn Quick Menu', 'keyboard', '')