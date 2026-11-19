<?php
/**
 * POST /api/vendor/notifications/mark-read
 *
 * Marks one or all notifications as read for the authenticated vendor.
 * Body: { "notification_id": "admin_24" } or { "all": true }
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/jwt.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendError('Method not allowed. Use POST.', 405);
}

$token   = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;

if (!$payload || !isset($payload['sub'])) {
    sendError('Unauthorized. Vendor access required.', 401);
}

$vendorId = (int)$payload['sub'];
$input = json_decode(file_get_contents('php://input'), true) ?? [];

$markAll = !empty($input['all']);
$notifId = trim($input['notification_id'] ?? '');

$pdo = getDBConnection();

try {
    if ($markAll) {
        $adminIds = $pdo->query("SELECT id FROM admin_notifications WHERE LOWER(target) IN ('vendors', 'vendor', 'all')")->fetchAll(PDO::FETCH_COLUMN);
        $uStmt = $pdo->prepare("SELECT id FROM user_notifications WHERE LOWER(user_type) IN ('vendor', 'vendors', 'all') AND (user_id = ? OR user_id IS NULL)");
        $uStmt->execute([$vendorId]);
        $userRows = $uStmt->fetchAll(PDO::FETCH_COLUMN);

        $stmt = $pdo->prepare("
            INSERT IGNORE INTO user_notification_reads (user_type, user_id, notification_id, notification_type, read_at)
            VALUES ('vendor', :vid, :nid, :ntype, NOW())
        ");

        foreach ($adminIds as $aid) {
            $stmt->execute([':vid' => $vendorId, ':nid' => (int)$aid, ':ntype' => 'admin']);
        }
        foreach ($userRows as $uid) {
            $stmt->execute([':vid' => $vendorId, ':nid' => (int)$uid, ':ntype' => 'user']);
        }

        // Also mark hotel order notifications
        $hStmt = $pdo->prepare("SELECT id FROM hotels WHERE vendor_id = ?");
        $hStmt->execute([$vendorId]);
        $hotelIds = $hStmt->fetchAll(PDO::FETCH_COLUMN);
        if (!empty($hotelIds)) {
            $inClause = implode(',', array_map('intval', $hotelIds));
            $orderRows = $pdo->query("SELECT order_id, status FROM orders WHERE hotel_id IN ($inClause) ORDER BY order_id DESC LIMIT 40")->fetchAll(PDO::FETCH_ASSOC);
            foreach ($orderRows as $o) {
                $pdo->prepare("
                    INSERT IGNORE INTO user_notification_reads (user_type, user_id, notification_id, notification_type, read_at)
                    VALUES ('vendor', ?, ?, ?, NOW())
                ")->execute([$vendorId, (int)$o['order_id'], 'vendor_order_' . strtolower($o['status'])]);
            }
        }

        $pdo->prepare("UPDATE user_notifications SET is_read = 1 WHERE user_type = 'vendor' AND user_id = ?")->execute([$vendorId]);

        sendSuccess('All vendor notifications marked as read.');
    } elseif (!empty($notifId)) {
        $parts = explode('_', $notifId);
        $sourceType = $parts[0] ?? 'admin';
        $rawId = isset($parts[1]) ? (int)$parts[1] : 0;

        if ($sourceType === 'vendor' && isset($parts[1]) && $parts[1] === 'order') {
            $rawId = isset($parts[2]) ? (int)$parts[2] : 0;
            $statusSuffix = $parts[3] ?? '';
            $sourceType = 'vendor_order_' . $statusSuffix;
        }

        $stmt = $pdo->prepare("
            INSERT IGNORE INTO user_notification_reads (user_type, user_id, notification_id, notification_type, read_at)
            VALUES ('vendor', :vid, :nid, :ntype, NOW())
        ");
        $stmt->execute([
            ':vid'   => $vendorId,
            ':nid'   => $rawId,
            ':ntype' => $sourceType,
        ]);

        if ($sourceType === 'user') {
            $pdo->prepare("UPDATE user_notifications SET is_read = 1 WHERE id = ? AND (user_id = ? OR user_id IS NULL)")->execute([$rawId, $vendorId]);
        }

        sendSuccess('Vendor notification marked as read.');
    } else {
        sendError('Please provide notification_id or all: true', 422);
    }
} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
