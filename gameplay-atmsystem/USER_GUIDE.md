# ATM System — User Guide

A practical guide for server owners and players using the ATM System.

---

## For Server Owners

### Quick Start (No Dependencies)

1. Drop `gameplay-atmsystem` into `resources/[local]/`
2. Add `ensure gameplay-atmsystem` to `server.cfg`
3. Restart your server
4. Players can immediately walk up to any ATM in GTA V and press [E]

### Setting Up Database Storage (oxmysql)

1. Import `sql/schema.sql` into your database:
   ```bash
   mysql -u root -p your_db < resources/[local]/gameplay-atmsystem/sql/schema.sql
   ```
2. Change `Config.Storage = 'oxmysql'` in `shared/config.lua`
3. Ensure oxmysql loads before ATM System in `server.cfg`:
   ```cfg
   ensure oxmysql
   ensure gameplay-atmsystem
   ```

### Setting Up Admin Permissions

In `server.cfg`:
```cfg
# Individual player
add_principal identifier.steam:11000010abcdef atmsystem.admin

# Or use an existing admin group (vMenu, EasyAdmin, etc.)
add_principal group.admin atmsystem.admin
```

Admins can then use:
- `/bank [playerId]` — View any player's balance
- `/setmoney [playerId] [bank|cash] [amount]` — Set a player's money

### Customizing ATM Fees

```lua
Config.ATMFee = {
    enabled = true,
    amount = 2.50,  -- $2.50 flat fee per ATM withdrawal
}
```

Set `enabled = false` to disable fees entirely.

### Enabling Interest

```lua
Config.Interest = {
    enabled = true,
    rate = 0.5,     -- 0.5% interest
    interval = 1440, -- Every 24 hours
    maxBalance = 5000000, -- Interest only on first $5M
}
```

Interest is paid automatically to all online players with a positive bank balance.

### Customizing Transfer Fees

```lua
Config.Transfers.transferFee = 0.5  -- 0.5% fee on transfers
```

Set to `0` to disable transfer fees.

### Enabling Overdraft

```lua
Config.Overdraft = {
    enabled = true,
    limit = -500,  -- Players can go up to -$500
}
```

### Integrating with Other Resources

ATM System provides server-side exports for other resources:

```lua
-- Add money (for job payouts, rewards, etc.)
exports['gameplay-atmsystem']:addMoney(playerId, 'bank', 5000)
exports['gameplay-atmsystem']:addMoney(playerId, 'cash', 500)

-- Remove money (for purchases, fines, etc.)
local success = exports['gameplay-atmsystem']:removeMoney(playerId, 'cash', 100)

-- Check balance
local balance = exports['gameplay-atmsystem']:getBalance(playerId)
print(balance.bank, balance.cash)

-- Get transaction history
local history = exports['gameplay-atmsystem']:getHistory(playerId)
```

### Adding More Bank Blips

```lua
Config.BankBlips = {
    { name = 'Fleeca Bank',     coords = vec3(150.0, -1040.0, 29.0) },
    { name = 'Fleeca Bank',     coords = vec3(-1212.0, -332.0, 37.0) },
    { name = 'Pacific Standard', coords = vec3(235.0, 216.0, 106.0) },
    -- Add more:
    { name = 'My Custom Bank',  coords = vec3(100.0, 200.0, 30.0) },
}
```

### Changing Commands

If commands conflict with other resources:

```lua
Config.Commands = {
    balance  = 'checkbalance',
    cash     = 'checkcash',
    transfer = 'banktransfer',
    givecash = 'handcash',
    bank     = 'checkbank',
    setmoney = 'setbank',
}
```

---

## For Players

### Using ATMs

1. **Find an ATM** — Look for ATM props near banks, stores, and gas stations. Bank blips appear on your map.
2. **Walk up to it** — Stand within 2 meters of the ATM
3. **Press [E]** — The ATM menu opens
4. **Choose an action:**
   - **Check Balance** — See your bank and cash totals
   - **Withdraw** — Take money from your bank account as cash
   - **Deposit** — Put cash into your bank account
   - **Transfer** — Send money to another player's bank account
   - **Transaction History** — View your recent transactions

### Chat Commands

| Command | What it does |
|---------|-------------|
| `/balance` | Shows your bank and cash balance |
| `/transfer [player ID] [amount]` | Sends money from your bank to their bank |
| `/givecash [player ID] [amount]` | Hands cash to a nearby player |

### Example: Transfer Money to Another Player

1. Find the other player's server ID (shown when they talk, or via `/ids`)
2. Type: `/transfer 5 1000`
3. Player 5 receives $1,000 in their bank account
4. A small transfer fee is deducted (0.5% by default)

### Example: Give Cash to Someone Next to You

1. Stand near the person you want to give cash to
2. Type: `/givecash 5 200`
3. Player 5 receives $200 in cash
4. You must be within 10 meters of them

### Understanding Fees

| Transaction | Fee |
|------------|-----|
| ATM Withdrawal | $2.50 flat fee |
| Bank Transfer | 0.5% of transfer amount |
| Cash Deposit | Free |
| Cash Giving | Free |
| Interest (if enabled) | Earns 0.5% every 24h |

### Reading Your Balance

When you check your balance, you'll see:
```
Bank: $5,000 | Cash: $500
Account: FLE1234567890
```

- **Bank** — Money stored in your bank account (safe, used for transfers)
- **Cash** — Physical money in your wallet (used for in-person transactions)
- **Account** — Your unique account number (for identification)

### Transaction History

View your last 50 transactions through the ATM menu. Each entry shows:
- Transaction type (deposit, withdrawal, transfer, etc.)
- Amount
- Resulting balance
- Timestamp

---

## Troubleshooting

### "No ATM nearby"

ATMs are specific prop models in GTA V. You'll find them:
- Outside Fleeca Bank branches
- Near 24/7 convenience stores
- At gas stations
- Inside some businesses

Look for the blue/gray ATM machines. Bank blips on your map show bank locations (ATMs are usually nearby).

### "Insufficient bank balance"

You tried to withdraw or transfer more than you have in your bank account. Check your balance first with `/balance`.

### "You do not have enough cash"

You tried to deposit or give more cash than you have in your wallet. Cash is separate from bank balance.

### "Too many transactions. Please slow down."

You've hit the rate limit (10 transactions per minute). Wait a minute and try again. This prevents abuse.

### "Player not found"

The player ID you entered is either invalid or that player is offline. Check that you have the right ID.

### Transfer fee seems too high

The default transfer fee is 0.5%. On a $10,000 transfer that's $50. You can ask the server owner to lower or disable it.

### Admin commands not working

Make sure you have the `atmsystem.admin` ACE permission. Ask an admin to assign it to you.

### Data not persisting after restart

If using JSON mode, the data file is auto-saved every 5 minutes and on disconnect. If using oxmysql, ensure the database is properly configured.

### ATM menu doesn't appear when pressing E

1. Make sure you're standing close enough to the ATM (within 2 meters)
2. Try walking away and coming back
3. If using ox_lib, ensure it's running — the menu uses context menus
4. Without ox_lib, the system falls back to text notifications

---

## Best Practices for Server Owners

1. **Start with JSON mode** — Test before switching to database
2. **Set reasonable fees** — $2.50 ATM fee is realistic; don't set it too high
3. **Enable interest cautiously** — Even 0.5% can inflate your economy over time
4. **Use rate limits** — 10 transactions/minute is a good default
5. **Log transactions** — Keep `Config.AntiAbuse.logging = true` for audit trails
6. **Give admins tools** — Ensure they have the `atmsystem.admin` permission
7. **Set starting balance wisely** — $5,000 is good for new servers; adjust based on your economy
8. **Use exports for jobs** — Pay players through exports instead of direct money manipulation