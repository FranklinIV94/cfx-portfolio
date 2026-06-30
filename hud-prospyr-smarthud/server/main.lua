-- ═════════════════════════════════════════════════════════════════════
-- Prospyr SmartHUD — Server Main
-- ═════════════════════════════════════════════════════════════════════
-- Server-side logic: bank balance lookups via oxmysql for ox_inventory.
-- Minimal server footprint — most HUD logic runs client-side.
-- ═════════════════════════════════════════════════════════════════════

-- Periodic bank balance sync for players using ox_inventory framework
CreateThread(function()
    if Config.Money.framework ~= 'ox' then return end

    while true do
        local players = GetPlayers()
        for _, src in ipairs(players) do
            local citizenId = nil

            -- Get player identifier (supports multiple frameworks)
            local identifiers = GetPlayerIdentifiers(src)
            for _, id in ipairs(identifiers) do
                if string.match(id, '^license:') then
                    citizenId = string.gsub(id, 'license:', '')
                    break
                end
            end

            if citizenId then
                -- Query bank balance from ox_inventory money account
                local ok, result = pcall(function()
                    return MySQL.query.await(
                        'SELECT SUM(amount) as bank FROM ox_inventory_items WHERE name = ? AND metadata->>"account" = "bank"',
                        { citizenId }
                    )
                end)
                -- Fallback: simple bank money table (adjust to your framework)
                if not ok or not result then
                    ok, result = pcall(function()
                        return MySQL.query.await(
                            'SELECT bank FROM players WHERE identifier = ?',
                            { citizenId }
                        )
                    end)
                end

                if ok and result and result[1] then
                    local bank = tonumber(result[1].bank) or 0
                    TriggerClientEvent('prospyr-hud:client:updateBank', src, bank)
                end
            end
        end
        Wait(Config.UpdateIntervals.money)
    end
end)

-- Player connected — send initial bank balance
RegisterNetEvent('playerJoining', function()
    local src = source
    Wait(2000) -- wait for player to fully load
    -- Trigger an immediate bank balance check for the new player
    TriggerClientEvent('prospyr-hud:client:checkBank', src)
end)

-- Request bank balance from client (client triggers this to request a refresh)
RegisterNetEvent('prospyr-hud:server:requestBank', function()
    local src = source
    local identifiers = GetPlayerIdentifiers(src)
    local citizenId = nil
    for _, id in ipairs(identifiers) do
        if string.match(id, '^license:') then
            citizenId = string.gsub(id, 'license:', '')
            break
        end
    end

    if citizenId then
        local ok, result = pcall(function()
            return MySQL.query.await('SELECT bank FROM players WHERE identifier = ?', { citizenId })
        end)
        if ok and result and result[1] then
            TriggerClientEvent('prospyr-hud:client:updateBank', src, tonumber(result[1].bank) or 0)
        end
    end
end)