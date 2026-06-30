# Prospyr Business Manager — Player Guide

**Welcome to Business Manager!** This guide covers everything players need to create and run businesses in-game.

---

## Getting Started

Press **F6** (default) or type `/business` in chat to open the Business Dashboard.

The dashboard has four tabs:
- **My Businesses** — view and select your businesses
- **Employees** — manage your workforce
- **Finance** — deposits, withdrawals, transaction history
- **Create Business** — start a new business

---

## Creating a Business

1. Open the dashboard (F6) and go to the **Create Business** tab
2. Enter a **Business Name** (e.g., "Downtown Diner")
3. Select a **Business Type** from the dropdown:
   - Restaurant
   - Convenience Store
   - Auto Shop
   - Barber Shop
   - Gas Station
   - General Business
4. Click **Create Business**

Your new business starts with a default balance (varies by type). A map blip is placed at your current location so customers can find you.

---

## Managing Your Business

### Selecting a Business

On the **My Businesses** tab, click any business card to select it. The Employees and Finance tabs will show data for the selected business.

### Checking Your Balance

The **Finance** tab shows:
- **Current Balance** — money in the business account
- **Total Revenue** — all money deposited/received
- **Total Expenses** — all money spent (withdrawals, payroll, expenses)

### Depositing Money

1. Go to the **Finance** tab
2. Enter the amount in the "Amount ($)" field
3. Optionally add a description (e.g., "Daily earnings")
4. Click **Deposit**

Deposits increase your business balance and revenue.

### Withdrawing Money

1. Go to the **Finance** tab
2. Enter the amount
3. Optionally add a description
4. Click **Withdraw**

Only the **business owner** can withdraw funds. Withdrawals are logged in the transaction history.

---

## Managing Employees

### Hiring

1. Go to the **Employees** tab
2. Click **+ Hire Employee**
3. Fill in the hire form:
   - **Player Name** — the in-game name of the player
   - **Citizen ID** — their license identifier (ask them or get from server admin)
   - **Role** — select from available roles for your business type
   - **Salary** — amount paid each payroll cycle (defaults to role standard)
4. Click **Hire**

The hired player will receive a notification that they've been hired.

### Firing

1. Go to the **Employees** tab
2. Find the employee in the table
3. Click **Fire** next to their name

The fired player will receive a notification. You cannot fire the business owner.

### Changing Roles

1. Go to the **Employees** tab
2. Click **Role** next to an employee
3. Enter the new role (must be a valid role for your business type)

Only the **owner** can change roles. Changing a role also updates the salary to the default for that role.

### Payroll

Payroll runs automatically based on the server's payroll settings (typically every 30 minutes).

- Each active employee receives their salary
- The business balance is reduced by total salaries + tax
- If the business doesn't have enough money, payroll fails and the owner is notified

Employees receive a notification when they're paid.

---

## Roles & Permissions

| Action | Owner | Manager | Employee |
|---|---|---|---|
| View Dashboard | ✅ | ✅ | ❌ |
| Hire/Fire | ✅ | ✅ | ❌ |
| Change Roles | ✅ | ❌ | ❌ |
| Change Salaries | ✅ | ❌ | ❌ |
| Deposit | ✅ | ✅ | ❌ |
| Withdraw | ✅ | ❌ | ❌ |
| Delete Business | ✅ | ❌ | ❌ |

---

## Transaction History

The **Finance** tab includes a full transaction log showing:
- **Date** — when the transaction occurred
- **Type** — deposit, withdrawal, payroll, revenue, or expense
- **Amount** — the dollar amount
- **Description** — what it was for
- **By** — who performed it

Transactions are paginated (25 per page) and kept for the lifetime of the business.

---

## Map Blips

When you create a business, a blip appears on the map at your current location. The blip icon and color match your business type:

| Type | Icon | Color |
|---|---|---|
| Restaurant | Fork & Knife | Green |
| Store | Shopping Cart | Blue |
| Auto Shop | Wrench | Yellow |
| Barber | Scissors | Purple |
| Gas Station | Gas Pump | Orange |
| General | Default Dot | White |

---

## Tips for Server Owners

- **Starting balance:** Each business type has a different default balance. Adjust in the config.
- **Payroll tax:** The tax rate reduces the business balance beyond just salaries. Set to 0 for no tax.
- **Custom roles:** Add roles to business types in the config and set their permissions and default salaries.
- **External integration:** Other resources can add revenue/expenses via server exports. See the MANUAL.md for API details.
- **Admin panel:** Server admins can view all businesses and delete problematic ones via the Admin tab.

---

## FAQ

**Q: Can I own multiple businesses?**  
A: Yes! Create as many as you want. Each appears as a separate card on the "My Businesses" tab.

**Q: What happens to employees when I delete my business?**  
A: All employees are automatically deactivated and all transactions are deleted (database cascade).

**Q: Can I change my business type after creation?**  
A: No. Business type is permanent. Delete and recreate if you need a different type.

**Q: My payroll failed. Why?**  
A: Your business balance was too low. The business needs at least the total of all salaries plus tax. Deposit more money and wait for the next payroll cycle.

**Q: Can employees see the business finances?**  
A: Only the owner and managers can view the finance tab. Regular employees cannot.

**Q: How do I find someone's Citizen ID to hire them?**  
A: Ask them to run `/business` — their Citizen ID is displayed when the dashboard initializes. Or ask a server admin to look it up.

---

*Prospyr Business Manager — Built by Prospyr 305*