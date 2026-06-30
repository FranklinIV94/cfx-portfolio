-- ═════════════════════════════════════════════════════════════════════
-- Prospyr SmartHUD — HUD Bar Updates
-- ═════════════════════════════════════════════════════════════════════
-- Collects player status values and sends them to NUI for rendering.
-- Uses minimal polling — only sends updates when values change.
-- ═════════════════════════════════════════════════════════════════════

local lastStatus = {}

-- Get player health/armor/stamina as 0-100 percentages
local function getVitals()
    local ped = PlayerPedId()
    local health = GetEntityHealth(ped)
    local maxHealth = GetEntityMaxHealth(ped)
    -- Normalize: subtract 100 (base health) for proper 0-100 range
    local healthPct = math.max(0, math.min(100, ((health - 100) / (maxHealth - 100)) * 100))
    local armor = GetPedArmour(ped)
    local armorPct = math.max(0, math.min(100, armor / 100 * 100))
    local staminaPct = math.max(0, math.min(100, GetPlayerSprintStaminaRemaining(PlayerId()) * 100))
    return {
        health = math.floor(healthPct),
        armor = math.floor(armorPct),
        stamina = math.floor(staminaPct),
    }
end

-- Get hunger/thirst from ox_status (if available)
local function getNeeds()
    local needs = { hunger = 100, thirst = 100 }
    -- ox_status export
    local ok, status = pcall(function()
        return exports['ox_status']:getStatus()
    end)
    if ok and type(status) == 'table' then
        needs.hunger = status.hunger or 100
        needs.thirst = status.thirst or 100
    end
    return needs
end

-- Get money from framework
local function getMoney()
    local money = { cash = 0, bank = 0 }
    if Config.Money.framework == 'ox' then
        local ok, inventory = pcall(function()
            return exports['ox_inventory']
        end)
        if ok then
            local cashItems = inventory:Search('count', 'money') or 0
            money.cash = cashItems
        end
        -- Bank balance via oxmysql callback is async; use server event for bank
    elseif Config.Money.framework == 'qb' then
        local PlayerData = exports['qb-core']:GetPlayerData()
        money.cash = PlayerData.money?.cash or 0
        money.bank = PlayerData.money?.bank or 0
    elseif Config.Money.framework == 'esx' then
        local xPlayer = exports['esx']:getSharedObject().getPlayerData()
        money.cash = xPlayer.money or 0
        money.bank = xPlayer.bank or 0
    end
    return money
end

-- Main status update loop
CreateThread(function()
    while true do
        if HUD_State.visible then
            local vitals = getVitals()
            local needs = getNeeds()

            -- Only send NUI update if values changed (reduces unnecessary NUI calls)
            local changed = false
            for k, v in pairs(vitals) do
                if lastStatus[k] ~= v then
                    changed = true
                    lastStatus[k] = v
                end
            end
            for k, v in pairs(needs) do
                if lastStatus[k] ~= v then
                    changed = true
                    lastStatus[k] = v
                end
            end

            if changed then
                SendNUIMessage({
                    action = 'updateStatus',
                    health   = HUD_State.settings.showHealth and vitals.health or nil,
                    armor    = HUD_State.settings.showArmor and vitals.armor or nil,
                    stamina  = HUD_State.settings.showStamina and vitals.stamina or nil,
                    hunger   = HUD_State.settings.showHunger and needs.hunger or nil,
                    thirst   = HUD_State.settings.showThirst and needs.thirst or nil,
                })
                HUD_State.lastActivity = GetGameTimer()
            end

            -- Fade logic
            if HUD_State.settings.bars.animateFade then
                local idle = GetGameTimer() - HUD_State.lastActivity
                if idle > HUD_State.settings.bars.fadeDelay then
                    SendNUIMessage({ action = 'fadeBars', opacity = HUD_State.settings.bars.fadeOpacity })
                else
                    SendNUIMessage({ action = 'fadeBars', opacity = 1.0 })
                end
            end
        end
        Wait(Config.UpdateIntervals.status)
    end
end)

-- Money update loop (slower interval — money changes less frequently)
CreateThread(function()
    while true do
        if HUD_State.visible and HUD_State.settings.showMoney then
            local money = getMoney()
            if lastStatus.cash ~= money.cash or lastStatus.bank ~= money.bank then
                lastStatus.cash = money.cash
                lastStatus.bank = money.bank
                SendNUIMessage({
                    action = 'updateMoney',
                    cash = money.cash,
                    bank = money.bank,
                    showCash = Config.Money.showCash,
                    showBank = Config.Money.showBank,
                })
            end
        end
        Wait(Config.UpdateIntervals.money)
    end
end)

-- Receive bank balance from server (for ox framework async bank lookup)
RegisterNetEvent('prospyr-hud:client:updateBank', function(bank)
    if lastStatus.bank ~= bank then
        lastStatus.bank = bank
        SendNUIMessage({
            action = 'updateMoney',
            cash = lastStatus.cash or 0,
            bank = bank,
            showCash = Config.Money.showCash,
            showBank = Config.Money.showBank,
        })
    end
end)