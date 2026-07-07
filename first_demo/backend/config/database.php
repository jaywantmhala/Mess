<?php
/**
 * Database Configuration — MySQL (visible in MySQL Workbench)
 * Connects to MySQL Server 8.0 running as Windows service.
 * Auto-creates the database and tables on first run.
 */

define('DB_HOST',    'localhost');
define('DB_PORT',    '3306');
define('DB_USER',    'root');
define('DB_PASS',    'root');         // ← your MySQL root password
define('DB_NAME',    'first_demo_db');
define('JWT_SECRET', 'first_demo_super_secret_jwt_key_2024_change_me');
define('JWT_EXPIRY', 86400);          // 24 hours

// Full path to mysql.exe — used for CLI operations in setup only
define('MYSQL_BIN',  'C:\\Program Files\\MySQL\\MySQL Server 8.0\\bin\\mysql.exe');

/**
 * Returns a PDO connection to MySQL.
 * Auto-creates the DB and tables if they don't exist.
 */
function getDBConnection(): PDO {
    // Connect without DB first so we can CREATE DATABASE
    try {
        $pdo = new PDO(
            "mysql:host=" . DB_HOST . ";port=" . DB_PORT . ";charset=utf8mb4",
            DB_USER,
            DB_PASS,
            [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES   => false,
            ]
        );
    } catch (PDOException $e) {
        http_response_code(500);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode([
            'success' => false,
            'message' => 'MySQL connection failed.',
            'error'   => $e->getMessage(),
            'hint'    => 'Check DB_HOST, DB_PORT, DB_USER, DB_PASS in config/database.php. Is MySQL80 service running?',
        ], JSON_PRETTY_PRINT);
        exit;
    }

    // Auto-create database
    $pdo->exec("CREATE DATABASE IF NOT EXISTS `" . DB_NAME . "`
                CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
    $pdo->exec("USE `" . DB_NAME . "`");

    // Auto-create tables
    createTables($pdo);

    return $pdo;
}

/**
 * Create all required tables if they don't already exist.
 */
function createTables(PDO $pdo): void {
    // Create customers table
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS `customers` (
            `id`              INT UNSIGNED  NOT NULL AUTO_INCREMENT,
            `full_name`       VARCHAR(150)  NOT NULL,
            `email`           VARCHAR(255)  NOT NULL,
            `password`        VARCHAR(255)  NOT NULL COMMENT 'bcrypt hashed password',
            `is_active`       TINYINT(1)    NOT NULL DEFAULT 1,
            `email_verified`  TINYINT(1)    NOT NULL DEFAULT 0,
            `profile_picture` VARCHAR(500)  DEFAULT NULL,
            `last_login_at`   DATETIME      DEFAULT NULL,
            `created_at`      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at`      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `uq_email` (`email`),
            KEY `idx_email_active` (`email`, `is_active`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
          COMMENT='Customer accounts for first_demo application'
    ");

    // Create vendors table
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS `vendors` (
            `id`              INT UNSIGNED  NOT NULL AUTO_INCREMENT,
            `full_name`       VARCHAR(150)  NOT NULL,
            `email`           VARCHAR(255)  NOT NULL,
            `password`        VARCHAR(255)  NOT NULL COMMENT 'bcrypt hashed password',
            `is_active`       TINYINT(1)    NOT NULL DEFAULT 1,
            `created_at`      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at`      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `uq_vendor_email` (`email`),
            KEY `idx_vendor_email_active` (`email`, `is_active`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
          COMMENT='Vendor accounts'
    ");

    // Drop hotels table if it contains the old contact_no column or lacks place_id
    try {
        $res = $pdo->query("SHOW TABLES LIKE 'hotels'")->fetch();
        if ($res) {
            $cols = $pdo->query("DESCRIBE hotels")->fetchAll(PDO::FETCH_COLUMN);
            if (in_array('contact_no', $cols) || !in_array('place_id', $cols)) {
                $pdo->exec("DROP TABLE IF EXISTS `hotels`");
            }
        }
    } catch (PDOException $e) {
        // Ignore errors during check, table will be created if not exists
    }

    // Create hotels table with new fields
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS `hotels` (
            `id`              INT UNSIGNED   NOT NULL AUTO_INCREMENT,
            `vendor_id`       INT UNSIGNED   NOT NULL,
            `hotel_name`      VARCHAR(150)   NOT NULL,
            `owner_name`      VARCHAR(150)   NOT NULL,
            `mobile_number`   VARCHAR(20)    NOT NULL,
            `email`           VARCHAR(255)   NOT NULL,
            `hotel_address`   TEXT           NOT NULL,
            `latitude`        DECIMAL(10,8)  NOT NULL,
            `longitude`       DECIMAL(11,8)  NOT NULL,
            `place_id`        VARCHAR(255)   DEFAULT NULL,
            `city`            VARCHAR(150)   DEFAULT NULL,
            `area`            VARCHAR(150)   DEFAULT NULL,
            `state`           VARCHAR(150)   DEFAULT NULL,
            `country`         VARCHAR(150)   DEFAULT NULL,
            `pincode`         VARCHAR(20)    DEFAULT NULL,
            `landmark`        VARCHAR(255)   DEFAULT NULL,
            `photo_url`       VARCHAR(500)   DEFAULT NULL,
            `created_at`      DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at`      DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `idx_hotel_vendor` (`vendor_id`),
            CONSTRAINT `fk_hotel_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
          COMMENT='Hotels owned by vendors with location storage'
    ");

    // Create menus table
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS `menus` (
            `id`              INT UNSIGNED   NOT NULL AUTO_INCREMENT,
            `hotel_id`        INT UNSIGNED   NOT NULL,
            `food_name`       VARCHAR(255)   NOT NULL,
            `description`     TEXT           DEFAULT NULL,
            `food_type`       VARCHAR(20)    NOT NULL COMMENT 'VEG or NON-VEG',
            `price`           DECIMAL(10,2)  NOT NULL DEFAULT 0.00,
            `original_price`  DECIMAL(10,2)  DEFAULT NULL,
            `spice_level`     VARCHAR(20)    DEFAULT 'NONE',
            `is_popular`      TINYINT(1)     NOT NULL DEFAULT 0,
            `is_available`    TINYINT(1)     NOT NULL DEFAULT 1,
            `image_url`       VARCHAR(500)   DEFAULT NULL,
            `menu_date`       DATE           NOT NULL,
            `created_at`      DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at`      DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `idx_menu_hotel` (`hotel_id`),
            KEY `idx_menu_date` (`menu_date`),
            CONSTRAINT `fk_menu_hotel` FOREIGN KEY (`hotel_id`) REFERENCES `hotels` (`id`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
          COMMENT='Daily food menus for hotels'
    ");

    // Add new columns to menus table if they don't exist
    try {
        $pdo->exec("ALTER TABLE `menus` ADD COLUMN `price` DECIMAL(10,2) NOT NULL DEFAULT 0.00");
    } catch (PDOException $e) {}
    try {
        $pdo->exec("ALTER TABLE `menus` ADD COLUMN `spice_level` VARCHAR(20) DEFAULT 'NONE'");
    } catch (PDOException $e) {}
    try {
        $pdo->exec("ALTER TABLE `menus` ADD COLUMN `is_popular` TINYINT(1) NOT NULL DEFAULT 0");
    } catch (PDOException $e) {}
    try {
        $pdo->exec("ALTER TABLE `menus` ADD COLUMN `is_available` TINYINT(1) NOT NULL DEFAULT 1");
    } catch (PDOException $e) {}

    // Create wallets table
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS `wallets` (
            `wallet_id`   INT UNSIGNED  NOT NULL AUTO_INCREMENT,
            `customer_id` INT UNSIGNED  NOT NULL,
            `balance`     DECIMAL(10,2) NOT NULL DEFAULT 0.00,
            `created_at`  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at`  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`wallet_id`),
            UNIQUE KEY `uq_wallet_customer` (`customer_id`),
            CONSTRAINT `fk_wallet_customer` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ");

    // Create wallet_transactions table
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS `wallet_transactions` (
            `id`            INT UNSIGNED  NOT NULL AUTO_INCREMENT,
            `wallet_id`     INT UNSIGNED  NOT NULL,
            `type`          VARCHAR(20)   NOT NULL,
            `amount`        DECIMAL(10,2) NOT NULL,
            `description`   VARCHAR(255)  DEFAULT NULL,
            `balance_after` DECIMAL(10,2) NOT NULL,
            `created_at`    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `idx_wallet_txn_wallet` (`wallet_id`),
            CONSTRAINT `fk_wallet_txn_wallet` FOREIGN KEY (`wallet_id`) REFERENCES `wallets` (`wallet_id`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ");

    // Create cart_items table
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS `cart_items` (
            `cart_item_id` INT UNSIGNED  NOT NULL AUTO_INCREMENT,
            `customer_id`  INT UNSIGNED  NOT NULL,
            `hotel_id`     INT UNSIGNED  NOT NULL,
            `menu_item_id` INT UNSIGNED  NOT NULL,
            `quantity`     INT UNSIGNED  NOT NULL DEFAULT 1,
            `created_at`   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at`   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`cart_item_id`),
            UNIQUE KEY `uq_customer_menu_item` (`customer_id`, `menu_item_id`),
            CONSTRAINT `fk_cart_customer` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE CASCADE,
            CONSTRAINT `fk_cart_hotel` FOREIGN KEY (`hotel_id`) REFERENCES `hotels` (`id`) ON DELETE CASCADE,
            CONSTRAINT `fk_cart_menu` FOREIGN KEY (`menu_item_id`) REFERENCES `menus` (`id`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ");

    // Create orders table
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS `orders` (
            `order_id`         INT UNSIGNED  NOT NULL AUTO_INCREMENT,
            `customer_id`      INT UNSIGNED  NOT NULL,
            `hotel_id`         INT UNSIGNED  NOT NULL,
            `subtotal`         DECIMAL(10,2) NOT NULL,
            `delivery_fee`     DECIMAL(10,2) NOT NULL DEFAULT 40.00,
            `tax_amount`       DECIMAL(10,2) NOT NULL,
            `grand_total`      DECIMAL(10,2) NOT NULL,
            `wallet_deducted`  DECIMAL(10,2) NOT NULL DEFAULT 0.00,
            `payment_method`   VARCHAR(50)   NOT NULL,
            `delivery_address` TEXT          NOT NULL,
            `status`           VARCHAR(50)   NOT NULL DEFAULT 'created_order',
            `created_at`       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at`       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`order_id`),
            CONSTRAINT `fk_order_customer` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE CASCADE,
            CONSTRAINT `fk_order_hotel` FOREIGN KEY (`hotel_id`) REFERENCES `hotels` (`id`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ");

    // Create order_items table
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS `order_items` (
            `order_item_id` INT UNSIGNED  NOT NULL AUTO_INCREMENT,
            `order_id`      INT UNSIGNED  NOT NULL,
            `menu_item_id`  INT UNSIGNED  NOT NULL,
            `quantity`      INT           NOT NULL,
            `price`         DECIMAL(10,2) NOT NULL,
            `created_at`    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`order_item_id`),
            CONSTRAINT `fk_order_item_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE CASCADE,
            CONSTRAINT `fk_order_item_menu` FOREIGN KEY (`menu_item_id`) REFERENCES `menus` (`id`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ");

    // Add original_price column to menus if it doesn't exist
    try {
        $pdo->exec("ALTER TABLE `menus` ADD COLUMN `original_price` DECIMAL(10,2) DEFAULT NULL");
    } catch (PDOException $e) {}

    // Update orders status column default to created_order for existing installations
    try {
        $pdo->exec("ALTER TABLE `orders` ALTER COLUMN `status` SET DEFAULT 'created_order'");
    } catch (PDOException $e) {}

    // Create drivers table
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS `drivers` (
            `id`              INT UNSIGNED  NOT NULL AUTO_INCREMENT,
            `full_name`       VARCHAR(150)  NOT NULL,
            `email`           VARCHAR(255)  NOT NULL,
            `password`        VARCHAR(255)  NOT NULL,
            `vehicle_number`  VARCHAR(50)   NOT NULL,
            `phone_number`    VARCHAR(20)   NOT NULL,
            `is_online`       TINYINT(1)    NOT NULL DEFAULT 0,
            `latitude`        DECIMAL(10,8) NOT NULL DEFAULT 18.5204,
            `longitude`       DECIMAL(11,8) NOT NULL DEFAULT 73.8567,
            `max_capacity`    INT           NOT NULL DEFAULT 3,
            `created_at`      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at`      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `uq_driver_email` (`email`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ");

    // Add driver_id column and foreign key to orders table
    try {
        $pdo->exec("ALTER TABLE `orders` ADD COLUMN `driver_id` INT UNSIGNED DEFAULT NULL");
    } catch (PDOException $e) {}

    try {
        $pdo->exec("ALTER TABLE `orders` ADD CONSTRAINT `fk_order_driver` FOREIGN KEY (`driver_id`) REFERENCES `drivers` (`id`) ON DELETE SET NULL");
    } catch (PDOException $e) {}

    // Add tiffin return tracking columns to orders
    try {
        $pdo->exec("ALTER TABLE `orders` ADD COLUMN `tiffin_received_to_hotel` VARCHAR(50) NOT NULL DEFAULT 'pending'");
    } catch (PDOException $e) {}

    try {
        $pdo->exec("ALTER TABLE `orders` ADD COLUMN `tiffin_return_otp` VARCHAR(4) DEFAULT NULL");
    } catch (PDOException $e) {}

    try {
        $pdo->exec("ALTER TABLE `orders` ADD COLUMN `tiffin_returned_driver_id` INT UNSIGNED DEFAULT NULL");
    } catch (PDOException $e) {}

    try {
        $pdo->exec("ALTER TABLE `orders` ADD COLUMN `tiffin_returned_at` DATETIME DEFAULT NULL");
    } catch (PDOException $e) {}

    // Create tiffin_return_logs table
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS `tiffin_return_logs` (
            `id`                      INT UNSIGNED  NOT NULL AUTO_INCREMENT,
            `order_id`                INT UNSIGNED  NOT NULL,
            `driver_id`               INT UNSIGNED  NOT NULL,
            `customer_id`             INT UNSIGNED  NOT NULL,
            `hotel_id`                INT UNSIGNED  NOT NULL,
            `otp`                     VARCHAR(4)    NOT NULL,
            `verified_at`             DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `log_details`             TEXT          DEFAULT NULL,
            PRIMARY KEY (`id`),
            CONSTRAINT `fk_tiffin_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE CASCADE,
            CONSTRAINT `fk_tiffin_driver` FOREIGN KEY (`driver_id`) REFERENCES `drivers` (`id`) ON DELETE CASCADE,
            CONSTRAINT `fk_tiffin_customer` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE CASCADE,
            CONSTRAINT `fk_tiffin_hotel` FOREIGN KEY (`hotel_id`) REFERENCES `hotels` (`id`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ");
}
