-- ═════════════════════════════════════════════════════════════════════
-- Prospyr SmartHUD — Vehicle Speedometer
-- ═════════════════════════════════════════════════════════════════════
-- Displays speed, fuel, gear, and vehicle damage when player is driving.
-- Appears automatically when entering a vehicle, hides when exiting.
-- ═════════════════════════════════════════════════════════════════════

local lastVehicleState = {}
local wasInVehicle = false

local function getVehicleData(vehicle)
    local data = {}

    -- Speed
    local speed = GetEntitySpeed(vehicle)
    if HUD_State.settings.speedUnit == 'mph' then
        data.speed = math.floor(speed * 2.23694)  -- m/s to mph
        data.unit = 'MPH'
    else
        data.speed = math.floor(speed * 3.6)     -- m/s to km/h
        data.unit = 'KM/H'
    end

    -- Fuel level (0-100)
    local fuel = GetVehicleFuelLevel(vehicle)
    data.fuel = math.floor(fuel)

    -- Gear (reverse, neutral, 1-6, etc.)
    local gear = GetVehicleCurrentGear(vehicle)
    if gear == 0 then
        data.gear = 'R'
    elseif gear == 1 and GetVehicleCurrentRPM(vehicle) < 0.1 then
        data.gear = 'N'
    else
        data.gear = tostring(gear)
    end

    -- Engine health (damage indicator)
    local engineHealth = GetVehicleEngineHealth(vehicle)
    data.engineHealth = math.max(0, math.min(100, math.floor(engineHealth / 10)))

    -- Body health
    local bodyHealth = GetVehicleBodyHealth(vehicle)
    data.bodyHealth = math.max(0, math.min(100, math.floor(bodyHealth / 10)))

    return data
end

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)

        if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
            if not wasInVehicle then
                wasInVehicle = true
                SendNUIMessage({ action = 'showVehicle', visible = true })
            end

            if HUD_State.visible and HUD_State.settings.showVehicle then
                local vData = getVehicleData(vehicle)

                -- Only send if data changed (reduces NUI traffic)
                local changed = false
                for k, v in pairs(vData) do
                    if lastVehicleState[k] ~= v then
                        changed = true
                        lastVehicleState[k] = v
                    end
                end

                if changed then
                    SendNUIMessage({
                        action = 'updateVehicle',
                        speed = HUD_State.settings.showVehicle and vData.speed or nil,
                        unit = vData.unit,
                        fuel = vData.fuel,
                        gear = vData.gear,
                        engineHealth = vData.engineHealth,
                        bodyHealth = vData.bodyHealth,
                        showSpeed  = Config.Vehicle.showSpeed,
                        showFuel   = Config.Vehicle.showFuel,
                        showGear   = Config.Vehicle.showGear,
                        showDamage = Config.Vehicle.showDamage,
                    })
                end
            end
        else
            if wasInVehicle then
                wasInVehicle = false
                SendNUIMessage({ action = 'showVehicle', visible = false })
                lastVehicleState = {}
            end
        end
        Wait(Config.UpdateIntervals.vehicle)
    end
end)