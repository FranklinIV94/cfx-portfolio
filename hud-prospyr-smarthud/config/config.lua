Config = {}

-- ═════════════════════════════════════════════════════════════════════
-- Prospyr SmartHUD — Main Configuration
-- ═════════════════════════════════════════════════════════════════════
-- All visual and behavioral settings for the HUD. Players can override
-- these individually via the in-game settings panel (default key: F7).
-- ═════════════════════════════════════════════════════════════════════

-- Theme colors (hex, no #). Players can customize via NUI panel.
Config.Theme = {
    primary     = '4f9eff',  -- accent / highlight
    secondary   = '2a2a2e',  -- background dark
    background  = '1a1a1e',  -- bar background
    text        = 'ffffff',
    textDim     = '9a9a9e',
    success     = '4fff7a',
    warning     = 'ffb84f',
    danger      = 'ff4f6a',
}

-- Default visibility (players toggle via settings panel)
Config.Defaults = {
    showHealth   = true,
    showArmor    = true,
    showStamina  = true,
    showHunger   = true,
    showThirst   = true,
    showMoney    = true,
    showVoice    = true,
    showVehicle  = true,
    showMinimap  = true,
}

-- Money display
Config.Money = {
    showCash  = true,
    showBank  = true,
    -- Framework: 'ox' = ox_inventory, 'qb' = qb-core, 'esx' = esx legacy
    -- Set to 'ox' for ox_inventory cash/bank accounts
    framework  = 'ox',
}

-- Status bar configuration
Config.Bars = {
    width       = 180,    -- px
    height      = 8,      -- px
    radius      = 4,       -- px (border-radius)
    margin      = 4,       -- px between bars
    animateFade = true,    -- fade bars out after inactivity
    fadeDelay   = 5000,    -- ms before fade starts
    fadeOpacity = 0.3,     -- opacity when faded
}

-- Minimap controls
Config.Minimap = {
    toggleKey     = 'B',       -- key to toggle minimap (within settings menu)
    defaultSize   = 'normal', -- 'small' | 'normal' | 'large'
    sizes         = {
        small  = { w = 150, h = 150 },
        normal = { w = 200, h = 200 },
        large  = { w = 260, h = 260 },
    },
}

-- Voice indicator
Config.Voice = {
    showWhenTalking = true,
    showRange       = true,
    ranges          = { 2.0, 8.0, 14.0 },  -- whisper, normal, shout
    defaultRange    = 2,                   -- index into ranges (1-based)
}

-- Vehicle speedometer
Config.Vehicle = {
    showSpeed     = true,
    showFuel      = true,
    showGear      = true,
    showDamage    = true,
    speedUnit     = 'mph',     -- 'mph' | 'kmh'
    showWhenDriving = true,
}

-- Settings panel keybind
Config.SettingsKey = 'F7'  -- default key to open settings NUI panel

-- Performance: update intervals (ms). Lower = smoother but more CPU.
Config.UpdateIntervals = {
    status    = 1000,   -- health/armor/stamina/hunger/thirst
    money     = 2000,   -- cash/bank balance check
    vehicle   = 100,    -- speed/fuel/gear (frequent for smooth display)
    voice     = 250,    -- voice range/active check
    minimap   = 5000,   -- minimap size sync (rare)
}

-- Save/load settings persistence
Config.SaveSettings = true  -- saves player settings to KVP (GetResourceKvpString)