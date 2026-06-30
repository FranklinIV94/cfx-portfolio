# Prospyr Business Manager — Installation & Configuration Manual

**Version:** 1.0.0  
**Author:** Prospyr 305  
**License:** MIT

---

## Prerequisites

| Requirement | Minimum Version | Required |
|---|---|---|
| FiveM Server Artifact | 12000+ | ✅ Yes |
| ox_lib | 3.0+ | ✅ Yes |
| oxmysql | 2.0+ | ✅ Yes |
| MySQL/MariaDB | 5.7+ / 10.3+ | ✅ Yes |
| pma-voice | — | ❌ Optional |

Prospyr Business Manager is framework-agnostic. It uses the player's license identifier for identification, making it compatible with qb-core, ESX, or standalone servers.

---

## Installation

### Step 1: Database Setup

Run the schema file in your server's MySQL/MariaDB database:

```sql
-- Import the schema file
SOURCE /path/to/prospyr-business-manager/sql/schema.sql;
```

Or via command line:

```bash
mysql -u your_user -p your_database < sql/schema.sql
```

This creates three tables:
- `prospyr_businesses` — business records
- `prospyr_employees` — employee records
- `prospyr_transactions` — transaction log

All tables use InnoDB with foreign key cascading. Business deletion automatically cleans up employees and transactions.

### Step 2: Install Resource

Place the `prospyr-business-manager` folder in your server's `resources` directory:

```
resources/
└── prospyr-business-manager/
    ├── fxmanifest.lua
    ├── config/
    ├── client/
    ├── server/
    ├── html/
    └── sql/
```

### Step 3: Configure server.cfg

Ensure dependencies are started **before** Business Manager:

```cfg
ensure ox_lib
ensure oxmysql
ensure prospyr-business-manager
```

### Step 4: Verify Installation

1. Start your server
2. Check console for any errors
3. Join the server
4. Press **F6** (default) or type `/business` to open the dashboard
5. Navigate to "Create Business" tab to create your first business

---

## Configuration

### Business Types

Define available business types in `config/config.lua`:

```lua
Config.BusinessTypes = {
    ['restaurant'] = {
        label = 'Restaurant',
        defaultBalance = 5000,
        blipSprite = 273,
        blipColor = 2,
        roles = { 'owner', 'manager', 'cook', 'waiter', 'cashier' },
    },
    -- Add custom types here
    ['pharmacy'] = {
        label = 'Pharmacy',
        defaultBalance = 8000,
        blipSprite = 135,
        blipColor = 2,
        roles = { 'owner', 'manager', 'pharmacist', 'clerk' },
    },
}
```

Each type requires:
- `label` — display name
- `defaultBalance` — starting balance for new businesses
- `blipSprite` — FiveM blip sprite ID (see [blip reference](https://docs.fivem.net/docs/game-references/blips/))
- `blipColor` — blip color ID
- `roles` — available employee roles

### Payroll

```lua
Config.Payroll = {
    enabled = true,       -- set to false to disable automatic payroll
    interval = 30,        -- minutes between payroll cycles
    taxRate = 0.10,       -- 10% tax on total payroll
    minBalance = 100,    -- business must have this much to process payroll
}
```

Payroll automatically deducts total employee salaries + tax from the business balance. If the business has insufficient funds, payroll fails and the owner is notified.

### Permissions

Role-based permissions control what each role can do:

```lua
Config.Permissions = {
    owner = {
        canManageEmployees = true,
        canManageFinances = true,
        canWithdraw = true,
        canDeposit = true,
        -- ... see full list in config
    },
    manager = {
        canManageEmployees = true,  -- managers can hire/fire
        canWithdraw = false,         -- but can't withdraw
        -- ...
    },
    employee = {
        -- minimal permissions
    },
}
```

To add custom roles, add them to the business type's `roles` list and add a corresponding permissions entry.

### Default Salaries

```lua
Config.DefaultSalaries = {
    owner = 500,
    manager = 300,
    cook = 150,
    -- ...
}
```

Salaries are paid per payroll cycle. When hiring an employee, the salary defaults to the role's value. The owner can override individual salaries via the dashboard.

### Admin Access

```lua
Config.Admin = {
    allowedGroups = { 'admin', 'superadmin' },
    canCreateForOthers = true,
    canDeleteAny = true,
}
```

Admin access uses FiveM's Ace permission system. Ensure your admin group is properly configured in `server.cfg`:

```cfg
add_principal identifier.license:your_license_here group.admin
```

### UI Settings

```lua
Config.UI = {
    command = 'business',       -- chat command
    keybind = 'F6',              -- default key
    refreshInterval = 5000,      -- auto-refresh when dashboard is open (ms)
}
```

### Blip Settings

```lua
Config.Blips = {
    showBlips = true,
    blipScale = 0.8,
    blipDisplay = 4,  -- shown on main map and minimap
}
```

---

## Integration with Other Resources

Prospyr Business Manager provides server exports for other resources to interact with businesses:

### Add Revenue (e.g., from a shop script)

```lua
-- In another resource's server-side code
exports['prospyr-business-manager']:AddRevenue(businessId, amount, 'Shop sale', 'shop_system')
```

### Add Expense (e.g., rent payment)

```lua
exports['prospyr-business-manager']:AddExpense(businessId, 500, 'Weekly rent', 'rent_system')
```

### Check Player Businesses

```lua
local businesses = exports['prospyr-business-manager']:GetBusinesses(citizenid)
for _, biz in ipairs(businesses) do
    print(biz.name, biz.balance)
end
```

### Get Financial Summary

```lua
local summary = exports['prospyr-business-manager']:GetFinancialSummary(businessId)
-- Returns: { business = {...}, summary = { transaction_count, total_deposits, total_withdrawals, ... } }
```

---

## Troubleshooting

### Dashboard doesn't open
1. Check `server.cfg` has `ensure prospyr-business-manager` after `ox_lib` and `oxmysql`
2. Check console for Lua errors
3. Verify the keybind isn't conflicting with another resource
4. Try the command `/business` instead of the keybind

### "Business not found" error
1. Run `sql/schema.sql` to create database tables
2. Verify oxmysql is connected to your database
3. Check `server.cfg` has `@oxmysql/lib/MySQL.lua` in server_scripts (already in fxmanifest)

### Blips don't appear
1. Ensure `Config.Blips.showBlips = true`
2. Check that the business has `blip_coords` set (assigned during creation)
3. Verify blip sprite IDs are valid (1-826 for GTA V)

### Payroll not processing
1. Ensure `Config.Payroll.enabled = true`
2. Check that businesses have sufficient balance (`> Config.Payroll.minBalance`)
3. Review server console for MySQL errors during payroll
4. Payroll runs in a server thread — check for resource monitor errors if it stops

### Employees not showing
1. Verify the player was hired (check `prospyr_employees` table)
2. Ensure `active = 1` in the employee record
3. Check that the business ID matches

### Admin panel shows "Admin access required"
1. Verify the player is in an admin group: `add_principal identifier.license:XXX group.admin`
2. Check that `Config.Admin.allowedGroups` includes your group name
3. Use FiveM's `IsPlayerAceAllowed` test command to verify permissions

### NUI is blank or unstyled
1. Ensure `html/index.html`, `html/style.css`, and `html/app.js` are listed in `fxmanifest.lua files{}`
2. Clear server cache: `clearcache` in server.cfg or delete cache folder
3. Check browser dev tools (F12 in NUI) for console errors

---

## Database Maintenance

### Clean old transactions (keep last 500 per business)

```sql
DELETE FROM prospyr_transactions
WHERE id NOT IN (
    SELECT id FROM (
        SELECT id FROM prospyr_transactions t2
        WHERE t2.business_id = prospyr_transactions.business_id
        ORDER BY created_at DESC
        LIMIT 500
    ) AS keep_ids
);
```

### Archive inactive employees

```sql
UPDATE prospyr_employees
SET active = 0
WHERE active = 1
AND DATEDIFF(NOW(), hired_at) > 90
AND citizenid NOT IN (
    SELECT owner_cid FROM prospyr_businesses
);
```

---

## Uninstallation

1. Remove `ensure prospyr-business-manager` from `server.cfg`
2. Delete the `prospyr-business-manager` folder
3. Optionally drop database tables: `DROP TABLE prospyr_transactions, prospyr_employees, prospyr_businesses;`

---

## Support

- **Issues:** Report bugs on the Cfx Marketplace listing or GitHub
- **Compatibility:** Tested with FiveM artifact 12000+, ox_lib 3.0+, oxmysql 2.0+
- **Updates:** Check the Cfx Marketplace page for new versions

---

*Prospyr Business Manager — Built by Prospyr 305*