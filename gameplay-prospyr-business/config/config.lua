Config = {}

-- ═════════════════════════════════════════════════════════════════════
-- Prospyr Business Manager — Configuration
-- ═════════════════════════════════════════════════════════════════════

-- Business types available for creation
-- Each type defines: label, default balance, blip sprite, blip color
Config.BusinessTypes = {
    ['restaurant'] = {
        label = 'Restaurant',
        defaultBalance = 5000,
        blipSprite = 273,
        blipColor = 2,
        roles = { 'owner', 'manager', 'cook', 'waiter', 'cashier' },
    },
    ['store'] = {
        label = 'Convenience Store',
        defaultBalance = 3000,
        blipSprite = 52,
        blipColor = 3,
        roles = { 'owner', 'manager', 'cashier', 'stocker' },
    },
    ['mechanic'] = {
        label = 'Auto Shop',
        defaultBalance = 5000,
        blipSprite = 446,
        blipColor = 5,
        roles = { 'owner', 'manager', 'mechanic', 'apprentice' },
    },
    ['barber'] = {
        label = 'Barber Shop',
        defaultBalance = 3000,
        blipSprite = 71,
        blipColor = 4,
        roles = { 'owner', 'manager', 'barber' },
    },
    ['gas_station'] = {
        label = 'Gas Station',
        defaultBalance = 4000,
        blipSprite = 361,
        blipColor = 6,
        roles = { 'owner', 'manager', 'attendant' },
    },
    ['general'] = {
        label = 'General Business',
        defaultBalance = 2000,
        blipSprite = 1,
        blipColor = 1,
        roles = { 'owner', 'manager', 'employee' },
    },
}

-- Payroll settings
Config.Payroll = {
    enabled = true,
    interval = 30,          -- minutes between payroll cycles
    taxRate = 0.10,          -- 10% tax on payroll
    minBalance = 100,        -- business must have at least this much to pay
}

-- Financial settings
Config.Finance = {
    maxTransactionLog = 500,  -- keep last N transactions per business
    currencyFormat = '$%s',   -- display format
    startingRevenue = 0,
}

-- Permissions by role
Config.Permissions = {
    owner = {
        canManageEmployees = true,
        canManageFinances = true,
        canEditBusiness = true,
        canDeleteBusiness = true,
        canViewDashboard = true,
        canWithdraw = true,
        canDeposit = true,
        payrollAccess = true,
    },
    manager = {
        canManageEmployees = true,
        canManageFinances = false,
        canEditBusiness = false,
        canDeleteBusiness = false,
        canViewDashboard = true,
        canWithdraw = false,
        canDeposit = true,
        payrollAccess = false,
    },
    employee = {
        canManageEmployees = false,
        canManageFinances = false,
        canEditBusiness = false,
        canDeleteBusiness = false,
        canViewDashboard = false,
        canWithdraw = false,
        canDeposit = false,
        payrollAccess = false,
    },
}

-- Default salaries by role (per payroll cycle, in dollars)
Config.DefaultSalaries = {
    owner = 500,
    manager = 300,
    cook = 150,
    waiter = 120,
    cashier = 130,
    stocker = 110,
    mechanic = 200,
    apprentice = 100,
    barber = 180,
    attendant = 110,
    employee = 120,
}

-- Admin settings
Config.Admin = {
    -- Groups that can access the admin panel
    allowedGroups = { 'admin', 'superadmin' },
    -- Can admins create businesses for other players?
    canCreateForOthers = true,
    -- Can admins delete any business?
    canDeleteAny = true,
}

-- NUI settings
Config.UI = {
    command = 'business',       -- command to open dashboard
    keybind = 'F6',              -- default keybind
    refreshInterval = 5000,      -- ms between auto-refreshes when open
}

-- Blip settings
Config.Blips = {
    showBlips = true,            -- show business blips on map
    blipScale = 0.8,
    blipDisplay = 4,              -- shown on both main map and minimap
}