-- ═════════════════════════════════════════════════════════════════════
-- Prospyr SmartHUD — Voice Indicator
-- ═════════════════════════════════════════════════════════════════════
-- Tracks voice activity and range, sends updates to NUI for rendering.
-- Compatible with pma-voice and FiveM built-in voice systems.
-- ═════════════════════════════════════════════════════════════════════

local lastVoiceState = { active = false, range = 1 }

CreateThread(function()
    while true do
        if HUD_State.visible and HUD_State.settings.showVoice then
            local ped = PlayerPedId()
            local talking = NetworkIsPlayerTalking(PlayerId())
            local range = HUD_State.settings.voiceRange or 1

            -- Check pma-voice export for voice range
            local ok, pmaRange = pcall(function()
                return exports['pma-voice']:getVoiceRange()
            end)
            if ok and pmaRange then
                -- Map pma-voice range to our index
                for i, r in ipairs(Config.Voice.ranges) do
                    if math.abs(pmaRange - r) < 0.5 then
                        range = i
                        break
                    end
                end
            end

            -- Only update NUI if state changed
            if talking ~= lastVoiceState.active or range ~= lastVoiceState.range then
                lastVoiceState.active = talking
                lastVoiceState.range = range

                SendNUIMessage({
                    action = 'updateVoice',
                    active = talking,
                    range = range,
                    ranges = Config.Voice.ranges,
                })
            end
        end
        Wait(Config.UpdateIntervals.voice)
    end
end)

-- Keybind to cycle voice range
RegisterCommand('hudvoicerange', function()
    local current = HUD_State.settings.voiceRange or 1
    local next = current + 1
    if next > #Config.Voice.ranges then next = 1 end
    HUD_State.settings.voiceRange = next

    -- Apply to pma-voice if available
    local ok = pcall(function()
        exports['pma-voice']:setVoiceRange(Config.Voice.ranges[next])
    end)

    SendNUIMessage({
        action = 'updateVoice',
        active = lastVoiceState.active,
        range = next,
        ranges = Config.Voice.ranges,
    })

    if Config.SaveSettings then
        SetResourceKvpString('prospyr_hud_settings', json.encode(HUD_State.settings))
    end
end, false)

RegisterKeyMapping('hudvoicerange', 'Cycle SmartHUD Voice Range', 'keyboard', 'V')