<?php
// backend/api/vendor/orders/status.php
header('Content-Type: application/json; charset=utf-8');

require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../helpers/jwt.php';
require_once __DIR__ . '/../../../helpers/response.php';
require_once __DIR__ . '/../../../helpers/fcm.php';
require_once __DIR__ . '/../../../helpers/ably_helper.php';

// ── JWT Authentication ────────────────────────────────────────────────────────
$token   = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;

if (!$payload || ($payload['role'] ?? '') !== 'vendor') {
    sendError('Unauthorized access. Vendor token required.', 401);
}

$vendorId = (int)$payload['sub'];

// Read JSON input
$input = json_decode(file_get_contents('php://input'), true);
$orderId = isset($input['order_id']) ? (int)$input['order_id'] : 0;
$status = isset($input['status']) ? trim($input['status']) : '';

if ($orderId <= 0 || empty($status)) {
    sendError('Required fields: order_id and status.', 400);
}

// Validate status enum
$validStatuses = ['created_order', 'accepted', 'rejected', 'preparing', 'ready', 'completed', 'cancelled'];
if (!in_array($status, $validStatuses)) {
    sendError('Invalid order status. Allowed: ' . implode(', ', $validStatuses), 400);
}

try {
    $pdo = getDBConnection();
    
    // Check if order exists and belongs to this vendor
    $checkStmt = $pdo->prepare("
        SELECT o.status, o.customer_id, o.hotel_id, h.vendor_id, h.photo_url
        FROM orders o
        JOIN hotels h ON o.hotel_id = h.id
        WHERE o.order_id = ?
    ");
    $checkStmt->execute([$orderId]);
    $order = $checkStmt->fetch(PDO::FETCH_ASSOC);

    if (!$order) {
        sendError('Order not found.', 404);
    }

    if ((int)$order['vendor_id'] !== $vendorId) {
        sendError('Forbidden. You do not manage this hotel\'s orders.', 403);
    }

    // Update the status in DB
    $updateStmt = $pdo->prepare("UPDATE orders SET status = ?, updated_at = NOW() WHERE order_id = ?");
    $updateStmt->execute([$status, $orderId]);

    // If order is completed, process vendor wallet crediting (area tiffin charge) & subscription delivery deduction
    $creditedAmount = 0.00;
    if ($status === 'completed') {
        require_once __DIR__ . '/../../../helpers/vendor_wallet_helper.php';
        $creditedAmount = VendorWalletHelper::creditVendorWalletForOrder($pdo, $orderId);

        $orderSubStmt = $pdo->prepare("SELECT subscription_id, is_subscription_order FROM orders WHERE order_id = ?");
        $orderSubStmt->execute([$orderId]);
        $orderSub = $orderSubStmt->fetch(PDO::FETCH_ASSOC);

        if ($orderSub && $orderSub['is_subscription_order'] && $orderSub['subscription_id']) {
            $subId = (int)$orderSub['subscription_id'];

            // 1. Update subscription_deliveries status to COMPLETED
            $updDel = $pdo->prepare("UPDATE subscription_deliveries SET status = 'COMPLETED' WHERE order_id = ?");
            $updDel->execute([$orderId]);

            // 2. Fetch subscription for update
            $subDataStmt = $pdo->prepare("SELECT remaining_deliveries, completed_deliveries, total_deliveries, customer_id FROM customer_subscriptions WHERE id = ? FOR UPDATE");
            $subDataStmt->execute([$subId]);
            $subData = $subDataStmt->fetch(PDO::FETCH_ASSOC);

            if ($subData) {
                $rem = max(0, (int)$subData['remaining_deliveries'] - 1);
                $comp = (int)$subData['completed_deliveries'] + 1;
                
                $newStatus = 'ACTIVE';
                $expiryTime = null;
                if ($rem === 0) {
                    $newStatus = 'COMPLETED';
                    $expiryTime = date('Y-m-d H:i:s');
                }

                $updSub = $pdo->prepare("
                    UPDATE customer_subscriptions 
                    SET remaining_deliveries = ?, 
                        completed_deliveries = ?, 
                        status = ?, 
                        expiration_timestamp = ?,
                        updated_at = NOW() 
                    WHERE id = ?
                ");
                $updSub->execute([$rem, $comp, $newStatus, $expiryTime, $subId]);

                if ($rem === 0) {
                    // Cancel any remaining PENDING deliveries
                    $cancelDel = $pdo->prepare("UPDATE subscription_deliveries SET status = 'CANCELLED' WHERE subscription_id = ? AND status = 'PENDING'");
                    $cancelDel->execute([$subId]);
                    
                    // Send FCM notification
                    FcmHelper::sendToCustomer((int)$subData['customer_id'], "🍽️ Subscription Completed", "You have received all meals in your subscription. Renew now to get more meals!");
                }
            }
        }
    }

    $customerId = (int)$order['customer_id'];
    $hotelId = (int)$order['hotel_id'];

    // ── Send real-time notification via Ably ─────────────────
    try {
        $statusData = [
            'order_id'    => $orderId,
            'customer_id' => $customerId,
            'hotel_id'    => $hotelId,
            'vendor_id'   => $vendorId,
            'status'      => $status
        ];
        AblyHelper::publishOrderUpdate($orderId, $statusData);
        AblyHelper::publish('ORDER_STATUS_UPDATED', $statusData, AblyHelper::getVendorChannel($vendorId));

        if ($status === 'completed') {
            $actualCredit = ($creditedAmount > 0) ? $creditedAmount : 50.00;

            AblyHelper::publish('VENDOR_WALLET_UPDATED', [
                'order_id'      => $orderId,
                'vendor_id'     => $vendorId,
                'hotel_id'      => $hotelId,
                'credit_amount' => $actualCredit,
                'status'        => 'completed'
            ], AblyHelper::getVendorChannel($vendorId));

            AblyHelper::publish('VENDOR_WALLET_UPDATED', [
                'order_id'      => $orderId,
                'vendor_id'     => $vendorId,
                'credit_amount' => $actualCredit,
                'status'        => 'completed'
            ]);
        }

        // Send FCM Notifications
        $statusBody = "Your order #$orderId status has changed to: $status";
        if ($status === 'preparing') {
            $statusBody = "Your order #$orderId is being prepared.";
        } elseif ($status === 'ready') {
            $statusBody = "Your order #$orderId is ready for pickup.";
        } elseif ($status === 'completed') {
            $statusBody = "Your order #$orderId has been delivered and completed.";
        } elseif ($status === 'cancelled') {
            $statusBody = "Your order #$orderId has been cancelled.";
        } elseif ($status === 'rejected') {
            $statusBody = "Your order #$orderId has been rejected by the kitchen.";
        } elseif ($status === 'accepted') {
            $statusBody = "Your order #$orderId has been accepted by the kitchen.";
        }

        FcmHelper::sendToCustomer($customerId, "Order Status Update", $statusBody, [
            'order_id'  => (string)$orderId,
            'event'     => 'ORDER_STATUS_UPDATED',
            'status'    => $status,
            'image_url' => $order['photo_url'] ?? ''
        ]);
    } catch (Throwable $e) {
        error_log("Notification error in status.php: " . $e->getMessage());
    }

    sendSuccess('Order status updated successfully.', [
        'order_id' => $orderId,
        'status'   => $status
    ]);

} catch (Throwable $e) {
    sendError('Database or system error: ' . $e->getMessage(), 500);
}
