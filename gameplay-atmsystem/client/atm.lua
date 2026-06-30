-- ═══════════════════════════════════════════════════════════════════════════════
-- ATM System — Client ATM Interaction
-- client/atm.lua
--
-- Handles ATM prop detection, interaction prompts, and the ATM menu.
-- ═══════════════════════════════════════════════════════════════════════════════

local nearATM = false
local currentATM = nil
local promptShown = false

-- ── ATM Detection Loop ────────────────────────────────────────────────────────

CreateThread(function()
    if not Config.Enabled then return end

    -- Precompute ATM model hashes for fast lookup
    local atmHashes = {}
    for _, model in ipairs(Config.ATMModels) do
        atmHashes[model] = true
    end

    while true do
        local sleep = 1000

        if not nearATM then
            -- Only check periodically when not near an ATM
            local coords = GetEntityCoords(cache.ped)
            local found = false
            local foundEntity = nil

            -- Search for ATM props in range
            local handle = StartShapeTestCapsule(
                coords.x, coords.y, coords.z,
                coords.x, coords.y, coords.z,
                Config.ATMRange + 5.0,
                2, -- Object flag
                cache.ped
            )

            -- Alternative: iterate nearby objects
            local nearbyObjects = GetGamePool('CObject')
            for _, obj in ipairs(nearbyObjects) do
                local model = GetEntityModel(obj)
                if atmHashes[model] then
                    local objCoords = GetEntityCoords(obj)
                    local dist = #(coords - objCoords)
                    if dist <= Config.ATMRange then
                        found = true
                        foundEntity = obj
                        break
                    end
                end
            end

            if found then
                nearATM = true
                currentATM = foundEntity
                sleep = 0 -- Start checking every frame for prompt
            end
        else
            -- We're near an ATM — check if we've moved away
            local coords = GetEntityCoords(cache.ped)
            local atmCoords = GetEntityCoords(currentATM)
            local dist = #(coords - atmCoords)

            if dist > Config.ATMRange + 1.0 then
                nearATM = false
                currentATM = nil
                promptShown = false
                sleep = 1000
            else
                -- Show interaction prompt
                if not promptShown then
                    Notify.Send(Util.L('atm_prompt'), 'info', 3000)
                    promptShown = true
                end
                sleep = 0
            end
        end

        Wait(sleep)
    end
end)

-- ── ATM Interaction Key Handler ────────────────────────────────────────────────

CreateThread(function()
    if not Config.Enabled then return end

    while true do
        Wait(0)
        if nearATM and currentATM then
            if IsControlJustReleased(0, Config.ATMKey) then
                OpenATMMenu()
            end
        end
    end
end)

-- ── ATM Menu ──────────────────────────────────────────────────────────────────

function OpenATMMenu()
    if GetResourceState('ox_lib') == 'started' then
        OpenOxLibMenu()
    else
        OpenNativeMenu()
    end
end

function OpenOxLibMenu()
    local options = {
        {
            title = Util.L('menu_balance'),
            description = 'Check your bank and cash balance',
            icon = 'fas fa-wallet',
            onSelect = function()
                TriggerServerEvent('atmsystem:server:checkBalance')
            end,
        },
        {
            title = Util.L('menu_withdraw'),
            description = 'Withdraw cash from your bank account',
            icon = 'fas fa-arrow-down',
            onSelect = function()
                local input = lib.inputDialog('Withdraw', {
                    {
                        type = 'number',
                        label = 'Amount',
                        description = 'Amount to withdraw',
                        min = 1,
                        max = Config.Transactions.maxWithdrawal,
                        default = 100,
                        required = true,
                    }
                })
                if input and input[1] then
                    TriggerServerEvent('atmsystem:server:withdraw', tonumber(input[1]))
                end
            end,
        },
        {
            title = Util.L('menu_deposit'),
            description = 'Deposit cash into your bank account',
            icon = 'fas fa-arrow-up',
            onSelect = function()
                local input = lib.inputDialog('Deposit', {
                    {
                        type = 'number',
                        label = 'Amount',
                        description = 'Amount to deposit',
                        min = 1,
                        max = Config.Transactions.maxDeposit,
                        default = 100,
                        required = true,
                    }
                })
                if input and input[1] then
                    TriggerServerEvent('atmsystem:server:deposit', tonumber(input[1]))
                end
            end,
        },
        {
            title = Util.L('menu_transfer'),
            description = 'Transfer money to another player',
            icon = 'fas fa-paper-plane',
            onSelect = function()
                local input = lib.inputDialog('Transfer', {
                    {
                        type = 'number',
                        label = 'Player ID',
                        description = 'Server ID of recipient',
                        min = 1,
                        required = true,
                    },
                    {
                        type = 'number',
                        label = 'Amount',
                        description = 'Amount to transfer',
                        min = 1,
                        required = true,
                    }
                })
                if input and input[1] and input[2] then
                    TriggerServerEvent('atmsystem:server:transfer', tonumber(input[1]), tonumber(input[2]))
                end
            end,
        },
        {
            title = Util.L('menu_history'),
            description = 'View your recent transactions',
            icon = 'fas fa-clock-rotate-left',
            onSelect = function()
                TriggerServerEvent('atmsystem:server:getHistory')
            end,
        },
        {
            title = Util.L('menu_exit'),
            icon = 'fas fa-xmark',
            onSelect = function() end,
        },
    }

    lib.registerContext({
        id = 'atm_menu',
        title = Config.MenuTitle,
        options = options,
    })

    lib.showContext('atm_menu')
end

-- ── Native Menu Fallback (no ox_lib) ───────────────────────────────────────────

function OpenNativeMenu()
    -- Simple text-based menu using chat messages
    Notify.Send('=== ' .. Util.L('menu_title') .. ' ===', 'info', 8000)
    Wait(200)
    Notify.Send('1: ' .. Util.L('menu_balance'), 'info', 8000)
    Wait(200)
    Notify.Send('2: ' .. Util.L('menu_withdraw'), 'info', 8000)
    Wait(200)
    Notify.Send('3: ' .. Util.L('menu_deposit'), 'info', 8000)
    Wait(200)
    Notify.Send('4: ' .. Util.L('menu_transfer'), 'info', 8000)
    Wait(200)
    Notify.Send('5: ' .. Util.L('menu_history'), 'info', 8000)
    Wait(200)
    Notify.Send('Type /balance, or use commands: /withdraw [amount], /deposit [amount], /transfer [id] [amount]', 'info', 8000)
end

-- ── Receive Balance from Server ───────────────────────────────────────────────

RegisterNetEvent('atmsystem:client:showBalance', function(bank, cash, accountNumber)
    local msg = Util.L('balance_both', Util.FormatMoney(bank), Util.FormatMoney(cash))
    if Config.ShowAccountNumber and accountNumber then
        msg = msg .. '\n' .. Util.L('account_number', accountNumber)
    end
    Notify.Send(msg, 'success', 8000)
end)

-- ── Receive Transaction History ──────────────────────────────────────────────

RegisterNetEvent('atmsystem:client:showHistory', function(history)
    if not history or #history == 0 then
        Notify.Send(Util.L('no_history'), 'info')
        return
    end

    if GetResourceState('ox_lib') == 'started' then
        local options = {}
        for _, tx in ipairs(history) do
            local sign = tx.type == 'deposit' and '+' or '-'
            local color = tx.type == 'deposit' and '🟢' or '🔴'
            table.insert(options, {
                title = string.format('%s %s %s', color, sign, Util.FormatMoney(tx.amount)),
                description = string.format('%s | Balance: %s', tx.type, Util.FormatMoney(tx.balanceAfter)),
                metadata = { { label = 'Time', value = tx.timestamp } },
            })
        end

        lib.registerContext({
            id = 'atm_history',
            title = 'Transaction History',
            options = options,
        })
        lib.showContext('atm_history')
    else
        for i = math.min(#history, 10), 1, -1 do
            local tx = history[i]
            local sign = tx.type == 'deposit' and '+' or '-'
            Notify.Send(string.format('%s %s — %s | Balance: %s', sign, Util.FormatMoney(tx.amount), tx.type, Util.FormatMoney(tx.balanceAfter)), 'info', 8000)
            Wait(300)
        end
    end
end)

-- ── Receive Notifications ─────────────────────────────────────────────────────

RegisterNetEvent('atmsystem:client:notify', function(message, type)
    Notify.Send(message, type)
end)