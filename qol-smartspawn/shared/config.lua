-- ═══════════════════════════════════════════════════════════════════════════════
-- SmartSpawn — Configuration
-- shared/config.lua
--
-- Everything a server owner needs to customize is here.
-- Buyers: Edit values in this file — no need to touch core logic.
-- ═══════════════════════════════════════════════════════════════════════════════

Config = {}

-- ── General Settings ──────────────────────────────────────────────────────────

-- Command prefix. Change '/spawn' to '/vspawn' or anything you like.
Config.Command = 'spawn'

-- Enable/disable the resource without removing it.
Config.Enabled = true

-- Language for notifications. Supported: 'en', 'es', 'fr', 'de'
Config.Language = 'en'

-- ── Cooldown System ───────────────────────────────────────────────────────────

-- Per-player cooldown in seconds between spawns.
Config.Cooldown = {
    enabled  = true,
    default  = 30,    -- Default cooldown for non-VIP players
    vip      = 10,    -- Cooldown for VIP/Donator tier
    admin    = 0,     -- Admins have no cooldown (0 = disabled)
}

-- ── Permission Tiers ───────────────────────────────────────────────────────────
-- Map ACE permission strings to tier names.
-- Add these to your server.cfg via: add_principal group.admin smartspawn.tier.admin

Config.Tiers = {
    ['smartspawn.tier.admin']  = 'admin',
    ['smartspawn.tier.vip']    = 'vip',
    ['smartspawn.tier.default'] = 'default',
}

-- ── Vehicle Categories ─────────────────────────────────────────────────────────
-- Players can only spawn vehicles from categories their tier allows.
-- Set to 'all' to allow every category for that tier.

Config.TierCategories = {
    admin   = 'all',
    vip     = {'compacts', 'sedans', 'suv', 'sports', 'sportsclassics', 'super', 'muscle', 'motorcycles', 'offroad', 'industrial', 'utility', 'vans', 'cycles'},
    default = {'compacts', 'sedans', 'suv', 'muscle', 'motorcycles', 'offroad', 'vans', 'cycles'},
}

-- ── Model Validation ──────────────────────────────────────────────────────────

-- Hard blocklist of vehicle models that should never be spawnable.
-- Add exploit vehicles, unreleased models, or anything you want restricted.
Config.Blocklist = {
    -- 'rhino', 'hydra', 'lazer',
}

-- Max vehicles per player that can exist simultaneously (prevents entity flooding).
Config.MaxVehiclesPerPlayer = 3

-- Delete the player's previous vehicle when spawning a new one?
Config.DeletePrevious = true

-- ── Spawn Behavior ─────────────────────────────────────────────────────────────

-- Spawn the vehicle directly at the player's position vs. in front.
Config.SpawnMethod = 'front'  -- 'front' | 'at_player'

-- Distance in front of player when SpawnMethod = 'front'
Config.SpawnDistance = 4.0

-- Auto-seat the player into the spawned vehicle?
Config.AutoSeat = true

-- Headlight color (0–8, default 0 = stock)
Config.HeadlightColor = 0

-- ── Blacklisted Zones ──────────────────────────────────────────────────────────
-- Coordinates where spawning is disabled (e.g., admin areas, event zones).
-- Format: { vec3 center, radius }
Config.NoSpawnZones = {
    -- { vec3(-1037.0, -2737.0, 20.0), 50.0 },  -- Example: airport
}

-- ── Notifications ──────────────────────────────────────────────────────────────

-- Use ox_lib notify if available, otherwise fall back to native GTA notifications.
Config.UseOxLib = true

-- Notification durations (ms)
Config.NotifyDuration = 5000