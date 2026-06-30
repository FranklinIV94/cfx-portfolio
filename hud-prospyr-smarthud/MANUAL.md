# Prospyr SmartHUD — Installation & Configuration Manual

**Version:** 1.0.0  
**Author:** Prospyr 305  
**License:** MIT

---

## Prerequisites

Before installing Prospyr SmartHUD, ensure your server meets these requirements:

| Requirement | Minimum Version | Notes |
|---|---|---|
| FiveM Server Artifact | 12000+ | Older artifacts may work but are unsupported |
| ox_lib | 3.0+ | Required for callbacks and UI utilities |
| ox_status | 2.0+ | Optional — provides hunger/thirst data |
| oxmysql | 2.0+ | Required only for bank balance display (ox_inventory) |
| pma-voice | 2.0+ | Optional — enables voice range indicator |

### Framework Compatibility

Prospyr SmartHUD supports three frameworks for money display:

- **ox_inventory** (recommended) — uses oxmysql for server-side bank lookups
- **qb-core** — reads `PlayerData.money` client-side
- **ESX** — reads `ESX.PlayerData.accounts` client-side

Set `Config.Money.framework` in `config/config.lua` to match your server.

---

## Installation

### Step 1: Download

Place the `prospyr-smarthud` folder in your server's `resources` directory:

```
resources/
└── prospyr-smarthud/
    ├── fxmanifest.lua
    ├── config/
    ├── client/
    ├── server/
    └── html/
```

### Step 2: Ensure Dependencies

Make sure all required resources are in your `server.cfg` and started **before** SmartHUD:

```cfg
ensure ox_lib
ensure ox_status      # optional but recommended
ensure oxmysql        # required for ox_inventory bank balance
ensure prospyr-smarthud
```

### Step 3: Verify Installation

1. Start your server
2. Check the server console for any errors related to `prospyr-smarthud`
3. Join the server — you should see the HUD appear in the bottom-left corner
4. Press **F7** (default) to open the settings panel

If the HUD doesn't appear, check the troubleshooting section below.

---

## Configuration

All configuration is done in `config/config.lua`. Player-specific settings (colors, positions, visibility) are handled via the in-game NUI panel and persisted to KVP.

### Theme Colors

```lua
Config.Theme = {
    primary     = '4f9eff',  -- accent / highlight color
    secondary   = '2a2a2e',  -- panel background
    background  = '1a1a1e',  -- bar background
    text        = 'ffffff',
    textDim     = '9a9a9e',
    success     = '4fff7a',
    warning     = 'ffb84f',
    danger      = 'ff4f6a',
}
```

Players can override these via the settings panel. Changes are saved per-player.

### Default Visibility

Control which elements show by default for new players:

```lua
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
```

### Status Bars

```lua
Config.Bars = {
    width       = 180,    -- bar width in pixels
    height      = 8,      -- bar height in pixels
    radius      = 4,      -- border-radius in pixels
    margin      = 4,      -- gap between bars in pixels
    animateFade = true,    -- fade bars after inactivity
    fadeDelay   = 5000,   -- ms of inactivity before fade
    fadeOpacity = 0.3,    -- opacity when faded (0.0-1.0)
}
```

### Update Intervals

Performance tuning — lower values = smoother but more CPU usage:

```lua
Config.UpdateIntervals = {
    status    = 1000,   -- health/armor/stamina/hunger/thirst (ms)
    money     = 2000,   -- cash/bank balance (ms)
    vehicle   = 100,    -- speed/fuel/gear (ms, frequent for smooth display)
    voice     = 250,    -- voice range/active state (ms)
    minimap   = 5000,   -- minimap size sync (ms, rare)
}
```

### Money Display

```lua
Config.Money = {
    showCash  = true,
    showBank  = true,
    framework  = 'ox',  -- 'ox' | 'qb' | 'esx'
}
```

### Minimap

```lua
Config.Minimap = {
    toggleKey     = 'B',
    defaultSize   = 'normal',  -- 'small' | 'normal' | 'large'
    sizes = {
        small  = { w = 150, h = 150 },
        normal = { w = 200, h = 200 },
        large  = { w = 260, h = 260 },
    },
}
```

### Voice Indicator

```lua
Config.Voice = {
    showWhenTalking = true,
    showRange       = true,
    ranges          = { 2.0, 8.0, 14.0 },  -- whisper, normal, shout
    defaultRange    = 2,                   -- index (1-based)
}
```

### Vehicle Speedometer

```lua
Config.Vehicle = {
    showSpeed     = true,
    showFuel      = true,
    showGear      = true,
    showDamage    = true,
    speedUnit     = 'mph',  -- 'mph' | 'kmh'
    showWhenDriving = true,
}
```

### Settings Panel Keybind

```lua
Config.SettingsKey = 'F7'  -- default key to open settings NUI
```

Players can also use the command `/hudsettings` to open the panel.

---

## Exports (For Developers)

Other resources can interact with SmartHUD via exports:

### Client Exports

```lua
-- Get current player HUD settings
local settings = exports['prospyr-smarthud']:GetHUDConfig()

-- Toggle HUD visibility
local isVisible = exports['prospyr-smarthud']:ToggleHUD()

-- Show/hide a specific element
exports['prospyr-smarthud']:SetHUDElement('Health', false)
exports['prospyr-smarthud']:SetHUDElement('Money', true)
```

### Events

```lua
-- Fired when HUD finishes initializing
RegisterNetEvent('prospyr-hud:client:started', function()
    print('SmartHUD ready')
end)
```

---

## Position Configuration

Element positions are defined in `config/positions.lua` as percentages of screen dimensions:

```lua
Config.Positions = {
    health  = { x = 1.5, y = 95.0 },
    armor   = { x = 1.5, y = 92.0 },
    stamina = { x = 1.5, y = 89.0 },
    hunger  = { x = 1.5, y = 86.0 },
    thirst  = { x = 1.5, y = 83.0 },
    money   = { x = 1.5, y = 78.0 },
    voice   = { x = 1.5, y = 73.0 },
    vehicle = { x = 50.0, y = 92.0 },
}
```

Players can drag elements in the settings panel to reposition them. Custom positions are saved to KVP.

---

## Troubleshooting

### HUD doesn't appear
1. Check `server.cfg` has `ensure prospyr-smarthud` after dependencies
2. Check console for Lua errors
3. Verify `ox_lib` is running — SmartHUD waits for it on init
4. Press F7 to open settings — if the panel opens but HUD doesn't show, toggle elements on

### Status bars show 0%
1. Ensure `ox_status` is installed and running (for hunger/thirst)
2. Health/armor/stamina use native FiveM player stats — these should always work
3. If using custom status resources, ensure they export to ox_status format

### Money shows $0
1. Verify `Config.Money.framework` matches your inventory system
2. For `ox` framework: ensure oxmysql is running and the player has a bank account
3. For `qb` framework: ensure `QBcore` is loaded before SmartHUD
4. For `esx` framework: ensure `esx:getSharedObject` is available

### Settings don't persist
1. Ensure `Config.SaveSettings = true` in config
2. KVP storage requires FiveM artifact 12000+
3. Check client console for JSON decode errors (corrupted KVP string)

### Performance issues
1. Increase `Config.UpdateIntervals` values (especially `vehicle` — 100ms is aggressive)
2. Disable `Config.Bars.animateFade` if CPU is tight
3. Reduce `Config.Voice` polling interval

### NUI panel doesn't open
1. Ensure no other resource is capturing NUI focus at the same time
2. Check that `html/index.html`, `html/style.css`, and `html/app.js` are listed in `fxmanifest.lua files{}`
3. Verify no browser extensions or overlays are interfering

---

## Uninstallation

1. Remove `ensure prospyr-smarthud` from `server.cfg`
2. Delete the `prospyr-smarthud` folder from `resources/`
3. Player KVP settings will remain (harmless) unless FiveM cache is cleared

---

## Support

- **Issues:** Report bugs on the Cfx Marketplace listing or GitHub
- **Compatibility:** Tested with FiveM artifact 12000+, ox_lib 3.0+, ox_status 2.0+
- **Updates:** Check the Cfx Marketplace page for new versions

---

*Prospyr SmartHUD — Built by Prospyr 305*