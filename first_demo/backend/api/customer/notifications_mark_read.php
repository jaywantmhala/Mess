<?php
/**
 * POST /api/customer/notifications/mark-read
 *
 * Marks one or all notifications as read for the authenticated customer.
 * Body: { "notification_id": "admin_21" } or { "all": true }
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
    sendError('Unauthorized. Customer authentication required.', 401);
}

$customerId = (int)$payload['sub'];
$input = json_decode(file_get_contents('php://input'), true) ?? [];

$markAll = !empty($input['all']);
$notifId = trim($input['notification_id'] ?? '');

$pdo = getDBConnection();

try {
    if ($markAll) {
        // Fetch all active notifications for this customer and mark them read
        $adminIds = $pdo->query("SELECT id FROM admin_notifications WHERE target IN ('customers', 'all')")->fetchAll(PDO::FETCH_COLUMN);
        $userRows = $pdo->query("SELECT id FROM user_notifications WHERE user_type IN ('customer', 'all') AND (user_id = $customerId OR user_id IS NULL)")->fetchAll(PDO::FETCH_COLUMN);
        $orderRows = $pdo->query("SELECT order_id, status FROM orders WHERE customer_id = $customerId ORDER BY order_id DESC LIMIT 30")->fetchAll(PDO::FETCH_ASSOC);

        $stmt = $pdo->prepare("
            INSERT IGNORE INTO user_notification_reads (user_type, user_id, notification_id, notification_type, read_at)
            VALUES ('customer', :cid, :nid, :ntype, NOW())
        ");

        foreach ($adminIds as $aid) {
            $stmt->execute([':cid' => $customerId, ':nid' => (int)$aid, ':ntype' => 'admin']);
        }
        foreach ($userRows as $uid) {
            $stmt->execute([':cid' => $customerId, ':nid' => (int)$uid, ':ntype' => 'user']);
        }
        foreach ($orderRows as $o) {
            $statusKey = 'order_' . $o['order_id'] . '_' . strtolower($o['status']);
            // Store as user notification read
            $pdo->prepare("
                INSERT IGNORE INTO user_notification_reads (user_type, user_id, notification_id, notification_type, read_at)
                VALUES ('customer', ?, ?, ?, NOW())
            ")->execute([$customerId, (int)$o['order_id'], 'order_' . strtolower($o['status'])]);
        }

        // Also update user_notifications table directly if owned
        $pdo->prepare("UPDATE user_notifications SET is_read = 1 WHERE user_type = 'customer' AND user_id = ?")->execute([$customerId]);

        sendSuccess('All notifications marked as read.');
    } elseif (!empty($notifId)) {
        // Example: admin_21 or user_5 or order_92_assigned
        $parts = explode('_', $notifId);
        $sourceType = $parts[0] ?? 'admin';
        $rawId = isset($parts[1]) ? (int)$parts[1] : 0;

        if ($sourceType === 'order') {
            $statusSuffix = $parts[2] ?? '';
            $sourceType = 'order_' . $statusSuffix;
        }

        $stmt = $pdo->prepare("
            INSERT IGNORE INTO user_notification_reads (user_type, user_id, notification_id, notification_type, read_at)
            VALUES ('customer', :cid, :nid, :ntype, NOW())
        ");
        $stmt->execute([
            ':cid'   => $customerId,
            ':nid'   => $rawId,
            ':ntype' => $sourceType,
        ]);

        if ($sourceType === 'user') {
            $pdo->prepare("UPDATE user_notifications SET is_read = 1 WHERE id = ? AND (user_id = ? OR user_id IS NULL)")->execute([$rawId, $customerId]);
        }

        sendSuccess('Notification marked as read.');
    } else {
        sendError('Please provide notification_id or all: true', 422);
    }
} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
