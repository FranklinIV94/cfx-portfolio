-- ═══════════════════════════════════════════════════════════════════════════════
-- ATM System — Shared Utilities
-- shared/util.lua
-- ═══════════════════════════════════════════════════════════════════════════════

Util = {}

--- Format a number as currency string.
--- @param amount number The amount to format
--- @return string formatted
function Util.FormatMoney(amount)
    local formatted = tostring(amount)
    -- Add thousands separators
    formatted = string.reverse(formatted)
    formatted = string.gsub(formatted, '(%d%d%d)', '%1,')
    formatted = string.reverse(formatted)
    -- Remove leading comma if present
    formatted = string.gsub(formatted, '^,', '')
    return Config.Currency .. formatted
end

--- Generate a random account number.
--- @return string accountNumber
function Util.GenerateAccountNumber()
    local num = ''
    for _ = 1, 10 do
        num = num .. math.random(0, 9)
    end
    return 'FLE' .. num
end

--- Validate that an amount is within allowed bounds.
--- @param amount number
--- @return boolean valid, string|nil error
function Util.ValidateAmount(amount)
    if type(amount) ~= 'number' or amount ~= amount then -- NaN check
        return false, 'Invalid amount'
    end
    if amount < Config.Transactions.minAmount then
        return false, string.format('Minimum amount is %s', Util.FormatMoney(Config.Transactions.minAmount))
    end
    if amount > Config.Transactions.maxAmount then
        return false, string.format('Maximum amount is %s', Util.FormatMoney(Config.Transactions.maxAmount))
    end
    return true
end

--- Calculate transfer fee.
--- @param amount number The transfer amount
--- @return number fee
function Util.CalculateTransferFee(amount)
    if not Config.Transactions.transferFee or Config.Transactions.transferFee <= 0 then
        return 0
    end
    return math.floor(amount * (Config.Transactions.transferFee / 100))
end

--- Truncate a string to a maximum length.
--- @param str string
--- @param maxLen number
--- @return string
function Util.Truncate(str, maxLen)
    if #str <= maxLen then return str end
    return string.sub(str, 1, maxLen - 3) .. '...'
end

--- Localized strings
Util.Locales = {
    ['en'] = {
        ['resource_disabled']   = 'ATM System is currently disabled.',
        ['no_atm_nearby']       = 'No ATM nearby. Find an ATM to interact.',
        ['atm_prompt']          = 'Press [E] to use ATM',
        ['withdraw_success']     = 'Withdrew %s from your account. Fee: %s',
        ['withdraw_fail']       = 'Insufficient bank balance. Available: %s',
        ['withdraw_limit']      = 'Maximum withdrawal is %s per transaction.',
        ['deposit_success']     = 'Deposited %s to your account.',
        ['deposit_fail']         = 'You do not have enough cash. Wallet: %s',
        ['deposit_limit']       = 'Maximum deposit is %s per transaction.',
        ['transfer_success']    = 'Transferred %s to %s (Fee: %s)',
        ['transfer_fail']       = 'Insufficient bank balance for transfer.',
        ['transfer_self']       = 'You cannot transfer money to yourself.',
        ['transfer_invalid']    = 'Target player not found or not online.',
        ['givecash_success']    = 'Gave %s to %s',
        ['givecash_fail']       = 'You do not have enough cash. Wallet: %s',
        ['givecash_self']      = 'You cannot give cash to yourself.',
        ['balance_bank']        = 'Bank Balance: %s',
        ['balance_cash']        = 'Wallet Cash: %s',
        ['balance_both']        = 'Bank: %s | Cash: %s',
        ['cooldown']            = 'Please wait a moment before using the ATM again.',
        ['rate_limited']        = 'Too many transactions. Please slow down.',
        ['invalid_amount']      = 'Invalid amount. Enter a positive number.',
        ['min_amount']          = 'Minimum amount is %s',
        ['max_amount']          = 'Maximum amount is %s',
        ['no_permission']       = 'You do not have permission to use this command.',
        ['player_not_found']    = 'Player not found. Are they online?',
        ['fee_charged']         = 'ATM fee charged: %s',
        ['overdraft_denied']    = 'Transaction denied: insufficient funds (overdraft not enabled).',
        ['account_number']     = 'Account: %s',
        ['menu_title']         = 'Fleeca Bank ATM',
        ['menu_withdraw']      = 'Withdraw Cash',
        ['menu_deposit']       = 'Deposit Cash',
        ['menu_transfer']      = 'Transfer to Player',
        ['menu_balance']       = 'Check Balance',
        ['menu_history']       = 'Transaction History',
        ['menu_exit']          = 'Exit',
        ['enter_amount']       = 'Enter amount:',
        ['enter_target']       = 'Enter player ID to transfer to:',
        ['no_history']         = 'No transactions yet.',
        ['interest_paid']      = 'Interest earned: %s',
        ['admin_view']         = '[Admin] %s (ID: %s) — Bank: %s | Cash: %s',
        ['admin_set']          = '[Admin] Set %s\'s %s to %s',
        ['usage_transfer']     = 'Usage: /%s [playerId] [amount]',
        ['usage_givecash']    = 'Usage: /%s [playerId] [amount]',
        ['usage_bank']         = 'Usage: /%s [playerId]',
        ['usage_setmoney']    = 'Usage: /%s [playerId] [bank|cash] [amount]',
    },
    ['es'] = {
        ['resource_disabled']   = 'El sistema ATM está deshabilitado.',
        ['no_atm_nearby']       = 'No hay un ATM cerca.',
        ['atm_prompt']          = 'Presiona [E] para usar el ATM',
        ['withdraw_success']     = 'Retiraste %s. Comisión: %s',
        ['withdraw_fail']       = 'Saldo insuficiente. Disponible: %s',
        ['withdraw_limit']      = 'Retiro máximo: %s',
        ['deposit_success']     = 'Depositaste %s',
        ['deposit_fail']        = 'No tienes suficiente efectivo. Cartera: %s',
        ['deposit_limit']       = 'Depósito máximo: %s',
        ['transfer_success']    = 'Transferiste %s a %s (Comisión: %s)',
        ['transfer_fail']       = 'Saldo insuficiente para transferir.',
        ['transfer_self']       = 'No puedes transferirte dinero a ti mismo.',
        ['transfer_invalid']    = 'Jugador no encontrado o no conectado.',
        ['givecash_success']    = 'Le diste %s a %s',
        ['givecash_fail']        = 'No tienes suficiente efectivo. Cartera: %s',
        ['givecash_self']       = 'No puedes darte efectivo a ti mismo.',
        ['balance_bank']        = 'Saldo bancario: %s',
        ['balance_cash']        = 'Efectivo: %s',
        ['balance_both']        = 'Banco: %s | Efectivo: %s',
        ['cooldown']            = 'Espera un momento antes de usar el ATM nuevamente.',
        ['rate_limited']        = 'Demasiadas transacciones. Ve más despacio.',
        ['invalid_amount']      = 'Cantidad inválida.',
        ['no_permission']       = 'No tienes permiso.',
        ['player_not_found']    = 'Jugador no encontrado.',
        ['fee_charged']         = 'Comisión ATM: %s',
        ['menu_title']          = 'ATM Banco Fleeca',
        ['menu_withdraw']       = 'Retirar',
        ['menu_deposit']        = 'Depositar',
        ['menu_transfer']       = 'Transferir',
        ['menu_balance']        = 'Ver Saldo',
        ['menu_history']        = 'Historial',
        ['menu_exit']           = 'Salir',
    },
}

function Util.L(key, ...)
    local lang = Config.Language or 'en'
    local str = (Util.Locales[lang] and Util.Locales[lang][key]) or Util.Locales['en'][key] or key
    if select('#', ...) > 0 then
        return string.format(str, ...)
    end
    return str
end