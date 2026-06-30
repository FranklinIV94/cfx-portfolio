# ATM System — Gameplay Enhancement Banking Mod

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Version](https://img.shields.io/badge/version-1.0.0-green.svg)
![FXVersion](https://img.shields.io/badge/fx_version-cerulean-purple.svg)

A complete banking system for FiveM servers featuring ATM interactions, cash and bank balances, player-to-player transfers, transaction history, interest accrual, and admin management tools.

## Features

- **ATM Interactions** — Walk up to any ATM prop in GTA V, press [E] to open the banking menu
- **Dual Currency System** — Separate bank balance and wallet cash (just like real life)
- **Withdrawals & Deposits** — Move money between bank and cash at any ATM
- **Player Transfers** — Send money bank-to-bank with configurable transfer fees
- **Cash Giving** — Hand cash to nearby players in person (with proximity check)
- **Transaction History** — Full log of all transactions with amounts and timestamps
- **ATM Fees** — Configurable withdrawal fees for realistic banking
- **Interest System** — Optional periodic interest on bank balances
- **Overdraft Protection** — Optional negative balance limit
- **Anti-Abuse** — Cooldowns, rate limiting, and max transaction limits
- **Admin Tools** — View player balances, set money, with ACE permissions
- **Dual Storage** — JSON file storage by default, oxmysql for database persistence
- **Bank Blips** — Bank locations shown on the minimap
- **ox_lib Integration** — Rich UI menus when ox_lib is present, native fallback otherwise
- **Multi-Language** — English and Spanish built in, easily extensible
- **Clean Architecture** — Modular design with separated database, transaction, and event layers

## Requirements

- FiveM Server (FX version: cerulean or later)
- **Optional:** [ox_lib](https://github.com/overextended/ox_lib) — for context menus, input dialogs, and enhanced notifications
- **Optional:** [oxmysql](https://github.com/overextended/oxmysql) — for database persistence (falls back to JSON file storage)

> ATM System works out of the box with zero dependencies. ox_lib and oxmysql enhance the experience but are not required.

## Installation

### Quick Start (JSON storage, no dependencies)

1. **Download** the `gameplay-atmsystem` folder
2. **Place** it in your server's `resources` directory:
   ```
   resources/[local]/gameplay-atmsystem/
   ```
3. **Add** to your `server.cfg`:
   ```cfg
   ensure gameplay-atmsystem
   ```
4. **Restart** your server

That's it. The system uses JSON file storage by default and works immediately.

### Database Mode (with oxmysql)

1. Follow the quick start steps above
2. **Import** the SQL schema:
   ```bash
   mysql -u root -p your_database < sql/schema.sql
   ```
   Or execute `sql/schema.sql` in your database tool
3. **Change** `Config.Storage` in `shared/config.lua`:
   ```lua
   Config.Storage = 'oxmysql'
   ```
4. **Ensure** oxmysql is started before this resource in your `server.cfg`:
   ```cfg
   ensure oxmysql
   ensure gameplay-atmsystem
   ```

### ACE Permissions (for admin commands)

Add to `server.cfg`:
```cfg
# Assign admin permission to specific players or groups
add_principal identifier.steam:11000010abcdef atmsystem.admin
add_principal group.admin atmsystem.admin
```

## Configuration

All settings are in `shared/config.lua`:

| Setting | Default | Description |
|---------|---------|-------------|
| `Config.StartingBalance` | `5000` | Bank balance for new players |
| `Config.StartingCash` | `500` | Wallet cash for new players |
| `Config.ATMRange` | `2.0` | Interaction distance (meters) |
| `Config.ATMKey` | `38` | Interaction key (E) |
| `Config.Transactions.maxWithdrawal` | `50000` | Max per withdrawal |
| `Config.Transactions.maxDeposit` | `500000` | Max per deposit |
| `Config.Transactions.transferFee` | `0.5` | Transfer fee percentage |
| `Config.ATMFee.amount` | `2.50` | Flat ATM withdrawal fee |
| `Config.AntiAbuse.cooldown` | `3` | Seconds between ATM uses |
| `Config.AntiAbuse.rateLimit` | `10` | Max transactions per minute |
| `Config.AntiAbuse.maxHistory` | `50` | Stored transaction records |
| `Config.Interest.enabled` | `false` | Enable interest system |
| `Config.Interest.rate` | `0.5` | Interest rate per cycle |
| `Config.Interest.interval` | `1440` | Interest cycle in minutes (24h) |
| `Config.Storage` | `'json'` | 'json' or 'oxmysql' |

## Commands

### Player Commands

| Command | Description | Example |
|---------|-------------|---------|
| `/balance` | Check bank and cash balance | `/balance` |
| `/cash` | Same as balance (alias) | `/cash` |
| `/transfer [id] [amount]` | Transfer bank money to another player | `/transfer 5 1000` |
| `/givecash [id] [amount]` | Give cash to a nearby player | `/givecash 5 200` |

### Admin Commands

| Command | Permission | Description |
|---------|-----------|-------------|
| `/bank [id]` | `atmsystem.admin` | View a player's balances |
| `/setmoney [id] [type] [amount]` | `atmsystem.admin` | Set a player's bank or cash |

**Example:**
```
/bank 5                    — View player 5's balance
/setmoney 5 bank 50000     — Set player 5's bank to $50,000
/setmoney 5 cash 5000      — Set player 5's cash to $5,000
```

## ATM Locations

ATMs are GTA V props — the system detects them automatically. You don't need to place them manually. The following ATM props are supported:

| Prop Model | Location |
|------------|----------|
| `prop_atm_01` | Standard ATM (blue/gray) |
| `prop_atm_02` | Wall-mounted ATM |
| `prop_atm_03` | Pillar ATM |
| `prop_fleeca_extrn` | Fleeca Bank exterior |

Bank blips are configured in `Config.BankBlips`. Edit or add entries as needed.

## File Structure

```
gameplay-atmsystem/
├── fxmanifest.lua          — Resource manifest
├── shared/
│   ├── config.lua          — All configurable settings
│   └── util.lua             — Shared utilities (formatting, validation, localization)
├── client/
│   ├── main.lua             — Chat command registration
│   ├── atm.lua              — ATM detection, interaction, menu
│   ├── notify.lua            — Notification wrapper
│   └── blips.lua             — Bank map blips
├── server/
│   ├── main.lua             — Event handlers, commands, admin tools
│   ├── database.lua          — Storage layer (JSON or oxmysql)
│   └── transactions.lua      — Core transaction logic
├── sql/
│   └── schema.sql           — Database schema for oxmysql mode
├── README.md               — This file
├── USER_GUIDE.md            — End-user guide
├── CHANGELOG.md             — Version history
└── LICENSE                  — MIT license
```

## Exports (for other resources)

### Server-side

```lua
-- Get a player's balance
local balance = exports['gameplay-atmsystem']:getBalance(playerId)
-- Returns: { bank = 5000, cash = 500, accountNumber = "FLE1234567890" }

-- Add money to a player's account
exports['gameplay-atmsystem']:addMoney(playerId, 'bank', 1000)
exports['gameplay-atmsystem']:addMoney(playerId, 'cash', 500)

-- Remove money from a player's account
local success = exports['gameplay-atmsystem']:removeMoney(playerId, 'bank', 1000)
-- Returns false if insufficient balance

-- Get transaction history
local history = exports['gameplay-atmsystem']:getHistory(playerId)
```

## Integration Examples

### Paying a player for a job

```lua
-- In your job resource:
RegisterNetEvent('myjob:server:payout', function()
    local source = source
    exports['gameplay-atmsystem']:addMoney(source, 'bank', 2500)
    TriggerClientEvent('atmsystem:client:notify', source, 'You earned $2,500 for completing the delivery!', 'success')
end)
```

### Charging a player for a service

```lua
-- In your shop resource:
local success = exports['gameplay-atmsystem']:removeMoney(playerId, 'cash', 100)
if not success then
    TriggerClientEvent('atmsystem:client:notify', playerId, 'Not enough cash.', 'error')
end
```

## FAQ

**Q: Does this work without ox_lib and oxmysql?**
A: Yes. JSON storage is used by default, and native GTA V notifications work without ox_lib.

**Q: Can I use this alongside ESX or QBCore?**
A: Yes. ATM System is standalone. It doesn't conflict with framework money systems. If you want to sync with ESX/QBCore money, use the exports from your framework's scripts.

**Q: How do I change the starting balance?**
A: Edit `Config.StartingBalance` in `shared/config.lua`.

**Q: Can I disable ATM fees?**
A: Yes. Set `Config.ATMFee.enabled = false`.

**Q: Where is the data stored in JSON mode?**
A: In `atm_system_data.json` inside the resource folder. The file is auto-created on first use.

**Q: How do I enable interest?**
A: Set `Config.Interest.enabled = true` and configure the rate and interval.

## Credits

- **Author:** Franklin Bryant IV
- **License:** MIT
- **Contact:** [GitHub](https://github.com/franklinbryant/cfx-portfolio)

## License

MIT License — see [LICENSE](LICENSE) for full text.