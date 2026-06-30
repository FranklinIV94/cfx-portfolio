-- ═══════════════════════════════════════════════════════════════════════════════
-- ATM System — Database Schema (for oxmysql storage mode)
-- sql/schema.sql
--
-- Run this if you're using Config.Storage = 'oxmysql'
-- Import: mysql -u root -p your_database < sql/schema.sql
-- Or via oxmysql: execute in your SQL tool of choice
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS `atm_system_accounts` (
    `identifier` VARCHAR(60) PRIMARY KEY,
    `bank_balance` DOUBLE DEFAULT 0,
    `cash_balance` DOUBLE DEFAULT 0,
    `account_number` VARCHAR(20),
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS `atm_system_transactions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `identifier` VARCHAR(60) NOT NULL,
    `type` VARCHAR(20) NOT NULL,
    `amount` DOUBLE NOT NULL,
    `balance_after` DOUBLE NOT NULL,
    `target_identifier` VARCHAR(60) NULL,
    `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_identifier` (`identifier`),
    INDEX `idx_type` (`type`),
    INDEX `idx_timestamp` (`timestamp`),
    CONSTRAINT `fk_atm_account` FOREIGN KEY (`identifier`)
        REFERENCES `atm_system_accounts` (`identifier`)
        ON DELETE CASCADE
);