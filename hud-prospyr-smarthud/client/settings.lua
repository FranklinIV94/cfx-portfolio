-- ═════════════════════════════════════════════════════════════════════
-- Prospyr SmartHUD — Settings Panel (NUI)
-- ═════════════════════════════════════════════════════════════════════
-- Handles the in-game NUI settings panel: toggling elements, changing
-- colors, adjusting bar dimensions, and repositioning HUD elements.
-- ═════════════════════════════════════════════════════════════════════

local settingsOpen = false

-- Toggle NUI focus and settings panel
RegisterNetEvent('prospyr-hud:client:toggleSettings', function()
    settingsOpen = not settingsOpen
    if settingsOpen then
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'openSettings',
            settings = HUD_State.settings,
            theme = HUD_State.settings.theme,
            bars = HUD_State.settings.bars,
            positions = HUD_State.positions,
        })
    else
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'closeSettings' })
    end
end)

-- NUI callback: element toggle (show/hide individual HUD elements)
RegisterNUICallback('toggleElement', function(data, cb)
    local key = 'show' .. data.element
    if HUD_State.settings[key] ~= nil then
        HUD_State.settings[key] = data.visible
        SendNUIMessage({ action = 'updateSettings', settings = HUD_State.settings })
        if Config.SaveSettings then
            SetResourceKvpString('prospyr_hud_settings', json.encode(HUD_State.settings))
        end
        cb({ ok = true, settings = HUD_State.settings })
    else
        cb({ ok = false, error = 'Unknown element: ' .. data.element })
    end
end)

-- NUI callback: theme color change
RegisterNUICallback('updateColor', function(data, cb)
    if HUD_State.settings.theme[data.colorKey] then
        HUD_State.settings.theme[data.colorKey] = data.value
        SendNUIMessage({ action = 'updateSettings', settings = HUD_State.settings })
        if Config.SaveSettings then
            SetResourceKvpString('prospyr_hud_settings', json.encode(HUD_State.settings))
        end
        cb({ ok = true })
    else
        cb({ ok = false, error = 'Unknown color key: ' .. data.colorKey })
    end
end)

-- NUI callback: bar dimension change
RegisterNUICallback('updateBars', function(data, cb)
    for k, v in pairs(data) do
        if HUD_State.settings.bars[k] ~= nil then
            HUD_State.settings.bars[k] = v
        end
    end
    SendNUIMessage({ action = 'updateSettings', settings = HUD_State.settings })
    if Config.SaveSettings then
        SetResourceKvpString('prospyr_hud_settings', json.encode(HUD_State.settings))
    end
    cb({ ok = true })
end)

-- NUI callback: minimap size change
RegisterNUICallback('setMinimapSize', function(data, cb)
    HUD_State.settings.minimapSize = data.size
    local sizeConfig = Config.Minimap.sizes[data.size]
    if sizeConfig then
        -- Apply minimap size change via native
        ExecuteCommand('minimap ' .. data.size)
        SendNUIMessage({ action = 'updateSettings', settings = HUD_State.settings })
    end
    if Config.SaveSettings then
        SetResourceKvpString('prospyr_hud_settings', json.encode(HUD_State.settings))
    end
    cb({ ok = true })
end)

-- NUI callback: voice range change
RegisterNUICallback('setVoiceRange', function(data, cb)
    HUD_State.settings.voiceRange = data.range
    if Config.SaveSettings then
        SetResourceKvpString('prospyr_hud_settings', json.encode(HUD_State.settings))
    end
    cb({ ok = true })
end)

-- NUI callback: speed unit change
RegisterNUICallback('setSpeedUnit', function(data, cb)
    HUD_State.settings.speedUnit = data.unit
    if Config.SaveSettings then
        SetResourceKvpString('prospyr_hud_settings', json.encode(HUD_State.settings))
    end
    cb({ ok = true })
end)

-- NUI callback: drag element position
RegisterNUICallback('updatePosition', function(data, cb)
    if HUD_State.settings.positions[data.element] then
        HUD_State.settings.positions[data.element].x = data.x
        HUD_State.settings.positions[data.element].y = data.y
        if Config.SaveSettings then
            SetResourceKvpString('prospyr_hud_settings', json.encode(HUD_State.settings))
        end
    end
    cb({ ok = true })
end)