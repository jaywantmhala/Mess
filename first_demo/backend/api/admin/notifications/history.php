<?php
/**
 * GET /api/admin/notifications/history
 *
 * Retrieve notification broadcast history list for Admin dashboard.
 */

require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../helpers/response.php';
require_once __DIR__ . '/../../../helpers/jwt.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'GET')     { sendError('Method not allowed. Use GET.', 405); }

$token   = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;

if (!$payload || !isset($payload['sub']) || ($payload['role'] ?? '') !== 'admin') {
    sendError('Unauthorized. Admin access required.', 401);
}

$pdo = getDBConnection();

try {
    // Ensure table exists before querying
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS `admin_notifications` (
            `id`            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            `title`         VARCHAR(255) NOT NULL,
            `body`          TEXT NOT NULL,
            `target`        VARCHAR(50) NOT NULL DEFAULT 'all',
            `state`         VARCHAR(100) DEFAULT NULL,
            `district`      VARCHAR(100) DEFAULT NULL,
            `taluka`        VARCHAR(100) DEFAULT NULL,
            `target_count`  INT UNSIGNED DEFAULT 0,
            `click_action`  VARCHAR(100) DEFAULT NULL,
            `image_url`     TEXT DEFAULT NULL,
            `created_at`    DATETIME DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ");

    try {
        $pdo->exec("ALTER TABLE `admin_notifications` ADD COLUMN `state` VARCHAR(100) DEFAULT NULL");
    } catch (Exception $e) {}
    try {
        $pdo->exec("ALTER TABLE `admin_notifications` ADD COLUMN `district` VARCHAR(100) DEFAULT NULL");
    } catch (Exception $e) {}
    try {
        $pdo->exec("ALTER TABLE `admin_notifications` ADD COLUMN `taluka` VARCHAR(100) DEFAULT NULL");
    } catch (Exception $e) {}

    $stmt = $pdo->query("
        SELECT id, title, body, target, state, district, taluka, target_count, click_action, image_url, created_at
        FROM admin_notifications
        ORDER BY id DESC
        LIMIT 50
    ");
    $list = $stmt->fetchAll(PDO::FETCH_ASSOC);

    sendSuccess('Notification history retrieved successfully.', [
        'notifications' => $list
    ]);
} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
