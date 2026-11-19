<?php
/**
 * GET /api/admin/whatsapp/history
 *
 * Retrieves history of WhatsApp broadcasts sent by admin.
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

$page  = max(1, (int)($_GET['page'] ?? 1));
$limit = min(100, max(1, (int)($_GET['limit'] ?? 20)));
$offset = ($page - 1) * $limit;

$pdo = getDBConnection();

try {
    // Ensure table exists
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS `admin_whatsapp_notifications` (
            `id`            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            `message`       TEXT NOT NULL,
            `target`        VARCHAR(50) NOT NULL DEFAULT 'all',
            `state`         VARCHAR(100) DEFAULT NULL,
            `district`      VARCHAR(100) DEFAULT NULL,
            `taluka`        VARCHAR(100) DEFAULT NULL,
            `target_count`  INT UNSIGNED DEFAULT 0,
            `sent_count`    INT UNSIGNED DEFAULT 0,
            `failed_count`  INT UNSIGNED DEFAULT 0,
            `created_at`    DATETIME DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ");

    $countStmt = $pdo->query("SELECT COUNT(*) FROM admin_whatsapp_notifications");
    $totalRecords = (int)$countStmt->fetchColumn();

    $stmt = $pdo->prepare("
        SELECT * FROM admin_whatsapp_notifications
        ORDER BY created_at DESC
        LIMIT :limit OFFSET :offset
    ");
    $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
    $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
    $stmt->execute();

    $logs = $stmt->fetchAll(PDO::FETCH_ASSOC);

    sendSuccess('WhatsApp notification history fetched successfully.', [
        'logs'         => $logs,
        'total'        => $totalRecords,
        'page'         => $page,
        'limit'        => $limit,
        'total_pages'  => $totalRecords > 0 ? ceil($totalRecords / $limit) : 1
    ]);

} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
