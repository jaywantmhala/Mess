<?php
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/jwt.php';

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
$deliveryAddress = trim((string) $body['delivery_address']);

if ($paymentMethod   === '') { sendError('payment_method cannot be empty.', 422); }
if ($deliveryAddress === '') { sendError('delivery_address cannot be empty.', 422); }

try {
    $pdo = getDBConnection();
    $pdo->beginTransaction();

    // ── 1. Fetch all cart items ──────────────────────────────────────────────
    $cartStmt = $pdo->prepare(
        "SELECT ci.cart_item_id, ci.menu_item_id, ci.hotel_id, ci.quantity,
                m.price, m.food_name AS item_name
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

    // ── 2. Calculate totals ──────────────────────────────────────────────────
    $hotelId     = (int) $cartItems[0]['hotel_id'];
    $subtotal    = 0.0;
    foreach ($cartItems as $item) {
        $subtotal += (float) $item['price'] * (int) $item['quantity'];
    }
    $deliveryFee = 40.00;
    $taxAmount   = round($subtotal * 0.05, 2);
    $grandTotal  = round($subtotal + $deliveryFee + $taxAmount, 2);

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

    // ── 4 & 5. Wallet deduction logic ───────────────────────────────────────
    $walletDeducted  = min($walletBalance, $grandTotal);
    $remainingPayable = round($grandTotal - $walletDeducted, 2);

    // ── 6. Insert order ──────────────────────────────────────────────────────
    $orderStmt = $pdo->prepare(
        "INSERT INTO orders
            (customer_id, hotel_id, subtotal, delivery_fee, tax_amount,
             grand_total, wallet_deducted, payment_method, delivery_address, status)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'created_order')"
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
    ]);
    $orderId = (int) $pdo->lastInsertId();

    // ── 7. Insert order items ────────────────────────────────────────────────
    $itemStmt = $pdo->prepare(
        "INSERT INTO order_items (order_id, menu_item_id, quantity, price)
         VALUES (?, ?, ?, ?)"
    );
    foreach ($cartItems as $item) {
        $itemStmt->execute([
            $orderId,
            (int)   $item['menu_item_id'],
            (int)   $item['quantity'],
            (float) $item['price'],
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
            'Order #' . $orderId . ' Payment',
            $newWalletBalance,
        ]);
    }

    // ── 9. Clear cart ────────────────────────────────────────────────────────
    $clearStmt = $pdo->prepare("DELETE FROM cart_items WHERE customer_id = ?");
    $clearStmt->execute([$customerId]);

    // ── 9.5. Send real-time notification to WebSocket server ───────────────
    try {
        // Fetch hotel vendor_id and hotel_name
        $hotelQuery = $pdo->prepare("SELECT vendor_id, hotel_name FROM hotels WHERE id = ?");
        $hotelQuery->execute([$hotelId]);
        $hotelRow = $hotelQuery->fetch(PDO::FETCH_ASSOC);
        $vendorId = (int)($hotelRow['vendor_id'] ?? 0);
        $hotelName = $hotelRow['hotel_name'] ?? 'Hotel';

        // Fetch customer name
        $customerQuery = $pdo->prepare("SELECT full_name FROM customers WHERE id = ?");
        $customerQuery->execute([$customerId]);
        $customerName = $customerQuery->fetchColumn() ?: 'Customer';

        // Fetch items list
        $itemsQuery = $pdo->prepare("
            SELECT oi.quantity, oi.price, m.food_name 
            FROM order_items oi
            JOIN menus m ON oi.menu_item_id = m.id
            WHERE oi.order_id = ?
        ");
        $itemsQuery->execute([$orderId]);
        $itemsList = $itemsQuery->fetchAll(PDO::FETCH_ASSOC);

        $eventData = [
            'order_id' => $orderId,
            'customer_id' => $customerId,
            'customer_name' => $customerName,
            'hotel_id' => $hotelId,
            'hotel_name' => $hotelName,
            'grand_total' => (float)$grandTotal,
            'status' => 'created_order',
            'items' => $itemsList,
            'created_at' => date('Y-m-d H:i:s')
        ];

        // Send local notification to TCP socket running PHP WebSocket server on port 8081
        $fp = @fsockopen("127.0.0.1", 8081, $errno, $errstr, 1);
        if ($fp) {
            $notification = [
                'system_event' => true,
                'secret' => 'first_demo_system_websocket_secret_key_2026',
                'event' => 'NEW_ORDER',
                'data' => $eventData
            ];
            @fwrite($fp, json_encode($notification));
            @fclose($fp);
        }
    } catch (Exception $e) {
        // Suppress notification errors so order placement isn't blocked if WS server is down
    }

    // ── 10. Commit ───────────────────────────────────────────────────────────
    $pdo->commit();

    sendSuccess('Order placed successfully.', [
        'order_id'           => $orderId,
        'grand_total'        => number_format($grandTotal,        2, '.', ''),
        'wallet_deducted'    => number_format($walletDeducted,    2, '.', ''),
        'remaining_payable'  => number_format($remainingPayable,  2, '.', ''),
        'new_wallet_balance' => number_format($newWalletBalance,  2, '.', ''),
        'status'             => 'created_order',
    ]);

} catch (PDOException $e) {
    if (isset($pdo) && $pdo->inTransaction()) { $pdo->rollBack(); }
    sendError('Database error: ' . $e->getMessage(), 500);
}
