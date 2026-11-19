<?php
/**
 * GET /api/customer/notifications
 *
 * Returns notifications relevant to the authenticated customer:
 * - Admin broadcasts targeted to 'customers' or 'all'
 * - Direct notifications sent to this customer
 * - Real-time order milestone updates
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/jwt.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    sendError('Method not allowed. Use GET.', 405);
}

$token   = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;

$customerId = ($payload && isset($payload['sub'])) ? (int)$payload['sub'] : null;

$pdo = getDBConnection();

try {
    $notifications = [];
    $customerState = '';
    $customerDistrict = '';

    if ($customerId) {
        $cStmt = $pdo->prepare("SELECT state, district FROM customers WHERE id = ? LIMIT 1");
        $cStmt->execute([$customerId]);
        $cRow = $cStmt->fetch(PDO::FETCH_ASSOC);
        if ($cRow) {
            $customerState = trim($cRow['state'] ?? '');
            $customerDistrict = trim($cRow['district'] ?? '');
        }

        // Also check primary address
        if (empty($customerState) || empty($customerDistrict)) {
            $addrStmt = $pdo->prepare("SELECT state, district FROM customer_addresses WHERE customer_id = ? ORDER BY is_default DESC, id DESC LIMIT 1");
            $addrStmt->execute([$customerId]);
            $addrRow = $addrStmt->fetch(PDO::FETCH_ASSOC);
            if ($addrRow) {
                if (empty($customerState)) $customerState = trim($addrRow['state'] ?? '');
                if (empty($customerDistrict)) $customerDistrict = trim($addrRow['district'] ?? '');
            }
        }
    }

    // 1. Fetch Admin Broadcasts targeted to customers or all
    $adminSql = "
        SELECT id, title, body, target, state, district, taluka, click_action, image_url, created_at
        FROM admin_notifications
        WHERE target IN ('customers', 'all')
        ORDER BY id DESC
        LIMIT 40
    ";
    $adminStmt = $pdo->query($adminSql);
    $adminRows = $adminStmt->fetchAll(PDO::FETCH_ASSOC);

    // Fetch read notification IDs for this customer
    $readIds = [];
    if ($customerId) {
        $rStmt = $pdo->prepare("SELECT notification_id, notification_type FROM user_notification_reads WHERE user_type = 'customer' AND user_id = ?");
        $rStmt->execute([$customerId]);
        while ($r = $rStmt->fetch(PDO::FETCH_ASSOC)) {
            $readIds[$r['notification_type'] . '_' . $r['notification_id']] = true;
        }
    }

    foreach ($adminRows as $row) {
        // Apply location filter if specified on notification
        if (!empty($row['state']) && !empty($customerState) && strcasecmp($row['state'], $customerState) !== 0) {
            continue;
        }
        if (!empty($row['district']) && !empty($customerDistrict) && strcasecmp($row['district'], $customerDistrict) !== 0) {
            continue;
        }

        $uniqueKey = 'admin_' . $row['id'];
        $isRead = isset($readIds[$uniqueKey]);

        $notifications[] = [
            'id'           => $uniqueKey,
            'raw_id'       => (int)$row['id'],
            'source'       => 'admin',
            'title'        => $row['title'],
            'body'         => $row['body'],
            'type'         => 'broadcast',
            'image_url'    => $row['image_url'] ?: null,
            'click_action' => $row['click_action'] ?: 'HOME',
            'created_at'   => $row['created_at'],
            'is_read'      => $isRead,
            'meta'         => [
                'target'   => $row['target'],
            ]
        ];
    }

    // 2. Fetch User-specific Notifications (if customer logged in)
    if ($customerId) {
        $userSql = "
            SELECT id, title, body, type, image_url, data, is_read, created_at
            FROM user_notifications
            WHERE user_type IN ('customer', 'all') AND (user_id = :cid OR user_id IS NULL)
            ORDER BY id DESC
            LIMIT 40
        ";
        $uStmt = $pdo->prepare($userSql);
        $uStmt->execute([':cid' => $customerId]);
        $uRows = $uStmt->fetchAll(PDO::FETCH_ASSOC);

        foreach ($uRows as $row) {
            $uniqueKey = 'user_' . $row['id'];
            $isRead = (bool)$row['is_read'] || isset($readIds[$uniqueKey]);
            $parsedData = !empty($row['data']) ? json_decode($row['data'], true) : [];

            $notifications[] = [
                'id'           => $uniqueKey,
                'raw_id'       => (int)$row['id'],
                'source'       => 'user',
                'title'        => $row['title'],
                'body'         => $row['body'],
                'type'         => $row['type'] ?: 'general',
                'image_url'    => $row['image_url'] ?: null,
                'click_action' => $parsedData['click_action'] ?? 'ORDERS',
                'created_at'   => $row['created_at'],
                'is_read'      => $isRead,
                'meta'         => $parsedData ?: new stdClass()
            ];
        }

        // 3. Synthesize Recent Order Status Notifications
        $orderSql = "
            SELECT o.order_id, o.status, o.grand_total, o.created_at, o.updated_at, h.hotel_name
            FROM orders o
            LEFT JOIN hotels h ON h.id = o.hotel_id
            WHERE o.customer_id = :cid
            ORDER BY o.order_id DESC
            LIMIT 15
        ";
        $oStmt = $pdo->prepare($orderSql);
        $oStmt->execute([':cid' => $customerId]);
        $orderRows = $oStmt->fetchAll(PDO::FETCH_ASSOC);

        foreach ($orderRows as $o) {
            $status = strtolower($o['status']);
            $orderId = (int)$o['order_id'];
            $hotelName = $o['hotel_name'] ?: 'Restaurant';
            $uniqueKey = 'order_' . $orderId . '_' . $status;
            $isRead = isset($readIds[$uniqueKey]);

            $title = '';
            $body = '';

            switch ($status) {
                case 'placed':
                case 'pending':
                    $title = 'Order Placed successfully';
                    $body  = "Your order #$orderId at $hotelName has been placed.";
                    break;
                case 'accepted':
                    $title = 'Order Accepted';
                    $body  = "$hotelName has accepted your order #$orderId and is preparing your food.";
                    break;
                case 'assigned':
                case 'out_for_delivery':
                    $title = 'Out for Delivery';
                    $body  = "A delivery partner has been assigned to order #$orderId and is on the way.";
                    break;
                case 'delivered':
                case 'completed':
                    $title = 'Order Delivered';
                    $body  = "Your delicious meal for order #$orderId from $hotelName has been delivered! Enjoy your food.";
                    break;
                case 'cancelled':
                    $title = 'Order Cancelled';
                    $body  = "Order #$orderId from $hotelName was cancelled.";
                    break;
                default:
                    $title = 'Order Update: #' . $orderId;
                    $body  = "Your order status is now: " . ucfirst($status);
                    break;
            }

            $notifications[] = [
                'id'           => $uniqueKey,
                'raw_id'       => $orderId,
                'source'       => 'order',
                'title'        => $title,
                'body'         => $body,
                'type'         => 'order',
                'image_url'    => null,
                'click_action' => 'ORDER_STATUS',
                'created_at'   => $o['updated_at'] ?: $o['created_at'],
                'is_read'      => $isRead,
                'meta'         => [
                    'order_id' => $orderId,
                    'status'   => $status,
                ]
            ];
        }
    }

    // Sort all notifications chronologically descending (newest first)
    usort($notifications, function ($a, $b) {
        return strtotime($b['created_at']) <=> strtotime($a['created_at']);
    });

    // Calculate unread count
    $unreadCount = 0;
    foreach ($notifications as $n) {
        if (!$n['is_read']) {
            $unreadCount++;
        }
    }

    sendSuccess('Customer notifications retrieved successfully.', [
        'unread_count'  => $unreadCount,
        'total'         => count($notifications),
        'notifications' => $notifications
    ]);

} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
