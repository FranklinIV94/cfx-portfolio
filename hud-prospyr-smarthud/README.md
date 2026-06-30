# Prospyr SmartHUD

A clean, modern, fully customizable HUD resource for FiveM servers. Built with performance in mind — minimal polling, change-detection NUI updates, and player-persisted settings.

## Features

- **Status Bars**: Health, Armor, Stamina, Hunger, Thirst (ox_status compatible)
- **Money Display**: Cash and Bank balance (supports ox_inventory, qb-core, ESX)
- **Voice Indicator**: Talking state + voice range display (pma-voice compatible)
- **Vehicle Speedometer**: Speed, fuel, gear, and damage indicator (auto-shows when driving)
- **Minimap Controls**: Toggle visibility, cycle sizes (small/normal/large)
- **NUI Settings Panel**: In-game customization — toggle elements, change colors, adjust bar dimensions, all without restarting the resource
- **Player-Persisted Settings**: Settings save to KVP — players keep their customization across sessions
- **Performance-Optimized**: Change-detection updates (only sends NUI messages when values change), configurable update intervals

## Requirements

- FiveM server (artifact 12000+ recommended)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_status](https://github.com/overextended/ox_status) (optional — for hunger/thirst)
- [oxmysql](https://github.com/overextended/oxmysql) (only if using ox_inventory money integration)

## Installation

See [MANUAL.md](MANUAL.md) for complete installation and configuration guide.

## Usage

See [USERGUIDE.md](USERGUIDE.md) for player-facing documentation.

## Architecture

```
prospyr-smarthud/
├── fxmanifest.lua          # Resource manifest
├── config/
│   ├── config.lua          # Main configuration (theme, defaults, intervals)
│   └── positions.lua        # Default element positions
├── client/
│   ├── main.lua             # Entry point, keybinds, NUI callbacks, exports
│   ├── hud.lua              # Status bar + money update loops
│   ├── settings.lua         # Settings panel NUI logic
│   ├── voice.lua            # Voice indicator + range cycling
│   └── vehicle.lua          # Vehicle speedometer
├── server/
│   └── main.lua             # Bank balance lookups (oxmysql)
└── html/
    ├── index.html            # NUI structure
    ├── style.css             # Dark-themed styling (CSS variables)
    └── app.js                # NUI message routing + settings panel
```

## Configuration

All configuration is in `config/config.lua` and `config/positions.lua`. See the file comments for each option. Key settings:

| Setting | Description | Default |
|---|---|---|
| `Config.Theme` | Color scheme (hex values) | Blue/dark theme |
| `Config.Defaults` | Which elements show by default | All visible |
| `Config.Bars` | Bar dimensions, fade behavior | 180×8px, fade after 5s |
| `Config.UpdateIntervals` | Poll rate per element (ms) | Status: 1s, Money: 2s |
| `Config.SettingsKey` | Keybind to open settings | F7 |
| `Config.Money.framework` | Framework for money display | `ox` |

## Exports

### Client Exports

| Export | Parameters | Returns | Description |
|---|---|---|---|
| `GetHUDConfig` | — | `table` | Returns current player settings |
| `ToggleHUD` | — | `boolean` | Toggle HUD visibility |
| `SetHUDElement` | `element: string, visible: boolean` | — | Show/hide a specific element |

## Performance Notes

- NUI messages are only sent when values change (not on every poll tick)
- Update intervals are configurable — lower intervals = smoother but more CPU
- Server-side bank balance check only runs for `ox` framework (other frameworks handle it client-side)
- No rendering loops in NUI — CSS transitions handle smooth animation

## Compatibility

- **Frameworks**: ox_inventory, qb-core, ESX (legacy)
- **Voice**: pma-voice, FiveM native voice
- **Status**: ox_status (optional — falls back to 100% if not present)
- **Database**: oxmysql (for server-side bank balance only)

## License

MIT — Free to use, modify, and distribute. Attribution appreciated.

## Author

**Prospyr 305** — [Prospyr 305](https://github.com/prospyr305)