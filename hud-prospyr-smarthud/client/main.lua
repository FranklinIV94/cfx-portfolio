-- ═════════════════════════════════════════════════════════════════════
-- Prospyr SmartHUD — Client Main
-- ═════════════════════════════════════════════════════════════════════
-- Entry point: initializes state, registers keybinds, starts update loops.
-- ═════════════════════════════════════════════════════════════════════

local State = {
    settings = {},
    visible = true,
    inVehicle = false,
    voiceActive = false,
    voiceRange = 1,
    lastActivity = 0,
}

-- Merge config defaults into player settings
local function initSettings()
    State.settings = {
        showHealth  = Config.Defaults.showHealth,
        showArmor   = Config.Defaults.showArmor,
        showStamina = Config.Defaults.showStamina,
        showHunger  = Config.Defaults.showHunger,
        showThirst  = Config.Defaults.showThirst,
        showMoney   = Config.Defaults.showMoney,
        showVoice   = Config.Defaults.showVoice,
        showVehicle = Config.Defaults.showVehicle,
        showMinimap = Config.Defaults.showMinimap,
        minimapSize = Config.Minimap.defaultSize,
        voiceRange  = Config.Voice.defaultRange,
        theme       = Config.Theme,
        bars        = Config.Bars,
        positions   = Config.Positions,
        speedUnit   = Config.Vehicle.speedUnit,
    }

    -- Load saved settings from KVP if persistence is enabled
    if Config.SaveSettings then
        local saved = GetResourceKvpString('prospyr_hud_settings')
        if saved then
            local ok, parsed = pcall(json.decode, saved)
            if ok and type(parsed) == 'table' then
                -- Merge saved over defaults (preserves new config keys)
                for k, v in pairs(parsed) do
                    State.settings[k] = v
                end
            end
        end
    end
end

-- Save current settings to KVP
local function saveSettings()
    if not Config.SaveSettings then return end
    SetResourceKvpString('prospyr_hud_settings', json.encode(State.settings))
end

-- ═════════════════════════════════════════════════════════════════════
-- Exports
-- ═════════════════════════════════════════════════════════════════════

exports('GetHUDConfig', function()
    return State.settings
end)

exports('ToggleHUD', function()
    State.visible = not State.visible
    SendNUIMessage({ action = 'toggle', visible = State.visible })
    return State.visible
end)

exports('SetHUDElement', function(element, visible)
    if State.settings['show' .. element] ~= nil then
        State.settings['show' .. element] = visible
        SendNUIMessage({ action = 'updateSettings', settings = State.settings })
        saveSettings()
    end
end)

-- ═════════════════════════════════════════════════════════════════════
-- Initialization
-- ═════════════════════════════════════════════════════════════════════

CreateThread(function()
    -- Wait for ox_lib to be ready
    while not GetResourceState('ox_lib') == 'started' do
        Wait(100)
    end

    initSettings()

    -- Send initial config to NUI
    SendNUIMessage({
        action = 'init',
        settings = State.settings,
        theme = State.settings.theme,
        bars = State.settings.bars,
        positions = State.settings.positions,
    })

    -- Start update loops
    TriggerEvent('prospyr-hud:client:started')
end)

-- ═════════════════════════════════════════════════════════════════════
-- Keybind: Settings panel
-- ═════════════════════════════════════════════════════════════════════

RegisterCommand('hudsettings', function()
    TriggerEvent('prospyr-hud:client:openSettings')
end, false)

RegisterKeyMapping('hudsettings', 'Open SmartHUD Settings', 'keyboard', Config.SettingsKey)

-- Toggle HUD visibility via command
RegisterCommand('hudtoggle', function()
    exports['prospyr-smarthud']:ToggleHUD()
end, false)

-- ═════════════════════════════════════════════════════════════════════
-- NUI Callbacks
-- ═════════════════════════════════════════════════════════════════════

RegisterNUICallback('saveSettings', function(data, cb)
    State.settings = data.settings
    saveSettings()
    cb({ ok = true })
end)

RegisterNUICallback('closeSettings', function(_, cb)
    SetNuiFocus(false, false)
    cb({ ok = true })
end)

RegisterNUICallback('resetSettings', function(_, cb)
    initSettings()
    SendNUIMessage({
        action = 'init',
        settings = State.settings,
        theme = State.settings.theme,
        bars = State.settings.bars,
        positions = State.settings.positions,
    })
    saveSettings()
    cb({ ok = true, settings = State.settings })
end)

RegisterNUICallback('previewPosition', function(data, cb)
    -- Live preview of element positions during drag
    State.settings.positions[data.element] = data.position
    cb({ ok = true })
end)

-- ═════════════════════════════════════════════════════════════════════
-- Event: Open Settings Panel
-- ═════════════════════════════════════════════════════════════════════

RegisterNetEvent('prospyr-hud:client:openSettings', function()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openSettings',
        settings = State.settings,
        theme = State.settings.theme,
        bars = State.settings.bars,
        positions = State.settings.positions,
    })
end)

-- Export state for other client files
HUD_State = State