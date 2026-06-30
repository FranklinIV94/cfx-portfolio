# SmartSpawn — Quality-of-Life Vehicle Spawner

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Version](https://img.shields.io/badge/version-1.0.0-green.svg)
![FXVersion](https://img.shields.io/badge/fx_version-cerulean-purple.svg)

A clean, configurable vehicle spawning system for FiveM servers. SmartSpawn provides tier-based permissions, anti-abuse cooldowns, model validation, and no-spawn zones — all controlled from a single config file.

## Features

- **Tiered Permissions** — Admin, VIP, and Default tiers with different vehicle category access
- **Anti-Abuse Cooldowns** — Per-player cooldowns with configurable durations per tier
- **Model Validation** — Validates vehicle models exist before spawning (prevents errors)
- **Category Restrictions** — Limit which vehicle categories each tier can spawn
- **Blocklist** — Hard-block specific vehicle models from being spawned
- **No-Spawn Zones** — Define areas where spawning is disabled (admin areas, event zones)
- **Max Vehicles Per Player** — Prevent entity flooding with a per-player vehicle limit
- **Previous Vehicle Cleanup** — Optionally delete the player's last spawned vehicle
- **Multi-Language Support** — Built-in localization (English, Spanish; easily extensible)
- **ox_lib Integration** — Enhanced notifications when ox_lib is present, native fallback otherwise
- **Clean Code** — Fully commented, organized into logical modules, uses FiveM best practices

## Requirements

- FiveM Server (FX version: cerulean or later)
- **Optional:** [ox_lib](https://github.com/overextended/ox_lib) — for enhanced notifications and callbacks
- **Optional:** ACE permission system (built into FiveM) — for tier-based access

> SmartSpawn works without ox_lib. It automatically falls back to native GTA V notifications and standard net events.

## Installation

1. **Download** the `qol-smartspawn` folder
2. **Place** it in your server's `resources` directory:
   ```
   resources/[local]/qol-smartspawn/
   ```
3. **Add** to your `server.cfg`:
   ```cfg
   ensure qol-smartspawn
   ```
4. **Configure** by editing `shared/config.lua` to match your server's needs
5. **Restart** your server (or start the resource with `start qol-smartspawn`)

## ACE Permission Setup

To enable tiered permissions, add these to your `server.cfg`:

```cfg
# Default tier (all players)
add_principal identifier.steam:110000100000000 smartspawn.tier.default

# VIP tier (donators, supporters)
add_principal identifier.steam:110000100000001 smartspawn.tier.vip

# Admin tier (staff)
add_principal group.admin smartspawn.tier.admin
```

Replace the identifiers with your actual player identifiers. You can use any ACE principal system (Badger_Discord_API, vMenu, etc.) to assign these.

## Configuration

All configuration is in `shared/config.lua`. Key settings:

| Setting | Default | Description |
|---------|---------|-------------|
| `Config.Command` | `'spawn'` | The chat command to spawn vehicles |
| `Config.Cooldown.default` | `30` | Cooldown (seconds) for default players |
| `Config.Cooldown.vip` | `10` | Cooldown for VIP players |
| `Config.Cooldown.admin` | `0` | Cooldown for admins (0 = disabled) |
| `Config.MaxVehiclesPerPlayer` | `3` | Maximum simultaneous vehicles per player |
| `Config.DeletePrevious` | `true` | Delete previous vehicle when spawning new one |
| `Config.SpawnMethod` | `'front'` | Spawn in front of player or at player position |
| `Config.AutoSeat` | `true` | Auto-seat player into spawned vehicle |

### Vehicle Categories

FiveM classifies vehicles into these categories:

| Class | Category |
|-------|----------|
| 0 | Compacts |
| 1 | Sedans |
| 2 | SUV |
| 3 | Sports |
| 4 | Sports Classics |
| 5 | Super |
| 6 | Muscle |
| 7 | Sports Classics |
| 8 | Motorcycles |
| 9 | Off-Road |
| 10 | Industrial |
| 11 | Utility |
| 12 | Vans |
| 13 | Cycles |
| 14 | Boats |
| 15 | Helicopters |
| 16 | Planes |
| 17 | Service |
| 18 | Emergency |
| 19 | Military |
| 20 | Commercial |

### No-Spawn Zones

Add zones where spawning is disabled:

```lua
Config.NoSpawnZones = {
    { vec3(-1037.0, -2737.0, 20.0), 50.0 },  -- Airport, radius 50m
    { vec3(215.0, -808.0, 30.0), 30.0 },     -- Legion Square, radius 30m
}
```

## Commands

| Command | Permission | Description |
|---------|-----------|-------------|
| `/spawn <model>` | All players | Spawn a vehicle by model name |
| `/spawnclear [playerId]` | Admin | Clear a player's cooldown |

### Usage Examples

```
/spawn sultan       — Spawn a Sultan RS
/spawn bati         — Spawn a Bati 801 motorcycle
/spawn sanchez      — Spawn a Sanchez dirt bike
/spawn hydra        — Blocked if on blocklist or category not allowed
```

## File Structure

```
qol-smartspawn/
├── fxmanifest.lua          — Resource manifest
├── shared/
│   ├── config.lua          — All configurable settings
│   └── util.lua             — Shared utilities (validation, localization)
├── client/
│   ├── main.lua             — Client-side command handling & vehicle spawning
│   └── notify.lua            — Notification wrapper (ox_lib or native)
├── server/
│   ├── main.lua             — Server-side validation & vehicle tracking
│   └── cooldown.lua          — Cooldown manager module
├── README.md               — This file
├── USER_GUIDE.md            — End-user guide
├── CHANGELOG.md             — Version history
└── LICENSE                  — MIT license
```

## Exports (for other resources)

### Server-side

```lua
exports['qol-smartspawn']:clearCooldown(playerId)
exports['qol-smartspawn']:getCooldown(playerId)        -- Returns seconds remaining
exports['qol-smartspawn']:getPlayerVehicles(playerId)   -- Returns { netIds, models }
```

## FAQ

**Q: Does this work without ox_lib?**
A: Yes. SmartSpawn automatically detects if ox_lib is running and falls back to native notifications and standard net events if not.

**Q: Can I limit vehicles to only certain categories for free players?**
A: Yes. Edit `Config.TierCategories.default` in `shared/config.lua` to control which categories each tier can access.

**Q: How do I add a vehicle to the blocklist?**
A: Add the model name to `Config.Blocklist` in `shared/config.lua`:
```lua
Config.Blocklist = { 'rhino', 'hydra', 'lazer' }
```

**Q: Can other resources check a player's cooldown?**
A: Yes. Use the server export: `exports['qol-smartspawn']:getCooldown(playerId)`

**Q: What happens to spawned vehicles when a player disconnects?**
A: The server automatically cleans up all vehicles spawned by that player on disconnect.

## Credits

- **Author:** Franklin Bryant IV
- **License:** MIT
- **Contact:** [GitHub](https://github.com/franklinbryant/cfx-portfolio)

## License

MIT License — see [LICENSE](LICENSE) for full text.