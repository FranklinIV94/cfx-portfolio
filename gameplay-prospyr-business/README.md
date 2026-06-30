# Prospyr Business Manager

A full in-game business management system for FiveM roleplay servers. Create businesses, manage employees, track finances, and run payroll — all from a modern in-game dashboard.

## Features

- **Business Creation** — 6 pre-configured types (restaurant, store, mechanic, barber, gas station, general) with custom blips
- **Employee Management** — hire, fire, role assignment, salary configuration per employee
- **Financial Dashboard** — balance, revenue, expenses, transaction history with pagination
- **Deposit/Withdraw** — owner-controlled fund management with full audit trail
- **Automated Payroll** — configurable payroll cycles with tax rate, automatic salary distribution
- **Admin Panel** — server admins can view all businesses, financial summaries, and delete businesses
- **Map Blips** — automatic blip creation at business locations with type-based icons
- **Permission System** — role-based access control (owner, manager, employee) with configurable permissions
- **NUI Dashboard** — modern dark-themed web UI with tabs, tables, modals, and real-time updates
- **Database-Backed** — full oxmysql integration with normalized schema and foreign key cascading

## Requirements

- FiveM server (artifact 12000+)
- [ox_lib](https://github.com/overextended/ox_lib) — UI utilities and callbacks
- [oxmysql](https://github.com/overextended/oxmysql) — database operations
- MySQL/MariaDB database

## Installation

See [MANUAL.md](MANUAL.md) for complete installation and configuration guide.

## Usage

See [USERGUIDE.md](USERGUIDE.md) for player-facing documentation.

## Architecture

```
prospyr-business-manager/
├── fxmanifest.lua              # Resource manifest
├── config/
│   └── config.lua              # All configuration (types, permissions, payroll, UI)
├── client/
│   ├── main.lua                # Entry point, commands, NUI callbacks, exports
│   ├── dashboard.lua            # NUI open/close, tab routing, auto-refresh
│   ├── business.lua            # Blips, creation flow, location selection
│   └── employees.lua           # Employee notifications, hire/fire events
├── server/
│   ├── main.lua                # Init, player data, payroll loop, exports
│   ├── business.lua            # Create, delete, deposit, withdraw, transactions
│   ├── employees.lua           # Hire, fire, role/salary updates
│   └── finance.lua              # Admin panel, financial summaries, external exports
├── html/
│   ├── index.html              # NUI structure (tabs, panels, modals)
│   ├── style.css               # Dark theme (CSS variables, Grid, Flexbox)
│   └── app.js                  # Message routing, rendering, event handlers
└── sql/
    └── schema.sql              # Database schema (3 tables)
```

## Configuration

All settings are in `config/config.lua`:

| Setting | Description | Default |
|---|---|---|
| `Config.BusinessTypes` | Available business types with labels, blips, roles | 6 types |
| `Config.Payroll` | Payroll cycle interval, tax rate, minimum balance | 30 min, 10% tax |
| `Config.Permissions` | Role-based permissions (owner, manager, employee) | See file |
| `Config.DefaultSalaries` | Default salary per role per payroll cycle | $100-$500 |
| `Config.Admin` | Admin groups, creation/deletion permissions | admin, superadmin |
| `Config.UI` | Command name, keybind, refresh interval | /business, F6, 5s |
| `Config.Blips` | Blip visibility, scale, display flags | Shown, 0.8 scale |

## Exports

### Server Exports

| Export | Parameters | Returns | Description |
|---|---|---|---|
| `GetBusinesses` | `cid: string` | `table` | Get all businesses owned by a player |
| `CreateBusiness` | `name, type, ownerCid, balance` | `int` | Create a business programmatically |
| `GetEmployees` | `businessId: int` | `table` | Get active employees for a business |
| `GetFinancialSummary` | `businessId: int` | `table` | Financial summary + transaction stats |
| `GetPlayerBusinesses` | `cid: string` | `table` | Same as GetBusinesses (alias) |
| `AddRevenue` | `businessId, amount, description, source` | `boolean` | Add revenue to a business |
| `AddExpense` | `businessId, amount, description, source` | `boolean` | Add expense to a business |

### Client Exports

| Export | Parameters | Returns | Description |
|---|---|---|---|
| `GetBusinesses` | — | `table` | Returns current player's business list |

## Database Schema

Three tables with foreign key relationships:

- **prospyr_businesses** — business records (name, type, owner, balance, revenue, expenses, blip coords)
- **prospyr_employees** — employee records (business_id, citizenid, role, salary, active)
- **prospyr_transactions** — transaction log (business_id, type, amount, description, performed_by)

All tables cascade on business deletion. Schema file: `sql/schema.sql`.

## Compatibility

- **Frameworks:** Framework-agnostic — uses license identifier for player identification (works with qb-core, ESX, standalone)
- **Database:** oxmysql (required)
- **UI:** Pure HTML/CSS/JS NUI — no React, no build step, no dependencies

## License

MIT — Free to use, modify, and distribute. Attribution appreciated.

## Author

**Prospyr 305** — [Prospyr 305](https://github.com/prospyr305)