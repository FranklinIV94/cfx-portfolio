-- ═══════════════════════════════════════════════════════════════════════════════
-- ATM System — Configuration
-- shared/config.lua
--
-- Full configuration for the ATM banking system.
-- Buyers: Customize everything here — no need to edit core logic.
-- ═══════════════════════════════════════════════════════════════════════════════

Config = {}

-- ── General ───────────────────────────────────────────────────────────────────

Config.Enabled = true
Config.Language = 'en'

-- ── Currency ──────────────────────────────────────────────────────────────────

Config.Currency = '$'          -- Display symbol
Config.StartingBalance = 5000  -- New player starting bank balance
Config.StartingCash = 500      -- New player starting wallet cash

-- ── ATM Prop Models ────────────────────────────────────────────────────────────
-- These are the prop models that act as ATMs in GTA V.
-- Players can interact with any of these.

Config.ATMModels = {
    `prop_atm_01`,  -- Standard ATM (blue/gray)
    `prop_atm_02`,  -- Wall ATM
    `prop_atm_03`,  -- Pillar ATM
    `prop_fleeca_extrn`, -- Fleeca bank exterior ATM
}

-- Interaction range (meters) — how close the player needs to be to an ATM
Config.ATMRange = 2.0

-- Interaction key (default: E = 38)
Config.ATMKey = 38

-- ── Bank Locations (Blips) ──────────────────────────────────────────────────────
-- Blips shown on the map for banks. ATMs don't get blips by default.

Config.BankBlips = {
    { name = 'Fleeca Bank',     coords = vec3(150.0, -1040.0, 29.0) },
    { name = 'Fleeca Bank',     coords = vec3(-1212.0, -332.0, 37.0) },
    { name = 'Fleeca Bank',     coords = vec3(-2962.0, 482.0, 15.0) },
    { name = 'Fleeca Bank',     coords = vec3(-112.0, 6466.0, 31.0) },
    { name = 'Fleeca Bank',     coords = vec3(314.0, -279.0, 54.0) },
    { name = 'Pacific Standard', coords = vec3(235.0, 216.0, 106.0) },
}

Config.BankBlipSprite = 108     -- Bank blip sprite
Config.BankBlipColor = 2        -- Green
Config.BankBlipScale = 0.7

-- ── Transactions ───────────────────────────────────────────────────────────────

Config.Transactions = {
    -- Minimum transfer/deposit/withdraw amount
    minAmount = 1,

    -- Maximum single transaction amount (anti-money-laundering limit)
    maxAmount = 1000000,

    -- Transfer fee (percentage charged on bank-to-bank transfers)
    transferFee = 0.5,  -- 0.5% fee

    -- Withdrawal limit per transaction
    maxWithdrawal = 50000,

    -- Deposit limit per transaction
    maxDeposit = 500000,
}

-- ── ATM Fees ───────────────────────────────────────────────────────────────────
-- Realistic ATM withdrawal fees.

Config.ATMFee = {
    enabled = true,
    amount = 2.50,  -- Flat fee per ATM withdrawal
}

-- ── Overdraft ──────────────────────────────────────────────────────────────────

Config.Overdraft = {
    enabled = false,
    limit = -500,  -- How far negative a balance can go
}

-- ── Interest System ────────────────────────────────────────────────────────────
-- Periodic interest on bank balance (paid every N minutes).

Config.Interest = {
    enabled = false,
    rate = 0.5,     -- 0.5% per cycle
    interval = 1440, -- Every 24 hours (in minutes)
    maxBalance = 5000000, -- Interest only paid up to this balance
}

-- ── Anti-Abuse ─────────────────────────────────────────────────────────────────

Config.AntiAbuse = {
    -- Cooldown between ATM interactions (seconds)
    cooldown = 3,

    -- Max transactions per minute (rate limiting)
    rateLimit = 10,

    -- Log all transactions server-side
    logging = true,

    -- Max transaction history stored per player
    maxHistory = 50,
}

-- ── Commands ────────────────────────────────────────────────────────────────────

Config.Commands = {
    balance  = 'balance',   -- Check bank balance
    cash     = 'cash',       -- Check wallet cash
    transfer = 'transfer',  -- /transfer [id] [amount]
    givecash = 'givecash',  -- /givecash [id] [amount]
    bank     = 'bank',      -- Admin: /bank [id] to view player balance
    setmoney = 'setmoney',  -- Admin: /setmoney [id] [type] [amount]
}

-- ── Admin Permissions ──────────────────────────────────────────────────────────

Config.AdminPermission = 'atmsystem.admin'

-- ── Storage ────────────────────────────────────────────────────────────────────
-- 'oxmysql' for database storage, 'json' for file-based storage

Config.Storage = 'json'  -- Set to 'oxmysql' if you have oxmysql running

-- JSON file path (only used if Storage = 'json')
Config.JSONFile = 'atm_system_data.json'

-- ── Notifications ──────────────────────────────────────────────────────────────

Config.UseOxLib = true
Config.NotifyDuration = 5000

-- ── UI Settings ────────────────────────────────────────────────────────────────

-- ATM menu title (shown in ox_lib context menu or notification)
Config.MenuTitle = 'Fleeca Bank ATM'

-- Show account number in UI (randomly generated per player)
Config.ShowAccountNumber = true