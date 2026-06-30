-- ═══════════════════════════════════════════════════════════════════════════════
-- ATM System — Server Database Layer
-- server/database.lua
--
-- Handles player data persistence. Supports oxmysql or JSON file storage.
-- Provides a unified Database API used by the rest of the server code.
-- ═══════════════════════════════════════════════════════════════════════════════

Database = {}

-- In-memory cache: { [serverId] = { bank, cash, accountNumber, history } }
local playerData = {}
local dataLoaded = false

-- ── JSON Storage ───────────────────────────────────────────────────────────────

local function GetJSONPath()
    local resourcePath = GetResourcePath(GetCurrentResourceName())
    return resourcePath .. '/' .. (Config.JSONFile or 'atm_system_data.json')
end

local function LoadFromJSON()
    local path = GetJSONPath()
    local file = io.open(path, 'r')
    if not file then
        return {}
    end
    local content = file:read('*a')
    file:close()
    if not content or content == '' then return {} end
    return json.decode(content) or {}
end

local function SaveToJSON(data)
    local path = GetJSONPath()
    local file = io.open(path, 'w')
    if not file then
        print(('[ATM System] ERROR: Could not write to %s'):format(path))
        return false
    end
    file:write(json.encode(data, { indent = true }))
    file:close()
    return true
end

-- ── Database Initialization ────────────────────────────────────────────────────

function Database.Init()
    if Config.Storage == 'oxmysql' and GetResourceState('oxmysql') == 'started' then
        -- Create table if not exists
        MySQL.query([[
            CREATE TABLE IF NOT EXISTS atm_system_accounts (
                identifier VARCHAR(60) PRIMARY KEY,
                bank_balance DOUBLE DEFAULT 0,
                cash_balance DOUBLE DEFAULT 0,
                account_number VARCHAR(20),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
            )
        ]])

        MySQL.query([[
            CREATE TABLE IF NOT EXISTS atm_system_transactions (
                id INT AUTO_INCREMENT PRIMARY KEY,
                identifier VARCHAR(60),
                type VARCHAR(20),
                amount DOUBLE,
                balance_after DOUBLE,
                target_identifier VARCHAR(60) NULL,
                timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (identifier) REFERENCES atm_system_accounts(identifier)
            )
        ]])

        print('[ATM System] Using oxmysql storage')
    else
        -- JSON mode
        local data = LoadFromJSON()
        print(('[ATM System] Using JSON storage (%d accounts loaded)'):format(table.size(data)))
    end
    dataLoaded = true
end

-- ── Get Player Identifier ─────────────────────────────────────────────────────

local function GetIdentifier(source)
    local identifiers = GetPlayerIdentifiers(source)
    if not identifiers or #identifiers == 0 then return nil end
    -- Prefer license2, then license, then steam
    for _, id in ipairs(identifiers) do
        if string.match(id, '^license2:') then return id end
    end
    for _, id in ipairs(identifiers) do
        if string.match(id, '^license:') then return id end
    end
    for _, id in ipairs(identifiers) do
        if string.match(id, '^steam:') then return id end
    end
    return identifiers[1]
end

-- ── Load Player Data ──────────────────────────────────────────────────────────

function Database.LoadPlayer(source)
    if not dataLoaded then Database.Init() end

    local identifier = GetIdentifier(source)
    if not identifier then
        return nil
    end

    if Config.Storage == 'oxmysql' and GetResourceState('oxmysql') == 'started' then
        local result = MySQL.single.await('SELECT * FROM atm_system_accounts WHERE identifier = ?', { identifier })
        if result then
            playerData[source] = {
                bank = result.bank_balance,
                cash = result.cash_balance,
                accountNumber = result.account_number,
                identifier = identifier,
                history = {},
            }
            -- Load recent history
            local history = MySQL.query.await('SELECT * FROM atm_system_transactions WHERE identifier = ? ORDER BY timestamp DESC LIMIT ?',
                { identifier, Config.AntiAbuse.maxHistory })
            for _, row in ipairs(history or {}) do
                table.insert(playerData[source].history, {
                    type = row.type,
                    amount = row.amount,
                    balanceAfter = row.balance_after,
                    target = row.target_identifier,
                    timestamp = tostring(row.timestamp),
                })
            end
        else
            -- New player
            local accountNumber = Util.GenerateAccountNumber()
            MySQL.insert('INSERT INTO atm_system_accounts (identifier, bank_balance, cash_balance, account_number) VALUES (?, ?, ?, ?)',
                { identifier, Config.StartingBalance, Config.StartingCash, accountNumber })
            playerData[source] = {
                bank = Config.StartingBalance,
                cash = Config.StartingCash,
                accountNumber = accountNumber,
                identifier = identifier,
                history = {},
            }
        end
    else
        -- JSON storage
        local data = LoadFromJSON()
        if not data[identifier] then
            data[identifier] = {
                bank = Config.StartingBalance,
                cash = Config.StartingCash,
                accountNumber = Util.GenerateAccountNumber(),
            }
            SaveToJSON(data)
        end

        playerData[source] = {
            bank = data[identifier].bank,
            cash = data[identifier].cash,
            accountNumber = data[identifier].accountNumber,
            identifier = identifier,
            history = data[identifier].history or {},
        }
    end

    return playerData[source]
end

-- ── Save Player Data ──────────────────────────────────────────────────────────

function Database.SavePlayer(source)
    if not playerData[source] then return end
    local data = playerData[source]

    if Config.Storage == 'oxmysql' and GetResourceState('oxmysql') == 'started' then
        MySQL.update('UPDATE atm_system_accounts SET bank_balance = ?, cash_balance = ? WHERE identifier = ?',
            { data.bank, data.cash, data.identifier })
    else
        local allData = LoadFromJSON()
        allData[data.identifier] = {
            bank = data.bank,
            cash = data.cash,
            accountNumber = data.accountNumber,
            history = data.history,
        }
        SaveToJSON(allData)
    end
end

-- ── Log Transaction ────────────────────────────────────────────────────────────

function Database.LogTransaction(source, txType, amount, balanceAfter, targetIdentifier)
    if not Config.AntiAbuse.logging then return end
    if not playerData[source] then return end

    local data = playerData[source]
    local entry = {
        type = txType,
        amount = amount,
        balanceAfter = balanceAfter,
        target = targetIdentifier,
        timestamp = os.date('%Y-%m-%d %H:%M:%S'),
    }

    -- Add to in-memory history
    table.insert(data.history, 1, entry)

    -- Trim history
    while #data.history > Config.AntiAbuse.maxHistory do
        table.remove(data.history)
    end

    -- Persist to database if using oxmysql
    if Config.Storage == 'oxmysql' and GetResourceState('oxmysql') == 'started' then
        MySQL.insert('INSERT INTO atm_system_transactions (identifier, type, amount, balance_after, target_identifier) VALUES (?, ?, ?, ?, ?)',
            { data.identifier, txType, amount, balanceAfter, targetIdentifier })
    end
end

-- ── Get Player Data ────────────────────────────────────────────────────────────

function Database.Get(source)
    return playerData[source]
end

function Database.GetAll()
    return playerData
end

-- ── Set Player Balance (Admin) ────────────────────────────────────────────────

function Database.SetBalance(source, accountType, amount)
    if not playerData[source] then return false end
    if accountType == 'bank' then
        playerData[source].bank = amount
    elseif accountType == 'cash' then
        playerData[source].cash = amount
    else
        return false
    end
    Database.SavePlayer(source)
    return true
end

-- ── Cleanup on Disconnect ─────────────────────────────────────────────────────

function Database.RemovePlayer(source)
    if playerData[source] then
        Database.SavePlayer(source)
        playerData[source] = nil
    end
end

-- ── Helper: table.size (if not available) ─────────────────────────────────────
if not table.size then
    function table.size(t)
        local count = 0
        for _ in pairs(t) do count = count + 1 end
        return count
    end
end