<?php
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/jwt.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'GET') { sendError('Method not allowed.', 405); }

$token = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;
if (!$payload || !isset($payload['sub'])) { sendError('Unauthorized.', 401); }
$customerId = (int) $payload['sub'];

$page  = max(1, (int) ($_GET['page']  ?? 1));
$limit = max(1, min(50, (int) ($_GET['limit'] ?? 10)));
$offset = ($page - 1) * $limit;

try {
    $pdo = getDBConnection();

    // Count total orders for this customer
    $countStmt = $pdo->prepare(
        "SELECT COUNT(*) FROM orders WHERE customer_id = ?"
    );
    $countStmt->execute([$customerId]);
    $total = (int) $countStmt->fetchColumn();

    // Fetch paginated orders with hotel name and item count
    $stmt = $pdo->prepare(
        "SELECT
            o.order_id,
            h.hotel_name  AS hotel_name,
            o.status,
            o.grand_total,
            o.wallet_deducted,
            o.created_at,
            COUNT(oi.order_item_id) AS item_count
         FROM orders o
         JOIN hotels      h  ON h.id  = o.hotel_id
         LEFT JOIN order_items oi ON oi.order_id = o.order_id
         WHERE o.customer_id = ?
         GROUP BY
            o.order_id, h.hotel_name, o.status,
            o.grand_total, o.wallet_deducted, o.created_at
         ORDER BY o.created_at DESC
         LIMIT ? OFFSET ?"
    );
    $stmt->execute([$customerId, $limit, $offset]);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $orders = array_map(function ($row) {
        return [
            'order_id'        => (int)    $row['order_id'],
            'hotel_name'      =>          $row['hotel_name'],
            'status'          =>          $row['status'],
            'grand_total'     => number_format((float) $row['grand_total'],     2, '.', ''),
            'wallet_deducted' => number_format((float) $row['wallet_deducted'], 2, '.', ''),
            'item_count'      => (int)    $row['item_count'],
            'created_at'      =>          $row['created_at'],
        ];
    }, $rows);

    sendSuccess('Order history fetched successfully.', [
        'orders' => $orders,
        'page'   => $page,
        'limit'  => $limit,
        'total'  => $total,
    ]);

} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
