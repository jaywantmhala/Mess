<?php
/**
 * POST /api/driver/orders/status
 * Updates the status of an assigned order.
 * Requires: Authorization: Bearer <JWT>
 * Body: { order_id, status }
 */

header('Content-Type: application/json; charset=utf-8');

require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../helpers/jwt.php';
require_once __DIR__ . '/../../../helpers/response.php';
require_once __DIR__ . '/../../../helpers/fcm.php';
require_once __DIR__ . '/../../../helpers/ably_helper.php';

// ── JWT Authentication ────────────────────────────────────────────────────────
$token   = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;

if (!$payload || ($payload['role'] ?? '') !== 'driver') {
    sendError('Unauthorized access. Driver token required.', 401);
}

$driverId = (int)$payload['sub'];

function getDistance($lat1, $lon1, $lat2, $lon2) {
    $earthRadius = 6371000; // in meters
    $latFrom = deg2rad($lat1);
    $lonFrom = deg2rad($lon1);
    $latTo = deg2rad($lat2);
    $lonTo = deg2rad($lon2);
    $latDelta = $latTo - $latFrom;
    $lonDelta = $lonTo - $lonFrom;
    $angle = 2 * asin(sqrt(pow(sin($latDelta / 2), 2) +
      cos($latFrom) * cos($latTo) * pow(sin($lonDelta / 2), 2)));
    return $angle * $earthRadius;
}

// Read JSON input
$input = json_decode(file_get_contents('php://input'), true);
$orderId = isset($input['order_id']) ? (int)$input['order_id'] : 0;
$status = isset($input['status']) ? trim($input['status']) : '';

if ($orderId <= 0 || empty($status)) {
    sendError('Required fields: order_id and status.', 400);
}

// Validate status enum
$validStatuses = ['accepted_by_driver', 'picked_up', 'arrived_at_customer', 'completed'];
if (!in_array($status, $validStatuses)) {
    sendError('Invalid order status. Allowed: ' . implode(', ', $validStatuses), 400);
}

try {
    $pdo = getDBConnection();
    
    // Check if order exists and belongs to this driver
    $checkStmt = $pdo->prepare("
        SELECT o.driver_id, o.customer_id, o.hotel_id, o.status, o.delivery_otp, h.photo_url
        FROM orders o
        JOIN hotels h ON o.hotel_id = h.id
        WHERE o.order_id = ?
    ");
    $checkStmt->execute([$orderId]);
    $order = $checkStmt->fetch(PDO::FETCH_ASSOC);

    if (!$order) {
        sendError('Order not found.', 404);
    }

    if ((int)$order['driver_id'] !== $driverId) {
        sendError('Forbidden. This order is not assigned to you.', 403);
    }

    // ── Enforce 50m radius check for arrived_at_customer ─────────────────
    if ($status === 'arrived_at_customer') {
        $driverStmt = $pdo->prepare("SELECT latitude, longitude FROM drivers WHERE id = ? LIMIT 1");
        $driverStmt->execute([$driverId]);
        $driverCoords = $driverStmt->fetch(PDO::FETCH_ASSOC);
        $driverLat = $driverCoords ? (float)$driverCoords['latitude'] : 0.0;
        $driverLng = $driverCoords ? (float)$driverCoords['longitude'] : 0.0;

        $addrStmt = $pdo->prepare("SELECT latitude, longitude FROM customer_addresses WHERE customer_id = ? LIMIT 1");
        $addrStmt->execute([(int)$order['customer_id']]);
        $custAddr = $addrStmt->fetch(PDO::FETCH_ASSOC);
        $custLat = $custAddr ? (float)$custAddr['latitude'] : 0.0;
        $custLng = $custAddr ? (float)$custAddr['longitude'] : 0.0;

        if ($custLat !== 0.0 && $custLng !== 0.0 && $driverLat !== 0.0 && $driverLng !== 0.0) {
            $distance = getDistance($driverLat, $driverLng, $custLat, $custLng);
            if ($distance > 50) {
                sendError("You must be within 50 meters of the customer's location to confirm arrival. Current distance: " . round($distance, 1) . "m", 400);
            }
        }
    }

    // ── Enforce OTP-based delivery confirmation for completed ────────────
    if ($status === 'completed') {
        $otp = isset($input['otp']) ? trim($input['otp']) : '';
        if (empty($otp)) {
            sendError('Delivery OTP is required to complete delivery.', 400);
        }
        if ($order['delivery_otp'] !== $otp) {
            sendError('Invalid delivery OTP. Please try again.', 400);
        }
    }

    // Update the status in DB
    if ($status === 'completed') {
        $updateStmt = $pdo->prepare("UPDATE orders SET status = ?, delivered_at = NOW(), updated_at = NOW() WHERE order_id = ?");
    } else {
        $updateStmt = $pdo->prepare("UPDATE orders SET status = ?, updated_at = NOW() WHERE order_id = ?");
    }
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

    // If order is completed, check for previous pending tiffin returns from the SAME driver AND SAME hotel
    $hasPendingTiffin = false;
    $pendingTiffinOrder = null;
    $tiffinPayload = null;

    if ($status === 'completed') {
        $pendingStmt = $pdo->prepare("
            SELECT 
                o.order_id AS previous_order_id, 
                o.customer_id, 
                o.hotel_id, 
                o.tiffin_return_otp AS otp,
                h.hotel_name
            FROM orders o
            JOIN hotels h ON o.hotel_id = h.id
            WHERE o.driver_id = :driver_id
              AND o.hotel_id = :hotel_id
              AND o.customer_id = :customer_id
              AND o.tiffin_received_to_hotel = 'pending' 
              AND o.order_id < :current_order_id 
              AND o.status = 'completed'
            ORDER BY o.order_id DESC 
            LIMIT 1
        ");
        $pendingStmt->execute([
            ':driver_id'        => $driverId,
            ':hotel_id'         => $hotelId,
            ':customer_id'      => $customerId,
            ':current_order_id' => $orderId
        ]);
        $pendingTiffinOrder = $pendingStmt->fetch(PDO::FETCH_ASSOC);
        
        if ($pendingTiffinOrder) {
            $hasPendingTiffin = true;
            $prevOrderId = (int)$pendingTiffinOrder['previous_order_id'];

            // Generate 4-digit OTP if missing
            $otp = $pendingTiffinOrder['otp'];
            if (empty($otp)) {
                $otp = strval(rand(1000, 9999));
                $otpStmt = $pdo->prepare("UPDATE orders SET tiffin_return_otp = ? WHERE order_id = ?");
                $otpStmt->execute([$otp, $prevOrderId]);
                $pendingTiffinOrder['otp'] = $otp;
            }
        }
    }

    // ── Send real-time notification via Ably ─────────────────
    try {
        $statusData = [
            'order_id'    => $orderId,
            'customer_id' => $customerId,
            'hotel_id'    => $hotelId,
            'driver_id'   => $driverId,
            'status'      => $status
        ];
        AblyHelper::publishOrderUpdate($orderId, $statusData);

        if ($status === 'completed') {
            $vStmt = $pdo->prepare("SELECT vendor_id FROM hotels WHERE id = ? LIMIT 1");
            $vStmt->execute([$hotelId]);
            $vId = (int)$vStmt->fetchColumn();

            $actualCredit = ($creditedAmount > 0) ? $creditedAmount : 50.00;

            AblyHelper::publish('VENDOR_WALLET_UPDATED', [
                'order_id'      => $orderId,
                'vendor_id'     => $vId,
                'hotel_id'      => $hotelId,
                'credit_amount' => $actualCredit,
                'status'        => 'completed'
            ], AblyHelper::getVendorChannel($vId));

            AblyHelper::publish('VENDOR_WALLET_UPDATED', [
                'order_id'      => $orderId,
                'vendor_id'     => $vId,
                'credit_amount' => $actualCredit,
                'status'        => 'completed'
            ]);
        }

        // Send FCM Notifications
        $statusBody = "Your order #$orderId status has changed to: $status";
        if ($status === 'accepted_by_driver') {
            $statusBody = "Driver has accepted your order #$orderId.";
        } elseif ($status === 'picked_up') {
            $statusBody = "Your order #$orderId has been picked up and is on the way.";
        } elseif ($status === 'arrived_at_customer') {
            $statusBody = "Your delivery partner has arrived at your location!";
        } elseif ($status === 'completed') {
            $statusBody = "Your order #$orderId has been delivered.";
        }

        FcmHelper::sendToCustomer($customerId, "Order Status Update", $statusBody, [
            'order_id'  => $orderId,
            'event'     => 'ORDER_STATUS_UPDATED',
            'status'    => $status,
            'image_url' => $order['photo_url'] ?? ''
        ]);

        // If there's a pending tiffin from the SAME driver & SAME hotel, publish tiffin-return-required event
        if ($hasPendingTiffin && $pendingTiffinOrder) {
            $prevOrderId = (int)$pendingTiffinOrder['previous_order_id'];
            $hotelName   = $pendingTiffinOrder['hotel_name'] ?: 'Restaurant';

            $tiffinPayload = [
                'event'                   => 'tiffin-return-required',
                'order_id'                => $orderId,
                'current_order_id'        => $orderId,
                'previous_order_id'       => $prevOrderId,
                'pending_tiffin_order_id' => $prevOrderId,
                'customer_id'             => (int)$pendingTiffinOrder['customer_id'],
                'driver_id'               => $driverId,
                'hotel_id'                => $hotelId,
                'hotel_name'              => $hotelName,
                'message'                 => "Previous Tiffin Return Required. Please return the previous tiffin from $hotelName.",
                'action'                  => 'SCAN_BARCODE',
                'otp'                     => $pendingTiffinOrder['otp']
            ];

            $driverChannel = AblyHelper::getDriverChannel($driverId);
            AblyHelper::publish('tiffin-return-required', $tiffinPayload, $driverChannel);
            AblyHelper::publish('tiffin-return-required', $tiffinPayload, "driver_{$driverId}");
            AblyHelper::publish('PENDING_TIFFIN_RETURN', $tiffinPayload, $driverChannel);
            AblyHelper::publish('PENDING_TIFFIN_RETURN', $tiffinPayload, "driver_{$driverId}");

            FcmHelper::sendToCustomer((int)$pendingTiffinOrder['customer_id'], "Tiffin Return OTP", "Please share OTP " . $pendingTiffinOrder['otp'] . " with the driver to return your empty tiffin from $hotelName.", [
                'order_id'          => $orderId,
                'previous_order_id' => $prevOrderId,
                'event'             => 'PENDING_TIFFIN_RETURN',
                'otp'               => $pendingTiffinOrder['otp']
            ]);
        }
    } catch (Throwable $e) {
        error_log("Notification error in driver status.php: " . $e->getMessage());
    }

    $responsePayload = [
        'order_id' => $orderId,
        'status'   => $status
    ];
    if ($hasPendingTiffin && !empty($tiffinPayload)) {
        $responsePayload['has_pending_tiffin'] = true;
        $responsePayload['pending_tiffin']     = $tiffinPayload;
    }

    sendSuccess('Order status updated successfully.', $responsePayload);

} catch (Throwable $e) {
    sendError('Database or system error: ' . $e->getMessage(), 500);
}
