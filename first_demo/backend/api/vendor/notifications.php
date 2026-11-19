<?php
/**
 * GET /api/vendor/notifications
 *
 * Returns notifications relevant to the authenticated vendor:
 * - Admin broadcasts targeted to 'vendors' or 'all'
 * - Direct notifications sent to this vendor
 * - Order and delivery partner updates for vendor's hotels
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

if (!$payload || !isset($payload['sub'])) {
    sendError('Unauthorized. Vendor access required.', 401);
}

$vendorId = (int)$payload['sub'];
$pdo = getDBConnection();

try {
    $notifications = [];
    $vendorStates = [];
    $vendorDistricts = [];
    $vendorTalukas = [];

    // Get vendor details including state, district, taluka
    $vStmt = $pdo->prepare("SELECT state, district, taluka FROM vendors WHERE id = ? LIMIT 1");
    $vStmt->execute([$vendorId]);
    $vRow = $vStmt->fetch(PDO::FETCH_ASSOC);
    if ($vRow) {
        if (!empty($vRow['state']))    $vendorStates[] = trim($vRow['state']);
        if (!empty($vRow['district'])) $vendorDistricts[] = trim($vRow['district']);
        if (!empty($vRow['taluka']))   $vendorTalukas[] = trim($vRow['taluka']);
    }

    $hotelStmt = $pdo->prepare("SELECT id, hotel_name, city, district, state, taluka FROM hotels WHERE vendor_id = ?");
    $hotelStmt->execute([$vendorId]);
    $hotels = $hotelStmt->fetchAll(PDO::FETCH_ASSOC);
    $hotelIds = array_column($hotels, 'id');
    $hotelNames = [];
    foreach ($hotels as $h) {
        $hotelNames[$h['id']] = $h['hotel_name'];
        if (!empty($h['state']))    $vendorStates[] = trim($h['state']);
        if (!empty($h['district'])) $vendorDistricts[] = trim($h['district']);
        if (!empty($h['city']))     $vendorDistricts[] = trim($h['city']); // city is often used as district in hotel profiles
        if (!empty($h['taluka']))   $vendorTalukas[] = trim($h['taluka']);
    }

    $vendorStates    = array_unique(array_filter($vendorStates));
    $vendorDistricts = array_unique(array_filter($vendorDistricts));
    $vendorTalukas   = array_unique(array_filter($vendorTalukas));

    // Read status lookup
    $readIds = [];
    $rStmt = $pdo->prepare("SELECT notification_id, notification_type FROM user_notification_reads WHERE user_type = 'vendor' AND user_id = ?");
    $rStmt->execute([$vendorId]);
    while ($r = $rStmt->fetch(PDO::FETCH_ASSOC)) {
        $readIds[$r['notification_type'] . '_' . $r['notification_id']] = true;
    }

    // 1. Fetch Admin Broadcasts targeted to vendors or all
    $adminSql = "
        SELECT id, title, body, target, state, district, taluka, click_action, image_url, created_at
        FROM admin_notifications
        WHERE LOWER(target) IN ('vendors', 'vendor', 'all')
        ORDER BY id DESC
        LIMIT 100
    ";
    $adminStmt = $pdo->query($adminSql);
    $adminRows = $adminStmt->fetchAll(PDO::FETCH_ASSOC);

    foreach ($adminRows as $row) {
        $reqState    = trim($row['state'] ?? '');
        $reqDistrict = trim($row['district'] ?? '');
        $reqTaluka   = trim($row['taluka'] ?? '');

        // State filter
        if (!empty($reqState) && strcasecmp($reqState, 'all') !== 0 && !empty($vendorStates)) {
            $matchedState = false;
            foreach ($vendorStates as $vs) {
                if (strcasecmp($reqState, $vs) === 0) {
                    $matchedState = true;
                    break;
                }
            }
            if (!$matchedState) {
                continue;
            }
        }

        // District filter
        if (!empty($reqDistrict) && strcasecmp($reqDistrict, 'all') !== 0 && !empty($vendorDistricts)) {
            $matchedDistrict = false;
            foreach ($vendorDistricts as $vd) {
                if (strcasecmp($reqDistrict, $vd) === 0) {
                    $matchedDistrict = true;
                    break;
                }
            }
            if (!$matchedDistrict) {
                continue;
            }
        }

        // Taluka filter
        if (!empty($reqTaluka) && strcasecmp($reqTaluka, 'all') !== 0 && !empty($vendorTalukas)) {
            $matchedTaluka = false;
            foreach ($vendorTalukas as $vt) {
                if (strcasecmp($reqTaluka, $vt) === 0) {
                    $matchedTaluka = true;
                    break;
                }
            }
            if (!$matchedTaluka) {
                continue;
            }
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
                'state'    => $row['state'],
                'district' => $row['district'],
                'taluka'   => $row['taluka'],
            ]
        ];
    }

    // 2. Fetch Direct Vendor Notifications from user_notifications table
    $userSql = "
        SELECT id, title, body, type, image_url, data, is_read, created_at
        FROM user_notifications
        WHERE LOWER(user_type) IN ('vendor', 'vendors', 'all') AND (user_id = :vid OR user_id IS NULL)
        ORDER BY id DESC
        LIMIT 100
    ";
    $uStmt = $pdo->prepare($userSql);
    $uStmt->execute([':vid' => $vendorId]);
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

    // 3. Synthesize Recent Orders for this Vendor's Hotels
    if (!empty($hotelIds)) {
        $inClause = implode(',', array_map('intval', $hotelIds));
        $orderSql = "
            SELECT o.order_id, o.hotel_id, o.status, o.grand_total, o.created_at, o.updated_at,
                   c.full_name AS customer_name, d.full_name AS driver_name
            FROM orders o
            LEFT JOIN customers c ON c.id = o.customer_id
            LEFT JOIN drivers d ON d.id = o.driver_id
            WHERE o.hotel_id IN ($inClause)
            ORDER BY o.order_id DESC
            LIMIT 20
        ";
        $oStmt = $pdo->query($orderSql);
        $orderRows = $oStmt->fetchAll(PDO::FETCH_ASSOC);

        foreach ($orderRows as $o) {
            $status = strtolower($o['status']);
            $orderId = (int)$o['order_id'];
            $hotelName = $hotelNames[$o['hotel_id']] ?? 'Your Restaurant';
            $custName = $o['customer_name'] ?: 'Customer';
            $driverName = $o['driver_name'] ?: 'Driver';
            $uniqueKey = 'vendor_order_' . $orderId . '_' . $status;
            $isRead = isset($readIds[$uniqueKey]);

            $title = '';
            $body = '';

            switch ($status) {
                case 'placed':
                case 'pending':
                    $title = '🔔 New Order Received! #' . $orderId;
                    $body  = "New order received from $custName at $hotelName. Total: ₹" . number_format((float)$o['grand_total'], 2);
                    break;
                case 'assigned':
                    $title = '🚚 Driver Assigned for Order #' . $orderId;
                    $body  = "$driverName is assigned to pick up order #$orderId from $hotelName.";
                    break;
                case 'completed':
                case 'delivered':
                    $title = '✅ Order #' . $orderId . ' Delivered';
                    $body  = "Order #$orderId has been delivered successfully to $custName.";
                    break;
                case 'cancelled':
                    $title = '❌ Order #' . $orderId . ' Cancelled';
                    $body  = "Order #$orderId at $hotelName was cancelled.";
                    break;
                default:
                    $title = 'Order #' . $orderId . ' Update';
                    $body  = "Order status is now " . ucfirst($status) . " at $hotelName.";
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
                'click_action' => 'ORDER_DETAILS',
                'created_at'   => $o['updated_at'] ?: $o['created_at'],
                'is_read'      => $isRead,
                'meta'         => [
                    'order_id' => $orderId,
                    'status'   => $status,
                    'hotel_id' => (int)$o['hotel_id'],
                ]
            ];
        }
    }

    // Sort chronologically descending
    usort($notifications, function ($a, $b) {
        return strtotime($b['created_at']) <=> strtotime($a['created_at']);
    });

    // Unread count
    $unreadCount = 0;
    foreach ($notifications as $n) {
        if (!$n['is_read']) {
            $unreadCount++;
        }
    }

    sendSuccess('Vendor notifications retrieved successfully.', [
        'unread_count'  => $unreadCount,
        'total'         => count($notifications),
        'notifications' => $notifications
    ]);

} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
