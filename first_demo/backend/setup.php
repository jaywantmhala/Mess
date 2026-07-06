<?php
/**
 * ============================================================
 *  DATABASE SETUP & DIAGNOSTIC SCRIPT
 *  Run this once in your browser to create the DB and tables.
 *  URL: http://localhost/first_demo/backend/setup.php
 *
 *  ⚠️  DELETE or RESTRICT this file in production!
 * ============================================================
 */

// Show ALL errors during setup
error_reporting(E_ALL);
ini_set('display_errors', '1');

// ── Configuration (must match config/database.php) ─────────────────────────
$host    = 'localhost';
$user    = 'root';
$pass    = 'root';          // ← Change to your MySQL password (blank for XAMPP default)
$dbName  = 'first_demo_db';
$port    = 3306;        // ← Default MySQL port

// ── Helper: print styled result ─────────────────────────────────────────────
function result(string $label, bool $ok, string $detail = ''): void {
    $icon  = $ok ? '✅' : '❌';
    $color = $ok ? '#1a7f37' : '#cf222e';
    echo "<div style='margin:8px 0;padding:10px 14px;background:" . ($ok ? '#dafbe1' : '#ffebe9') . ";border-left:4px solid $color;border-radius:6px;font-family:monospace'>";
    echo "<strong style='color:$color'>$icon $label</strong>";
    if ($detail) echo "<br><span style='color:#444;font-size:13px'>$detail</span>";
    echo "</div>";
}

function info(string $msg): void {
    echo "<div style='margin:8px 0;padding:10px 14px;background:#ddf4ff;border-left:4px solid #0969da;border-radius:6px;font-family:monospace;color:#0550ae'>ℹ️ $msg</div>";
}

?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Backend Setup — first_demo</title>
<style>
  body { font-family: -apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif; max-width:780px; margin:40px auto; background:#f6f8fa; color:#24292f; padding:0 20px; }
  h1   { font-size:22px; border-bottom:1px solid #d0d7de; padding-bottom:12px; }
  h2   { font-size:16px; margin:28px 0 10px; color:#57606a; text-transform:uppercase; letter-spacing:.5px; }
  pre  { background:#161b22; color:#e6edf3; padding:16px; border-radius:8px; overflow-x:auto; font-size:13px; line-height:1.6; }
  .badge { display:inline-block; padding:2px 10px; border-radius:12px; font-size:12px; font-weight:600; background:#ddf4ff; color:#0969da; }
</style>
</head>
<body>
<h1>🔧 first_demo — PHP Backend Setup</h1>

<?php

// ── Step 1: PHP Version ──────────────────────────────────────────────────────
$phpOk = version_compare(PHP_VERSION, '7.4.0', '>=');
result("PHP Version: " . PHP_VERSION, $phpOk, $phpOk ? 'Required: >= 7.4' : '❌ Please upgrade PHP to 7.4+');

// ── Step 2: PDO Extension ────────────────────────────────────────────────────
$pdoOk = extension_loaded('pdo') && extension_loaded('pdo_mysql');
result("PDO & PDO_MySQL extension", $pdoOk, $pdoOk ? 'Both loaded' : 'Enable pdo and pdo_mysql in php.ini');

if (!$pdoOk) {
    echo "<p>Open your <code>php.ini</code> and uncomment:</p>";
    echo "<pre>extension=pdo_mysql</pre>";
    die("</body></html>");
}

// ── Step 3: Connect to MySQL (no DB selected) ────────────────────────────────
echo "<h2>Step 1 — MySQL Connection</h2>";
try {
    $pdo = new PDO(
        "mysql:host=$host;port=$port;charset=utf8mb4",
        $user,
        $pass,
        [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        ]
    );
    $serverVersion = $pdo->getAttribute(PDO::ATTR_SERVER_VERSION);
    result("MySQL connection", true, "Server version: $serverVersion | Host: $host:$port | User: $user");
} catch (PDOException $e) {
    result("MySQL connection", false, $e->getMessage());
    echo "<h2>🔎 Troubleshooting</h2>";
    echo "<pre>";
    echo "1. Is XAMPP/WAMP/MySQL running?\n";
    echo "   → Open XAMPP Control Panel → Start 'MySQL'\n\n";
    echo "2. Wrong password?\n";
    echo "   → Edit setup.php line 15:  \$pass = 'your_password';\n";
    echo "   → Also edit config/database.php line 9:  define('DB_PASS', 'your_password');\n\n";
    echo "3. Wrong port?\n";
    echo "   → Default MySQL: 3306, XAMPP sometimes uses 3307\n";
    echo "   → Edit setup.php line 16:  \$port = 3307;\n\n";
    echo "4. MySQL user 'root' has no access?\n";
    echo "   → Open phpMyAdmin → User Accounts → check 'root'@'localhost'\n";
    echo "</pre>";
    die("</body></html>");
}

// ── Step 4: Create Database ──────────────────────────────────────────────────
echo "<h2>Step 2 — Create Database</h2>";
try {
    $pdo->exec("CREATE DATABASE IF NOT EXISTS `$dbName` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
    $pdo->exec("USE `$dbName`");
    result("Database '$dbName'", true, "Created or already exists");
} catch (PDOException $e) {
    result("Create database '$dbName'", false, $e->getMessage());
    die("</body></html>");
}

// ── Step 5: Create customers Table ──────────────────────────────────────────
echo "<h2>Step 3 — Create Tables</h2>";
$createTable = "
    CREATE TABLE IF NOT EXISTS `customers` (
        `id`              INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
        `full_name`       VARCHAR(150)     NOT NULL,
        `email`           VARCHAR(255)     NOT NULL,
        `password`        VARCHAR(255)     NOT NULL COMMENT 'bcrypt hashed password',
        `is_active`       TINYINT(1)       NOT NULL DEFAULT 1,
        `email_verified`  TINYINT(1)       NOT NULL DEFAULT 0,
        `profile_picture` VARCHAR(500)     NULL DEFAULT NULL,
        `last_login_at`   DATETIME         NULL DEFAULT NULL,
        `created_at`      DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at`      DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_customers_email` (`email`),
        KEY `idx_customers_email_active` (`email`, `is_active`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
      COMMENT='Customer accounts for first_demo application'
";

try {
    $pdo->exec($createTable);
    result("Table 'customers'", true, "Created or already exists");
} catch (PDOException $e) {
    result("Table 'customers'", false, $e->getMessage());
    die("</body></html>");
}

// ── Step 6: Verify table columns ─────────────────────────────────────────────
try {
    $cols = $pdo->query("DESCRIBE customers")->fetchAll();
    echo "<h2>Step 4 — Table Columns Verified</h2>";
    echo "<table border='1' cellpadding='6' cellspacing='0' style='border-collapse:collapse;width:100%;font-family:monospace;font-size:13px;border-color:#d0d7de'>";
    echo "<tr style='background:#f0f6ff'><th>Column</th><th>Type</th><th>Null</th><th>Key</th><th>Default</th><th>Extra</th></tr>";
    foreach ($cols as $col) {
        echo "<tr>";
        foreach ($col as $val) {
            echo "<td style='padding:6px 10px;border:1px solid #d0d7de'>" . htmlspecialchars((string)$val) . "</td>";
        }
        echo "</tr>";
    }
    echo "</table>";
} catch (PDOException $e) {
    result("Verify table", false, $e->getMessage());
}

// ── Step 7: Update config/database.php with correct password ─────────────────
$configPath = __DIR__ . '/config/database.php';
if (file_exists($configPath)) {
    $config   = file_get_contents($configPath);
    $newConfig = preg_replace(
        "/define\('DB_PASS',\s*'.*?'\)/",
        "define('DB_PASS', '$pass')",
        $config
    );
    $newConfig = preg_replace(
        "/define\('DB_HOST',\s*'.*?'\)/",
        "define('DB_HOST', '$host')",
        $newConfig
    );
    if ($newConfig !== $config) {
        file_put_contents($configPath, $newConfig);
        info("config/database.php updated automatically with host=$host and your password.");
    } else {
        info("config/database.php credentials already match — no changes needed.");
    }
}

// ── Step 8: Test API endpoints reachability ──────────────────────────────────
echo "<h2>Step 5 — API Endpoints</h2>";
$base = (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http')
        . '://' . $_SERVER['HTTP_HOST']
        . rtrim(dirname($_SERVER['REQUEST_URI']), '/');

$endpoints = [
    ['POST', "$base/api/auth/signup.php",  'Register a new customer'],
    ['POST', "$base/api/auth/login.php",   'Authenticate & get JWT'],
    ['GET',  "$base/api/auth/me.php",      'Get profile (JWT required)'],
    ['POST', "$base/api/auth/logout.php",  'Logout (JWT required)'],
];
echo "<table border='1' cellpadding='6' cellspacing='0' style='border-collapse:collapse;width:100%;font-size:13px;border-color:#d0d7de'>";
echo "<tr style='background:#f0f6ff'><th>Method</th><th>Endpoint</th><th>Description</th></tr>";
foreach ($endpoints as [$method, $url, $desc]) {
    echo "<tr><td style='padding:6px 10px;border:1px solid #d0d7de;font-weight:700;color:#0550ae'>$method</td>";
    echo "<td style='padding:6px 10px;border:1px solid #d0d7de;font-family:monospace'><a href='$url' target='_blank'>$url</a></td>";
    echo "<td style='padding:6px 10px;border:1px solid #d0d7de'>$desc</td></tr>";
}
echo "</table>";

// ── All done ──────────────────────────────────────────────────────────────────
echo "<br>";
result("🎉 Setup Complete!", true, "Database '$dbName' and 'customers' table are ready. You can now use the APIs.");

echo "<h2>⚠️ Security Reminder</h2>";
echo "<div style='padding:12px 16px;background:#fff8c5;border-left:4px solid #d4a72c;border-radius:6px;font-size:14px'>";
echo "<strong>Delete or disable setup.php</strong> before deploying to production.<br>";
echo "It exposes your database credentials and server configuration.";
echo "</div>";

// ── Handy cURL test commands ─────────────────────────────────────────────────
echo "<h2>Quick Test with cURL</h2>";
echo "<pre>";
echo "# Sign Up\n";
echo 'curl -X POST ' . $base . '/api/auth/signup.php \' . "\n";
echo '     -H "Content-Type: application/json" \' . "\n";
echo '     -d \'{"full_name":"Test User","email":"test@example.com","password":"Test1234","confirm_password":"Test1234"}\'';
echo "\n\n# Login\n";
echo 'curl -X POST ' . $base . '/api/auth/login.php \' . "\n";
echo '     -H "Content-Type: application/json" \' . "\n";
echo '     -d \'{"email":"test@example.com","password":"Test1234"}\'';
echo "</pre>";
?>

</body>
</html>
