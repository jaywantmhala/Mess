<?php
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/jwt.php';
require_once __DIR__ . '/../../helpers/ably_helper.php';
require_once __DIR__ . '/../../helpers/meal_helper.php';
require_once __DIR__ . '/../../helpers/tiffin_charge_helper.php';
require_once __DIR__ . '/../../helpers/redis_helper.php';


header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'POST') { sendError('Method not allowed.', 405); }

$token = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;
if (!$payload || !isset($payload['sub'])) { sendError('Unauthorized.', 401); }
$customerId = (int) $payload['sub'];

$body = json_decode(file_get_contents('php://input'), true);
if (!isset($body['payment_method'], $body['delivery_address'])) {
    sendError('payment_method and delivery_address are required.', 422);
}

$paymentMethod   = trim((string) $body['payment_method']);
$deliveryAddress = trim((string) ($body['delivery_address'] ?? ''));

if ($paymentMethod === '') { sendError('payment_method cannot be empty.', 422); }

// Determine meal timing (Asia/Kolkata, fallback to 'Dinner')
$mealType = getCurrentMealType() ?? 'Dinner';

// Concurrency Control: Acquire atomic lock to prevent double-tap race conditions
$orderLockKey = "customer:{$customerId}:order";
$orderLockToken = null;
if (!RedisHelper::lock($orderLockKey, 4, $orderLockToken)) {
    sendError('An order placement is already in progress. Please wait a moment.', 429);
}

try {
    $pdo = getDBConnection();

    // ── If deliveryAddress is empty, fetch customer's active default address ──
    if (empty($deliveryAddress)) {
        try {
            $addrStmt = $pdo->prepare("
                SELECT id, tag, house_no, full_address, landmark, area, city, pincode, latitude, longitude
                FROM customer_addresses
                WHERE customer_id = ? AND is_default = 1
                LIMIT 1
            ");
            $addrStmt->execute([$customerId]);
            $activeAddr = $addrStmt->fetch(PDO::FETCH_ASSOC);

            if ($activeAddr && !empty($activeAddr['full_address'])) {
                $tagEmoji = ($activeAddr['tag'] === 'OFFICE' || $activeAddr['tag'] === 'WORK') ? '🏢' : (($activeAddr['tag'] === 'HOME') ? '🏠' : '📍');
                $tagText  = ucfirst(strtolower($activeAddr['tag']));
                $parts    = [];
                if (!empty($activeAddr['house_no'])) $parts[] = $activeAddr['house_no'];
                if (!empty($activeAddr['full_address'])) $parts[] = $activeAddr['full_address'];
                if (!empty($activeAddr['landmark'])) $parts[] = "Landmark: " . $activeAddr['landmark'];
                $deliveryAddress = "$tagEmoji $tagText: " . implode(', ', $parts);
            }
        } catch (Exception $addrEx) {
            // Fallback
        }
    }

    if (empty($deliveryAddress)) { sendError('delivery_address cannot be empty.', 422); }

    $pdo->beginTransaction();

    // ── 1. Fetch all cart items ──────────────────────────────────────────────
    $cartStmt = $pdo->prepare(
        "SELECT ci.cart_item_id, ci.menu_item_id, ci.hotel_id, ci.quantity, ci.customizations,
                m.price, m.food_name AS item_name, m.mandatory_items
         FROM cart_items ci
         JOIN menus m ON m.id = ci.menu_item_id
         WHERE ci.customer_id = ?
         FOR UPDATE"
    );
    $cartStmt->execute([$customerId]);
    $cartItems = $cartStmt->fetchAll(PDO::FETCH_ASSOC);

    if (empty($cartItems)) {
        $pdo->rollBack();
        sendError('Your cart is empty.', 422);
    }

    $hotelId  = (int) $cartItems[0]['hotel_id'];
    $subtotal = 0.0;
    foreach ($cartItems as $item) {
        $subtotal += (float)$item['price'] * (int)$item['quantity'];
    }

    // Resolve the customer's area tiffin charge dynamically
    $areaInfo = resolveAreaTiffinCharge($pdo, $customerId, $hotelId);
    $areaTiffinCharge = (float)$areaInfo['tiffin_charge'];
    $areaName = $areaInfo['area_name'] ?? 'Area';

    $deliveryFee = 0.00;
    $taxAmount   = 0.00;
    $grandTotal  = round($subtotal + $deliveryFee + $taxAmount + $areaTiffinCharge, 2);

    // ── 3. Get / create wallet (with row lock) ───────────────────────────────
    $wStmt = $pdo->prepare("SELECT wallet_id, balance FROM wallets WHERE customer_id = ? FOR UPDATE");
    $wStmt->execute([$customerId]);
    $wallet = $wStmt->fetch(PDO::FETCH_ASSOC);

    if (!$wallet) {
        $wIns = $pdo->prepare("INSERT INTO wallets (customer_id, balance) VALUES (?, 0.00)");
        $wIns->execute([$customerId]);
        $walletId      = (int) $pdo->lastInsertId();
        $walletBalance = 0.00;
    } else {
        $walletId      = (int) $wallet['wallet_id'];
        $walletBalance = (float) $wallet['balance'];
    }

    // ── 4 & 5. Area Tiffin Charge & Wallet deduction logic ──────────────────
    $subStmt = $pdo->prepare("
        SELECT id, remaining_deliveries, status 
        FROM customer_subscriptions 
        WHERE customer_id = ? 
          AND status = 'ACTIVE' 
          AND end_date >= CURDATE() 
          AND remaining_deliveries > 0
        LIMIT 1
    ");
    $subStmt->execute([$customerId]);
    $activeSub = $subStmt->fetch(PDO::FETCH_ASSOC);

    $isSubscriptionOrder = 0;
    $subscriptionId = null;

    // Verify wallet balance against area-wise tiffin charge
    if ($walletBalance < $areaTiffinCharge) {
        throw new Exception("Insufficient wallet balance. Minimum ₹" . number_format($areaTiffinCharge, 2) . " ($areaName Tiffin Charge) required in wallet to place an order.", 422);
    }

    $walletDeducted   = $areaTiffinCharge;
    $remainingPayable = round(max(0.0, $grandTotal - $walletDeducted), 2);

    if (strtoupper($paymentMethod) === 'WALLET' && $walletBalance >= $grandTotal) {
        // Customer has sufficient balance to cover the entire order including tiffin charge
        $walletDeducted   = $grandTotal;
        $remainingPayable = 0.00;
    }

    if ($activeSub) {
        $isSubscriptionOrder = 1;
        $subscriptionId = (int)$activeSub['id'];
        if (strtoupper($paymentMethod) !== 'WALLET') {
            $remainingPayable = 0.00;
        }
    }


    // ── 6. Insert order ──────────────────────────────────────────────────────
    $deliveryOtp = strval(rand(1000, 9999));
    $orderStmt = $pdo->prepare(
        "INSERT INTO orders
            (customer_id, hotel_id, subtotal, delivery_fee, tax_amount,
             grand_total, wallet_deducted, payment_method, delivery_address, status, delivery_otp, subscription_id, is_subscription_order, meal_type, tiffin_charge, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'created_order', ?, ?, ?, ?, ?, NOW())"
    );
    $orderStmt->execute([
        $customerId,
        $hotelId,
        $subtotal,
        $deliveryFee,
        $taxAmount,
        $grandTotal,
        $walletDeducted,
        $paymentMethod,
        $deliveryAddress,
        $deliveryOtp,
        $subscriptionId,
        $isSubscriptionOrder,
        $mealType,
        $areaTiffinCharge
    ]);
    $orderId = (int) $pdo->lastInsertId();

    // If subscription order, update remaining deliveries and link delivery
    if ($isSubscriptionOrder && $subscriptionId) {
        $updSubStmt = $pdo->prepare("
            UPDATE customer_subscriptions
            SET remaining_deliveries = GREATEST(0, remaining_deliveries - 1),
                completed_deliveries = completed_deliveries + 1
            WHERE id = ?
        ");
        $updSubStmt->execute([$subscriptionId]);

        $pendingDelStmt = $pdo->prepare("
            SELECT id FROM subscription_deliveries 
            WHERE subscription_id = ? AND status = 'PENDING' 
            ORDER BY delivery_date ASC LIMIT 1
        ");
        $pendingDelStmt->execute([$subscriptionId]);
        $pendingDelId = $pendingDelStmt->fetchColumn();
        if ($pendingDelId) {
            $updDelStmt = $pdo->prepare("UPDATE subscription_deliveries SET status = 'GENERATED', order_id = ? WHERE id = ?");
            $updDelStmt->execute([$orderId, $pendingDelId]);
        }
    }

    // ── 7. Insert order items ────────────────────────────────────────────────
    $itemStmt = $pdo->prepare(
        "INSERT INTO order_items (order_id, menu_item_id, quantity, price, mandatory_items, customizations)
         VALUES (?, ?, ?, ?, ?, ?)"
    );
    foreach ($cartItems as $item) {
        $itemStmt->execute([
            $orderId,
            (int)   $item['menu_item_id'],
            (int)   $item['quantity'],
            (float) $item['price'],
            $item['mandatory_items'],
            $item['customizations'],
        ]);
    }

    // ── 8. Wallet deduction transaction ─────────────────────────────────────
    $newWalletBalance = $walletBalance;
    if ($walletDeducted > 0) {
        $newWalletBalance = round($walletBalance - $walletDeducted, 2);

        $wUpd = $pdo->prepare("UPDATE wallets SET balance = ? WHERE wallet_id = ?");
        $wUpd->execute([$newWalletBalance, $walletId]);

        $wTxn = $pdo->prepare(
            "INSERT INTO wallet_transactions (wallet_id, type, amount, description, balance_after)
             VALUES (?, 'DEBIT', ?, ?, ?)"
        );
        $wTxn->execute([
            $walletId,
            $walletDeducted,
            'Order #' . $orderId . ' (' . $areaName . ' Tiffin Charge)',
            $newWalletBalance,
        ]);
    }

    // ── 9. Clear cart ────────────────────────────────────────────────────────
    $clearStmt = $pdo->prepare("DELETE FROM cart_items WHERE customer_id = ?");
    $clearStmt->execute([$customerId]);

    // ── 10. Commit ───────────────────────────────────────────────────────────
    $pdo->commit();

    // ── 11. Send real-time notifications (outside transaction) ───────────────
    try {
        // Fetch hotel vendor_id, hotel_name, and coordinates
        $hotelQuery = $pdo->prepare("SELECT vendor_id, hotel_name, COALESCE(latitude, 0.0) AS latitude, COALESCE(longitude, 0.0) AS longitude FROM hotels WHERE id = ?");
        $hotelQuery->execute([$hotelId]);
        $hotelRow = $hotelQuery->fetch(PDO::FETCH_ASSOC);
        $vendorId = (int)($hotelRow['vendor_id'] ?? 0);
        $hotelName = $hotelRow['hotel_name'] ?? 'Hotel';
        $hotelLat = (float)($hotelRow['latitude'] ?? 0.0);
        $hotelLng = (float)($hotelRow['longitude'] ?? 0.0);

        // Fetch customer name & email
        $customerQuery = $pdo->prepare("SELECT full_name, email, COALESCE(latitude, 0.0) AS latitude, COALESCE(longitude, 0.0) AS longitude FROM customers WHERE id = ?");
        $customerQuery->execute([$customerId]);
        $custRow = $customerQuery->fetch(PDO::FETCH_ASSOC);
        $customerName = $custRow['full_name'] ?? 'Customer';
        $customerEmail = $custRow['email'] ?? '';

        // Resolve customer coordinates for actual distance
        $custLat = 0.0;
        $custLng = 0.0;
        if (!empty($deliveryAddress)) {
            $addrCoordStmt = $pdo->prepare("
                SELECT latitude, longitude 
                FROM customer_addresses 
                WHERE customer_id = ? 
                  AND (TRIM(full_address) = ? OR ? LIKE CONCAT('%', full_address, '%') OR full_address LIKE CONCAT('%', ?, '%'))
                  AND latitude != 0.0 AND longitude != 0.0
                ORDER BY (TRIM(full_address) = ?) DESC, is_default DESC, id DESC 
                LIMIT 1
            ");
            $addrCoordStmt->execute([$customerId, $deliveryAddress, $deliveryAddress, $deliveryAddress, $deliveryAddress]);
            $addrCoord = $addrCoordStmt->fetch(PDO::FETCH_ASSOC);
            if ($addrCoord) {
                $custLat = (float)$addrCoord['latitude'];
                $custLng = (float)$addrCoord['longitude'];
            }
        }
        if ($custLat == 0.0 || $custLng == 0.0) {
            $defAddrStmt = $pdo->prepare("SELECT latitude, longitude FROM customer_addresses WHERE customer_id = ? AND latitude != 0.0 ORDER BY is_default DESC, id DESC LIMIT 1");
            $defAddrStmt->execute([$customerId]);
            $defAddr = $defAddrStmt->fetch(PDO::FETCH_ASSOC);
            if ($defAddr) {
                $custLat = (float)$defAddr['latitude'];
                $custLng = (float)$defAddr['longitude'];
            }
        }
        if ($custLat == 0.0 || $custLng == 0.0) {
            $custLat = (float)($custRow['latitude'] ?? 0.0);
            $custLng = (float)($custRow['longitude'] ?? 0.0);
        }

        // Calculate actual customer distance from hotel (drop distance in km)
        $dropDistanceKm = 0.0;
        if ($hotelLat != 0.0 && $hotelLng != 0.0 && $custLat != 0.0 && $custLng != 0.0) {
            $earthRadius = 6371; // km
            $dLat = deg2rad($custLat - $hotelLat);
            $dLon = deg2rad($custLng - $hotelLng);
            $a = sin($dLat / 2) * sin($dLat / 2) +
                 cos(deg2rad($hotelLat)) * cos(deg2rad($custLat)) *
                 sin($dLon / 2) * sin($dLon / 2);
            $c = 2 * atan2(sqrt($a), sqrt(1 - $a));
            $dropDistanceKm = round($earthRadius * $c, 2);
        }

        // Fetch items list
        $itemsQuery = $pdo->prepare("
            SELECT oi.order_item_id, oi.menu_item_id, oi.quantity, oi.price, m.food_name 
            FROM order_items oi
            JOIN menus m ON oi.menu_item_id = m.id
            WHERE oi.order_id = ?
        ");
        $itemsQuery->execute([$orderId]);
        $itemsList = $itemsQuery->fetchAll(PDO::FETCH_ASSOC);

        $eventData = [
            'order_id'           => $orderId,
            'customer_id'        => $customerId,
            'customer_name'      => $customerName,
            'customer_email'     => $customerEmail,
            'hotel_id'           => $hotelId,
            'vendor_id'          => $vendorId,
            'hotel_name'         => $hotelName,
            'hotel_latitude'     => $hotelLat,
            'hotel_longitude'    => $hotelLng,
            'customer_latitude'  => $custLat,
            'customer_longitude' => $custLng,
            'distance_km'        => $dropDistanceKm,
            'drop_distance_km'   => $dropDistanceKm,
            'subtotal'           => (float)$subtotal,
            'delivery_fee'       => (float)$deliveryFee,
            'tax_amount'         => (float)$taxAmount,
            'grand_total'        => (float)$grandTotal,
            'wallet_deducted'    => (float)$walletDeducted,
            'tiffin_charge'      => (float)$areaTiffinCharge,
            'area_name'          => $areaName,
            'payment_method'     => $paymentMethod,
            'delivery_address'   => $deliveryAddress,
            'status'             => 'created_order',
            'items'              => $itemsList,
            'created_at'         => date('Y-m-d H:i:s')
        ];

        // Send real-time notification via Ably to vendor channel (vendor_{vendorId}) and order tracking channel (order_{orderId})
        AblyHelper::publishVendorNewOrder($vendorId, $eventData);
        AblyHelper::publishOrderUpdate($orderId, $eventData);

        // Send FCM notification to Vendor (asynchronous background process)
        require_once __DIR__ . '/../../helpers/fcm.php';
        FcmHelper::sendToVendor($vendorId, "🆕 New Order Received!", "Order #$orderId has been placed at $hotelName. Tap to accept.", [
            'order_id'  => (string)$orderId,
            'hotel_id'  => (string)$hotelId,
            'vendor_id' => (string)$vendorId,
            'event'     => 'NEW_ORDER',
            'status'    => 'created_order'
        ]);

        // Also send FCM confirmation to Customer (order placed successfully)
        FcmHelper::sendToCustomer($customerId, "🎉 Order Placed!", "Your order #$orderId from $hotelName has been received. Waiting for acceptance.", [
            'order_id' => (string)$orderId,
            'event'    => 'ORDER_PLACED',
            'status'   => 'created_order'
        ]);
    } catch (Throwable $e) {
        error_log("Notification error in place.php: " . $e->getMessage());
    }

    sendSuccess('Order placed successfully.', [
        'order_id'           => $orderId,
        'meal_type'          => $mealType,
        'grand_total'        => number_format($grandTotal,        2, '.', ''),
        'wallet_deducted'    => number_format($walletDeducted,    2, '.', ''),
        'remaining_payable'  => number_format($remainingPayable,  2, '.', ''),
        'new_wallet_balance' => number_format($newWalletBalance,  2, '.', ''),
        'status'             => 'created_order',
        'delivery_otp'       => $deliveryOtp,
        'tiffin_charge'      => number_format($areaTiffinCharge,  2, '.', ''),
        'area_name'          => $areaName,
    ]);

} catch (Exception $e) {
    if (isset($pdo) && $pdo->inTransaction()) { $pdo->rollBack(); }
    $code = $e->getCode();
    $status = ($code >= 400 && $code <= 500) ? $code : 500;
    sendError($e->getMessage(), $status);
} finally {
    if (!empty($orderLockKey) && !empty($orderLockToken)) {
        RedisHelper::unlock($orderLockKey, $orderLockToken);
    }
}
