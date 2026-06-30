# CFX Portfolio — FiveM Lua Resources

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Resources](https://img.shields.io/badge/resources-2-green.svg)

Portfolio of FiveM/GTA V Lua resource mods built for the CFX Creator Program application. These resources demonstrate clean code, anti-abuse design, configurable architecture, and thorough documentation — the qualities that make marketplace resources worth buying.

## Resources

### 1. SmartSpawn — Quality-of-Life Vehicle Spawner

A practical vehicle spawning system that servers actually need. Features tiered permissions (Admin/VIP/Default via ACE), per-player anti-abuse cooldowns, model validation, vehicle category restrictions, blocklist support, no-spawn zones, and max vehicle limits. Uses ox_lib callbacks with native fallback.

**Key technical highlights:**
- Server-side cooldown manager as a reusable module
- Client-side model loading with timeout handling
- State bag tracking for spawned vehicles
- Server exports for cross-resource integration
- Automatic cleanup on disconnect/resource stop

📁 **Location:** [`qol-smartspawn/`](qol-smartspawn/)

### 2. ATM System — Gameplay Enhancement Banking Mod

A complete banking system with ATM prop interactions, dual currency (bank + cash), player-to-player transfers, transaction history, interest accrual, and admin management. Supports both JSON file storage and oxmysql database persistence.

**Key technical highlights:**
- Modular architecture: database layer, transaction processor, event handler, client UI — all separated
- Dual storage backend (JSON / oxmysql) with unified API
- Anti-abuse: cooldowns, rate limiting, max transaction limits, amount validation
- ox_lib context menu UI with native notification fallback
- Server-side exports for job/payment integration with other resources
- Full transaction logging and history

📁 **Location:** [`gameplay-atmsystem/`](gameplay-atmsystem/)

## Development Philosophy

These resources were built with the following principles:

1. **Configuration over code** — Server owners should never need to touch core logic. Everything is in `config.lua`.
2. **Graceful degradation** — Optional dependencies (ox_lib, oxmysql) enhance the experience but aren't required. The mods work out of the box.
3. **Anti-abuse by default** — Cooldowns, rate limits, validation, and entity limits are built in, not afterthoughts.
4. **Clean architecture** — Shared utilities, separated client/server concerns, modular server code, reusable exports.
5. **Documentation is a feature** — Every resource ships with README, user guide, changelog, and license. Buyers should never be guessing.

## Technical Stack

- **Language:** Lua 5.4 (`lua54 'on'`)
- **FX Version:** Cerulean
- **Optional Dependencies:** ox_lib (UI/notifications), oxmysql (database)
- **Best Practices:** Cache player, state bags, net events, ox_lib callbacks, proper model loading, entity cleanup

## About the Author

**Franklin Bryant IV** is a developer building tools for FiveM server owners. This portfolio was developed using an AI-assisted workflow: the resources were designed and iterated with AI assistance for code quality, documentation, and testing — the same way modern developers use tools like Copilot and Claude Code. The architecture, feature decisions, and quality standards are entirely human-directed.

### AI-Assisted Development Workflow

The development process for these resources followed this workflow:

1. **Design phase** — Feature scoping, architecture planning, and config structure designed manually
2. **Implementation phase** — Lua code written with AI assistance (Claude/GPT) for boilerplate, error handling patterns, and FiveM API usage
3. **Review phase** — Every file reviewed for correctness: nil checks, event security, anti-abuse coverage, FiveM best practices
4. **Documentation phase** — READMEs and user guides written with AI assistance for completeness and consistency
5. **Quality pass** — Final review for code cleanliness, comment quality, and documentation accuracy

This approach produces higher quality output than either pure manual or pure AI generation — the human sets the standards and architecture, the AI handles volume and consistency, and the human verifies everything.

## Contact

- **GitHub:** [franklinbryant](https://github.com/franklinbryant)
- **CFX Forum:** Pending application
- **Email:** Available on request

## License

MIT License — see [LICENSE](LICENSE) for full text.

## File Structure

```
cfx-portfolio/
├── README.md                      — This file
├── LICENSE                        — MIT license
├── qol-smartspawn/                — Mod 1: Vehicle Spawner (QoL)
│   ├── fxmanifest.lua
│   ├── shared/
│   │   ├── config.lua
│   │   └── util.lua
│   ├── client/
│   │   ├── main.lua
│   │   └── notify.lua
│   ├── server/
│   │   ├── main.lua
│   │   └── cooldown.lua
│   ├── README.md
│   ├── USER_GUIDE.md
│   ├── CHANGELOG.md
│   └── LICENSE
├── gameplay-atmsystem/            — Mod 2: ATM Banking System
│   ├── fxmanifest.lua
│   ├── shared/
│   │   ├── config.lua
│   │   └── util.lua
│   ├── client/
│   │   ├── main.lua
│   │   ├── atm.lua
│   │   ├── notify.lua
│   │   └── blips.lua
│   ├── server/
│   │   ├── main.lua
│   │   ├── database.lua
│   │   └── transactions.lua
│   ├── sql/
│   │   └── schema.sql
│   ├── README.md
│   ├── USER_GUIDE.md
│   ├── CHANGELOG.md
│   └── LICENSE
```