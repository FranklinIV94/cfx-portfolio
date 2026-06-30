-- ═════════════════════════════════════════════════════════════════════
-- Prospyr Business Manager — Database Schema
-- Run this in your server's MySQL/MariaDB database.
-- ═════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS `prospyr_businesses` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL,
    `type` VARCHAR(50) NOT NULL,
    `owner_cid` VARCHAR(50) NOT NULL,
    `balance` DECIMAL(15,2) DEFAULT 0.00,
    `revenue` DECIMAL(15,2) DEFAULT 0.00,
    `expenses` DECIMAL(15,2) DEFAULT 0.00,
    `blip_coords` VARCHAR(100) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_owner` (`owner_cid`),
    INDEX `idx_type` (`type`)
);

CREATE TABLE IF NOT EXISTS `prospyr_employees` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `business_id` INT NOT NULL,
    `citizenid` VARCHAR(50) NOT NULL,
    `player_name` VARCHAR(100) NOT NULL,
    `role` VARCHAR(50) NOT NULL DEFAULT 'employee',
    `salary` DECIMAL(10,2) DEFAULT 100.00,
    `hired_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `active` TINYINT(1) DEFAULT 1,
    FOREIGN KEY (`business_id`) REFERENCES `prospyr_businesses`(`id`) ON DELETE CASCADE,
    INDEX `idx_business` (`business_id`),
    INDEX `idx_citizen` (`citizenid`),
    UNIQUE KEY `uk_business_employee` (`business_id`, `citizenid`)
);

CREATE TABLE IF NOT EXISTS `prospyr_transactions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `business_id` INT NOT NULL,
    `type` ENUM('deposit', 'withdrawal', 'payroll', 'revenue', 'expense') NOT NULL,
    `amount` DECIMAL(15,2) NOT NULL,
    `description` VARCHAR(255) DEFAULT '',
    `performed_by` VARCHAR(50) NOT NULL,
    `performed_name` VARCHAR(100) DEFAULT '',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`business_id`) REFERENCES `prospyr_businesses`(`id`) ON DELETE CASCADE,
    INDEX `idx_business` (`business_id`),
    INDEX `idx_type` (`type`),
    INDEX `idx_date` (`created_at`)
);

-- Optional: seed data for testing
-- INSERT INTO `prospyr_businesses` (`name`, `type`, `owner_cid`, `balance`)
-- VALUES ('Test Diner', 'restaurant', 'ABC12345', 5000.00);