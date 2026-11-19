<?php
// Set default timezone to IST (India Standard Time)
if (date_default_timezone_get() !== 'Asia/Kolkata') {
    date_default_timezone_set('Asia/Kolkata');
}

/**
 * Database Configuration ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â MySQL (visible in MySQL Workbench)
 * Connects to MySQL Server 8.0 running as Windows service.
 * Auto-creates the database and tables on first run.
 */

$httpHost = $_SERVER['HTTP_HOST'] ?? '';
$isProduction = (strpos($httpHost, 'hungrilyfoods.com') !== false || strpos(__DIR__, 'u292076282') !== false);

if ($isProduction) {
    define('DB_HOST',    'localhost');
    define('DB_PORT',    '3306');
    define('DB_USER',    'u292076282_hungrily');
    define('DB_PASS',    'HungrilyPassword@123');
    define('DB_NAME',    'u292076282_hungrily');
} else {
    define('DB_HOST',    'localhost');
    define('DB_PORT',    '3306');
    define('DB_USER',    'root');
    define('DB_PASS',    'root');         // ÃƒÂ¢Ã¢â‚¬Â Ã‚Â your MySQL root password
    define('DB_NAME',    'first_demo_db');
}
define('JWT_SECRET', 'first_demo_super_secret_jwt_key_2024_change_me');
define('JWT_EXPIRY', 3153600000);        // 100 years access token (never expires)
define('JWT_ACCESS_EXPIRY', 3153600000); // 100 years access token (never expires)
define('JWT_REFRESH_EXPIRY', 3153600000); // 100 years refresh token (never expires)
define('GOOGLE_MAPS_API_KEY', 'AIzaSyDuZC6kFobB0pnp-k3VcxQIjvb0EhgfnVI');

// Full path to mysql.exe ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â used for CLI operations in setup only
define('MYSQL_BIN',  'C:\\Program Files\\MySQL\\MySQL Server 8.0\\bin\\mysql.exe');

/**
 * Returns a PDO connection to MySQL.
 * Auto-creates the DB and tables if they don't exist.
 */
function getDBConnection(): PDO {
    // Set PHP timezone to IST (India Standard Time) for consistent timestamps
    if (date_default_timezone_get() !== 'Asia/Kolkata') {
        date_default_timezone_set('Asia/Kolkata');
    }

    // Connect without DB first so we can CREATE DATABASE
    $connected = false;
    $passwordsToTry = [DB_PASS];
    if (DB_PASS !== '') {
        $passwordsToTry[] = '';
    }
    $lastException = null;
    foreach ($passwordsToTry as $pass) {
        try {
            $pdo = new PDO(
                "mysql:host=" . DB_HOST . ";port=" . DB_PORT . ";charset=utf8mb4",
                DB_USER,
                $pass,
                [
                    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                    PDO::ATTR_EMULATE_PREPARES   => true,
                ]
            );
            $connected = true;
            break;
        } catch (PDOException $e) {
            $lastException = $e;
        }
    }
    if (!$connected) {
        http_response_code(500);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode([
            'success' => false,
            'message' => 'MySQL connection failed.',
            'error'   => $lastException ? $lastException->getMessage() : 'Unknown error',
            'hint'    => 'Check DB_HOST, DB_PORT, DB_USER, DB_PASS in config/database.php. Is MySQL80 service running?',
        ], JSON_PRETTY_PRINT);
        exit;
    }

    // Auto-create database
    $pdo->exec("CREATE DATABASE IF NOT EXISTS `" . DB_NAME . "`
                CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
    $pdo->exec("USE `" . DB_NAME . "`");

    // Set MySQL session timezone to IST (Asia/Kolkata, UTC+05:30) for accurate timestamps
    $pdo->exec("SET time_zone = '+05:30'");

    // Ensure all database tables and required columns exist automatically
    createTables($pdo);
    ensureServiceLocationTables($pdo);
    ensureVendorLocationColumns($pdo);
    ensureDriverLocationColumns($pdo);
    ensureCustomerLocationColumns($pdo);
    ensureCustomerAddressLocationColumns($pdo);
    ensureHotelColumns($pdo);
    ensureGstColumnsInHotels($pdo);
    ensureVendorPayoutTable($pdo);
    ensureMissingCoreTables($pdo);
    ensureRefreshTokenTable($pdo);
    ensureOtpVerificationTable($pdo);
    ensureEnquiriesTable($pdo);

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
            `fcm_token`       VARCHAR(255)  DEFAULT NULL,
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
            `phone`           VARCHAR(20)   DEFAULT NULL,
            `country`         VARCHAR(100)  NOT NULL DEFAULT 'India',
            `state`           VARCHAR(100)  DEFAULT NULL,
            `district`        VARCHAR(100)  DEFAULT NULL,
            `taluka`          VARCHAR(100)  DEFAULT NULL,
            `is_active`       TINYINT(1)    NOT NULL DEFAULT 1,
            `fcm_token`       VARCHAR(255)  DEFAULT NULL,
            `created_at`      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at`      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `uq_vendor_email` (`email`),
            KEY `idx_vendor_email_active` (`email`, `is_active`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
          COMMENT='Vendor accounts'
    ");

    // Create refresh_tokens table
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS `refresh_tokens` (
            `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `user_id`     INT UNSIGNED NOT NULL,
            `role`        VARCHAR(20)  NOT NULL DEFAULT 'customer',
            `token_hash`  VARCHAR(255) NOT NULL,
            `expires_at`  DATETIME     NOT NULL,
            `created_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `uq_token_hash` (`token_hash`),
            KEY `idx_user_role` (`user_id`, `role`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
          COMMENT='Refresh tokens for authentication'
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
            `meal_type`       ENUM('Lunch','Dinner') NOT NULL DEFAULT 'Lunch',
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
    try {
        $pdo->exec("ALTER TABLE `menus` ADD COLUMN `meal_type` ENUM('Lunch','Dinner') NOT NULL DEFAULT 'Lunch'");
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

    // Ensure index on orders(created_at) for fast date-based order queries
    try {
        $pdo->exec("ALTER TABLE `orders` ADD INDEX `idx_orders_created_at` (`created_at`)");
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
            `fcm_token`       VARCHAR(255)  DEFAULT NULL,
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

    // Add fcm_token column to customers, vendors, drivers if they don't exist
    try {
        $pdo->exec("ALTER TABLE `customers` ADD COLUMN `fcm_token` VARCHAR(255) DEFAULT NULL");
    } catch (PDOException $e) {}
    try {
        $pdo->exec("ALTER TABLE `vendors` ADD COLUMN `fcm_token` VARCHAR(255) DEFAULT NULL");
    } catch (PDOException $e) {}
    try {
        $pdo->exec("ALTER TABLE `drivers` ADD COLUMN `fcm_token` VARCHAR(255) DEFAULT NULL");
    } catch (PDOException $e) {}

    ensureServiceLocationTables($pdo);
}

/**
 * Ensure service_locations and plans tables exist.
 */
function ensureServiceLocationTables(PDO $pdo): void {
    try {
        $pdo->exec("
            CREATE TABLE IF NOT EXISTS `service_locations` (
                `id`            INT UNSIGNED  NOT NULL AUTO_INCREMENT,
                `location_name` VARCHAR(255)  NOT NULL,
                `address`       TEXT          DEFAULT NULL,
                `latitude`      DECIMAL(10,8) NOT NULL DEFAULT 0.00000000,
                `longitude`     DECIMAL(11,8) NOT NULL DEFAULT 0.00000000,
                `location`      POINT         DEFAULT NULL,
                `radius_km`     DECIMAL(5,2)  NOT NULL DEFAULT 5.00,
                `tiffin_charge` DECIMAL(10,2) NOT NULL DEFAULT 50.00,
                `country`       VARCHAR(50)   NOT NULL DEFAULT 'IN',
                `region`        VARCHAR(100)  DEFAULT NULL,
                `status`        ENUM('active','inactive') NOT NULL DEFAULT 'active',
                `created_at`    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
                `updated_at`    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                PRIMARY KEY (`id`),
                KEY `idx_service_loc_status` (`status`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ");

        $pdo->exec("
            CREATE TABLE IF NOT EXISTS `plans` (
                `id`                  INT UNSIGNED  NOT NULL AUTO_INCREMENT,
                `service_location_id` INT UNSIGNED  NOT NULL,
                `plan_name`           VARCHAR(255)  NOT NULL,
                `description`         TEXT          DEFAULT NULL,
                `price`               DECIMAL(10,2) NOT NULL DEFAULT 0.00,
                `duration`            INT           NOT NULL DEFAULT 30,
                `total_deliveries`    INT           NOT NULL DEFAULT 30,
                `meals_per_day`       INT           NOT NULL DEFAULT 1,
                `meal_type`           ENUM('VEG','NON-VEG','BOTH') NOT NULL DEFAULT 'VEG',
                `delivery_time_slot`  VARCHAR(100)  DEFAULT NULL,
                `discount`            DECIMAL(10,2) NOT NULL DEFAULT 0.00,
                `delivery_charge`     DECIMAL(10,2) NOT NULL DEFAULT 0.00,
                `tiffin_charge`       DECIMAL(10,2) NOT NULL DEFAULT 50.00,
                `status`              ENUM('active','inactive') NOT NULL DEFAULT 'active',
                `legacy_plan_id`      INT UNSIGNED  DEFAULT NULL,
                `created_at`          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
                `updated_at`          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                PRIMARY KEY (`id`),
                KEY `idx_plans_service_loc` (`service_location_id`),
                KEY `idx_plans_status` (`status`),
                CONSTRAINT `fk_plans_service_location` FOREIGN KEY (`service_location_id`) REFERENCES `service_locations` (`id`) ON DELETE CASCADE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ");

        $pdo->exec("
            CREATE TABLE IF NOT EXISTS `customer_subscriptions` (
                `id`                   INT UNSIGNED  NOT NULL AUTO_INCREMENT,
                `customer_id`          INT UNSIGNED  NOT NULL,
                `plan_id`              INT UNSIGNED  NOT NULL,
                `start_date`           DATE          NOT NULL,
                `end_date`             DATE          NOT NULL,
                `status`               VARCHAR(20)   NOT NULL DEFAULT 'ACTIVE',
                `remaining_deliveries` INT           NOT NULL DEFAULT 30,
                `total_deliveries`     INT           NOT NULL DEFAULT 30,
                `completed_deliveries` INT           NOT NULL DEFAULT 0,
                `auto_renew`           TINYINT(1)    NOT NULL DEFAULT 1,
                `pause_history`        TEXT          DEFAULT NULL,
                `created_at`           DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
                `updated_at`           DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                PRIMARY KEY (`id`),
                KEY `idx_cust_sub_cust` (`customer_id`),
                KEY `idx_cust_sub_status` (`status`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ");

        $pdo->exec("
            CREATE TABLE IF NOT EXISTS `sub_areas` (
                `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
                `sub_area_name` VARCHAR(255) NOT NULL,
                `latitude`      DECIMAL(10,8) DEFAULT 0.00000000,
                `longitude`     DECIMAL(11,8) DEFAULT 0.00000000,
                `tiffin_charge` DECIMAL(10,2) NOT NULL DEFAULT 50.00,
                PRIMARY KEY (`id`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ");

        $pdo->exec("
            CREATE TABLE IF NOT EXISTS `subscription_plans` (
                `id`               INT UNSIGNED NOT NULL AUTO_INCREMENT,
                `sub_area_id`      INT UNSIGNED NOT NULL,
                `plan_name`        VARCHAR(255) NOT NULL,
                `price`            DECIMAL(10,2) NOT NULL DEFAULT 0.00,
                `duration`         INT NOT NULL DEFAULT 30,
                `total_deliveries` INT NOT NULL DEFAULT 30,
                `tiffin_charge`    DECIMAL(10,2) NOT NULL DEFAULT 50.00,
                PRIMARY KEY (`id`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ");

        // Dynamic column addition checks
        $slCols = $pdo->query("SHOW COLUMNS FROM service_locations")->fetchAll(PDO::FETCH_COLUMN);
        if (!in_array('tiffin_charge', $slCols)) {
            $pdo->exec("ALTER TABLE service_locations ADD COLUMN `tiffin_charge` DECIMAL(10,2) NOT NULL DEFAULT 50.00");
        }
        $pCols = $pdo->query("SHOW COLUMNS FROM plans")->fetchAll(PDO::FETCH_COLUMN);
        if (!in_array('tiffin_charge', $pCols)) {
            $pdo->exec("ALTER TABLE plans ADD COLUMN `tiffin_charge` DECIMAL(10,2) NOT NULL DEFAULT 50.00");
        }
        $ordCols = $pdo->query("SHOW COLUMNS FROM orders")->fetchAll(PDO::FETCH_COLUMN);
        if (!in_array('tiffin_charge', $ordCols)) {
            $pdo->exec("ALTER TABLE orders ADD COLUMN `tiffin_charge` DECIMAL(10,2) NOT NULL DEFAULT 50.00");
        }
    } catch (PDOException $e) {}
}

/**
 * Ensure country, state, district, taluka, and phone columns exist in vendors table.
 */
function ensureVendorLocationColumns(PDO $pdo): void {
    try {
        $cols = $pdo->query("SHOW COLUMNS FROM vendors")->fetchAll(PDO::FETCH_COLUMN);
        
        if (!in_array('phone', $cols)) {
            $pdo->exec("ALTER TABLE vendors ADD COLUMN `phone` VARCHAR(20) DEFAULT NULL AFTER `email`");
        }
        if (!in_array('country', $cols)) {
            $pdo->exec("ALTER TABLE vendors ADD COLUMN `country` VARCHAR(100) NOT NULL DEFAULT 'India'");
        }
        if (!in_array('state', $cols)) {
            $pdo->exec("ALTER TABLE vendors ADD COLUMN `state` VARCHAR(100) DEFAULT NULL");
        }
        if (!in_array('district', $cols)) {
            $pdo->exec("ALTER TABLE vendors ADD COLUMN `district` VARCHAR(100) DEFAULT NULL");
        }
        if (!in_array('taluka', $cols)) {
            $pdo->exec("ALTER TABLE vendors ADD COLUMN `taluka` VARCHAR(100) DEFAULT NULL");
        }
        if (!in_array('region', $cols)) {
            $pdo->exec("ALTER TABLE vendors ADD COLUMN `region` VARCHAR(100) DEFAULT NULL AFTER `taluka`");
        }
        if (!in_array('area', $cols)) {
            $pdo->exec("ALTER TABLE vendors ADD COLUMN `area` VARCHAR(100) DEFAULT NULL");
        }

        $hCols = $pdo->query("SHOW COLUMNS FROM hotels")->fetchAll(PDO::FETCH_COLUMN);
        if (!in_array('region', $hCols)) {
            $pdo->exec("ALTER TABLE hotels ADD COLUMN `region` VARCHAR(150) DEFAULT NULL AFTER `taluka`");
        }
        if (!in_array('area', $hCols)) {
            $pdo->exec("ALTER TABLE hotels ADD COLUMN `area` VARCHAR(150) DEFAULT NULL");
        }
    } catch (PDOException $e) {}
}

/**
 * Ensure country, state, district, taluka exist in drivers table.
 */
function ensureDriverLocationColumns(PDO $pdo): void {
    try {
        $cols = $pdo->query("SHOW COLUMNS FROM drivers")->fetchAll(PDO::FETCH_COLUMN);
        if (!in_array('country', $cols)) {
            $pdo->exec("ALTER TABLE drivers ADD COLUMN `country` VARCHAR(100) NOT NULL DEFAULT 'India'");
        }
        if (!in_array('state', $cols)) {
            $pdo->exec("ALTER TABLE drivers ADD COLUMN `state` VARCHAR(100) DEFAULT NULL");
        }
        if (!in_array('district', $cols)) {
            $pdo->exec("ALTER TABLE drivers ADD COLUMN `district` VARCHAR(100) DEFAULT NULL");
        }
        if (!in_array('taluka', $cols)) {
            $pdo->exec("ALTER TABLE drivers ADD COLUMN `taluka` VARCHAR(100) DEFAULT NULL");
        }
    } catch (PDOException $e) {}
}

/**
 * Ensure country, state, district, taluka exist in customer_addresses table.
 */
function ensureCustomerAddressLocationColumns(PDO $pdo): void {
    try {
        $res = $pdo->query("SHOW TABLES LIKE 'customer_addresses'")->fetch();
        if ($res) {
            $cols = $pdo->query("SHOW COLUMNS FROM customer_addresses")->fetchAll(PDO::FETCH_COLUMN);
            if (!in_array('country', $cols)) {
                $pdo->exec("ALTER TABLE customer_addresses ADD COLUMN `country` VARCHAR(100) NOT NULL DEFAULT 'India'");
            }
            if (!in_array('state', $cols)) {
                $pdo->exec("ALTER TABLE customer_addresses ADD COLUMN `state` VARCHAR(100) DEFAULT ''");
            }
            if (!in_array('district', $cols)) {
                $pdo->exec("ALTER TABLE customer_addresses ADD COLUMN `district` VARCHAR(255) DEFAULT ''");
            }
            if (!in_array('taluka', $cols)) {
                $pdo->exec("ALTER TABLE customer_addresses ADD COLUMN `taluka` VARCHAR(255) DEFAULT ''");
            }
            if (!in_array('region', $cols)) {
                $pdo->exec("ALTER TABLE customer_addresses ADD COLUMN `region` VARCHAR(100) DEFAULT ''");
            }
            if (!in_array('area', $cols)) {
                $pdo->exec("ALTER TABLE customer_addresses ADD COLUMN `area` VARCHAR(255) DEFAULT ''");
            }
            if (!in_array('full_address', $cols)) {
                $pdo->exec("ALTER TABLE customer_addresses ADD COLUMN `full_address` TEXT DEFAULT NULL");
            }
        }
    } catch (PDOException $e) {}
}

/**
 * Ensure phone_number, country, state, district, taluka, region, area exist in customers table.
 */
function ensureCustomerLocationColumns(PDO $pdo): void {
    try {
        $cols = $pdo->query("SHOW COLUMNS FROM customers")->fetchAll(PDO::FETCH_COLUMN);
        if (!in_array('phone_number', $cols)) {
            $pdo->exec("ALTER TABLE customers ADD COLUMN `phone_number` VARCHAR(20) DEFAULT NULL");
        }
        if (!in_array('country', $cols)) {
            $pdo->exec("ALTER TABLE customers ADD COLUMN `country` VARCHAR(100) NOT NULL DEFAULT 'India'");
        }
        if (!in_array('state', $cols)) {
            $pdo->exec("ALTER TABLE customers ADD COLUMN `state` VARCHAR(100) DEFAULT NULL");
        }
        if (!in_array('district', $cols)) {
            $pdo->exec("ALTER TABLE customers ADD COLUMN `district` VARCHAR(100) DEFAULT NULL");
        }
        if (!in_array('taluka', $cols)) {
            $pdo->exec("ALTER TABLE customers ADD COLUMN `taluka` VARCHAR(100) DEFAULT NULL");
        }
        if (!in_array('region', $cols)) {
            $pdo->exec("ALTER TABLE customers ADD COLUMN `region` VARCHAR(100) DEFAULT NULL");
        }
        if (!in_array('area', $cols)) {
            $pdo->exec("ALTER TABLE customers ADD COLUMN `area` VARCHAR(255) DEFAULT NULL");
        }
    } catch (PDOException $e) {}
}

/**
 * Ensure performance indexes for customer searches (name, email, phone) and joins exist.
 */
function ensureCustomerSearchIndexes(PDO $pdo): void {
    try {
        $helper = function($table, $indexName, $colsSql) use ($pdo) {
            $check = $pdo->prepare("
                SELECT COUNT(1) 
                FROM information_schema.statistics 
                WHERE table_schema = DATABASE() 
                  AND table_name = ? 
                  AND index_name = ?
            ");
            $check->execute([$table, $indexName]);
            if ((int)$check->fetchColumn() === 0) {
                $pdo->exec("ALTER TABLE `{$table}` ADD INDEX `{$indexName}` ({$colsSql})");
            }
        };

        $helper('customers', 'idx_cust_full_name', '`full_name`');
        $helper('customers', 'idx_cust_phone_number', '`phone_number`');
        $helper('customers', 'idx_cust_created_at', '`created_at`');
        $helper('customer_addresses', 'idx_ca_customer_id', '`customer_id`');
        $helper('customer_addresses', 'idx_ca_location', '`district`, `city`');
    } catch (PDOException $e) {}
}

/**
 * Ensure food_type and service_type exist in hotels table.
 */
function ensureHotelColumns(PDO $pdo): void {
    try {
        $cols = $pdo->query("SHOW COLUMNS FROM hotels")->fetchAll(PDO::FETCH_COLUMN);
        if (!in_array('food_type', $cols)) {
            $pdo->exec("ALTER TABLE hotels ADD COLUMN `food_type` VARCHAR(20) DEFAULT 'BOTH'");
        }
        if (!in_array('service_type', $cols)) {
            $pdo->exec("ALTER TABLE hotels ADD COLUMN `service_type` VARCHAR(20) DEFAULT 'BOTH'");
        }
    } catch (PDOException $e) {}
}

/**
 * Ensure refresh_tokens table exists.
 */
function ensureRefreshTokenTable(PDO $pdo): void {
    try {
        $pdo->exec("
            CREATE TABLE IF NOT EXISTS `refresh_tokens` (
                `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,
                `user_id`     INT UNSIGNED NOT NULL,
                `role`        VARCHAR(20)  NOT NULL DEFAULT 'customer',
                `token_hash`  VARCHAR(255) NOT NULL,
                `expires_at`  DATETIME     NOT NULL,
                `created_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (`id`),
                UNIQUE KEY `uq_token_hash` (`token_hash`),
                KEY `idx_user_role` (`user_id`, `role`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
              COMMENT='Refresh tokens for authentication'
        ");
    } catch (PDOException $e) {}
}

/**
 * Ensure otp_verifications table exists.
 */
function ensureOtpVerificationTable(PDO $pdo): void {
    try {
        $pdo->exec("
            CREATE TABLE IF NOT EXISTS `otp_verifications` (
                `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,
                `phone`       VARCHAR(20)  NOT NULL,
                `otp`         VARCHAR(10)  NOT NULL,
                `role`        VARCHAR(20)  NOT NULL DEFAULT 'customer',
                `expires_at`  DATETIME     NOT NULL,
                `created_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (`id`),
                KEY `idx_phone_role` (`phone`, `role`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
              COMMENT='OTP verifications for WhatsApp login/signup'
        ");
    } catch (PDOException $e) {}
}

/**
 * Ensure gst_number and gst_photo_url columns exist in hotels table.
 */
function ensureGstColumnsInHotels(PDO $pdo): void {
    try {
        $cols = $pdo->query("SHOW COLUMNS FROM hotels")->fetchAll(PDO::FETCH_COLUMN);
        if (!in_array('gst_number', $cols)) {
            $pdo->exec("ALTER TABLE hotels ADD COLUMN `gst_number` VARCHAR(50) NULL DEFAULT NULL");
        }
        if (!in_array('gst_photo_url', $cols)) {
            $pdo->exec("ALTER TABLE hotels ADD COLUMN `gst_photo_url` VARCHAR(255) NULL DEFAULT NULL");
        }
    } catch (PDOException $e) {}
}

/**
 * Ensure vendor_payouts table and PayU beneficiary columns in vendors table exist.
 */
function ensureVendorPayoutTable(PDO $pdo): void {
    try {
        $cols = $pdo->query("SHOW COLUMNS FROM vendors")->fetchAll(PDO::FETCH_COLUMN);
        if (!in_array('bank_name', $cols)) {
            $pdo->exec("ALTER TABLE vendors ADD COLUMN `bank_name` VARCHAR(255) DEFAULT NULL");
        }
        if (!in_array('account_holder_name', $cols)) {
            $pdo->exec("ALTER TABLE vendors ADD COLUMN `account_holder_name` VARCHAR(255) DEFAULT NULL");
        }
        if (!in_array('account_number', $cols)) {
            $pdo->exec("ALTER TABLE vendors ADD COLUMN `account_number` VARCHAR(100) DEFAULT NULL");
        }
        if (!in_array('ifsc_code', $cols)) {
            $pdo->exec("ALTER TABLE vendors ADD COLUMN `ifsc_code` VARCHAR(50) DEFAULT NULL");
        }
        if (!in_array('payu_beneficiary_id', $cols)) {
            $pdo->exec("ALTER TABLE vendors ADD COLUMN `payu_beneficiary_id` VARCHAR(100) NULL DEFAULT NULL");
        }
        if (!in_array('bank_verified', $cols)) {
            $pdo->exec("ALTER TABLE vendors ADD COLUMN `bank_verified` TINYINT(1) NOT NULL DEFAULT 0");
        }
        if (!in_array('payout_enabled', $cols)) {
            $pdo->exec("ALTER TABLE vendors ADD COLUMN `payout_enabled` TINYINT(1) NOT NULL DEFAULT 0");
        }
        if (!in_array('bank_verified_at', $cols)) {
            $pdo->exec("ALTER TABLE vendors ADD COLUMN `bank_verified_at` DATETIME NULL DEFAULT NULL");
        }
        if (!in_array('payu_beneficiary_created_at', $cols)) {
            $pdo->exec("ALTER TABLE vendors ADD COLUMN `payu_beneficiary_created_at` DATETIME NULL DEFAULT NULL");
        }
    } catch (PDOException $e) {}

    try {
        $pdo->exec("
            CREATE TABLE IF NOT EXISTS `vendor_payouts` (
                `id`                       INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
                `vendor_id`                INT(11) UNSIGNED NOT NULL,
                `amount`                   DECIMAL(10,2)    NOT NULL DEFAULT 0.00,
                `merchant_ref_id`          VARCHAR(100)     NOT NULL,
                `batch_id`                 VARCHAR(100)     NULL DEFAULT NULL,
                `payu_txn_id`              VARCHAR(100)     NULL DEFAULT NULL,
                `payu_transaction_ref_no` VARCHAR(100)     NULL DEFAULT NULL,
                `bank_transaction_ref_no` VARCHAR(100)     NULL DEFAULT NULL,
                `payment_type`             VARCHAR(20)      NOT NULL DEFAULT 'IMPS',
                `status`                   ENUM('PENDING','PROCESSING','QUEUED','SUCCESS','FAILED','REVERSED') NOT NULL DEFAULT 'PENDING',
                `failure_reason`           TEXT             NULL DEFAULT NULL,
                `initiated_at`             DATETIME         NULL DEFAULT NULL,
                `completed_at`             DATETIME         NULL DEFAULT NULL,
                `created_at`               DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
                `updated_at`               DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                PRIMARY KEY (`id`),
                UNIQUE KEY `uq_vendor_payouts_ref` (`merchant_ref_id`),
                KEY `idx_vendor_payouts_vendor_status` (`vendor_id`, `status`),
                KEY `idx_vendor_payouts_created` (`created_at`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
              COMMENT='Vendor payouts settlements tracking via PayU'
        ");
    } catch (PDOException $e) {}
}

/**
 * Ensure customer_subscriptions, vendor_subscriptions, order_chats, customer_addresses exist.
 */
function ensureMissingCoreTables(PDO $pdo): void {
    try {
        $pdo->exec("
            CREATE TABLE IF NOT EXISTS `customer_subscriptions` (
                `id`                   INT UNSIGNED  NOT NULL AUTO_INCREMENT,
                `customer_id`          INT UNSIGNED  NOT NULL,
                `plan_id`              INT UNSIGNED  NOT NULL,
                `start_date`           DATE          NOT NULL,
                `end_date`             DATE          NOT NULL,
                `status`               VARCHAR(20)   NOT NULL DEFAULT 'ACTIVE',
                `remaining_deliveries` INT           NOT NULL DEFAULT 30,
                `total_deliveries`     INT           NOT NULL DEFAULT 30,
                `completed_deliveries` INT           NOT NULL DEFAULT 0,
                `auto_renew`           TINYINT(1)    NOT NULL DEFAULT 1,
                `pause_history`        TEXT          DEFAULT NULL,
                `created_at`           DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
                `updated_at`           DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                PRIMARY KEY (`id`),
                KEY `idx_cust_sub_cust` (`customer_id`),
                KEY `idx_cust_sub_status` (`status`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ");
    } catch (PDOException $e) {}

    try {
        $pdo->exec("
            CREATE TABLE IF NOT EXISTS `vendor_subscriptions` (
                `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,
                `vendor_id`   INT UNSIGNED NOT NULL,
                `plan_id`     INT UNSIGNED NOT NULL,
                `start_date`  DATE         NOT NULL,
                `end_date`    DATE         NOT NULL,
                `status`      VARCHAR(20)  NOT NULL DEFAULT 'ACTIVE',
                `created_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (`id`),
                KEY `idx_vend_sub_vend` (`vendor_id`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ");
    } catch (PDOException $e) {}

    try {
        $pdo->exec("
            CREATE TABLE IF NOT EXISTS `order_chats` (
                `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,
                `order_id`    INT UNSIGNED NOT NULL,
                `sender_type` VARCHAR(20)  NOT NULL,
                `sender_id`   INT UNSIGNED NOT NULL,
                `message`     TEXT         NOT NULL,
                `is_read`     TINYINT(1)   NOT NULL DEFAULT 0,
                `created_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (`id`),
                KEY `idx_order_chats_order` (`order_id`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ");
    } catch (PDOException $e) {}

    try {
        $pdo->exec("
            CREATE TABLE IF NOT EXISTS `customer_addresses` (
                `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
                `customer_id`    INT UNSIGNED NOT NULL,
                `address_line1` VARCHAR(255) NOT NULL,
                `address_line2` VARCHAR(255) DEFAULT NULL,
                `city`          VARCHAR(100) DEFAULT NULL,
                `state`         VARCHAR(100) DEFAULT NULL,
                `pincode`       VARCHAR(20)  DEFAULT NULL,
                `latitude`      DECIMAL(10,8) DEFAULT 0.00000000,
                `longitude`     DECIMAL(11,8) DEFAULT 0.00000000,
                `country`       VARCHAR(100) DEFAULT 'India',
                `district`      VARCHAR(255) DEFAULT NULL,
                `taluka`        VARCHAR(255) DEFAULT NULL,
                `is_default`    TINYINT(1)   NOT NULL DEFAULT 0,
                `created_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (`id`),
                KEY `idx_addr_customer` (`customer_id`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ");
    } catch (PDOException $e) {}
}

/**
 * Ensure website enquiries table exists with location hierarchy and date indexes.
 */
function ensureEnquiriesTable(PDO $pdo): void {
    try {
        $pdo->exec("
            CREATE TABLE IF NOT EXISTS `enquiries` (
                `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
                `name`       VARCHAR(150) NOT NULL,
                `phone`      VARCHAR(20)  NOT NULL,
                `state`      VARCHAR(100) NOT NULL DEFAULT '',
                `district`   VARCHAR(100) NOT NULL DEFAULT '',
                `taluka`     VARCHAR(100) NOT NULL DEFAULT '',
                `area`       VARCHAR(150) NOT NULL DEFAULT '',
                `notes`      TEXT         DEFAULT NULL,
                `status`     VARCHAR(50)  NOT NULL DEFAULT 'New',
                `created_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
                `updated_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                PRIMARY KEY (`id`),
                KEY `idx_enq_date` (`created_at`),
                KEY `idx_enq_state` (`state`),
                KEY `idx_enq_district` (`district`),
                KEY `idx_enq_taluka` (`taluka`),
                KEY `idx_enq_area` (`area`),
                KEY `idx_enq_status` (`status`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ");
    } catch (PDOException $e) {}
}
