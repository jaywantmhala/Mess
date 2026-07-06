<?php
/**
 * GET /api/vendor/drivers/online
 * Returns list of online and available drivers with active order counts.
 * Requires: Authorization: Bearer <JWT> (Vendor role required)
 */

header('Content-Type: application/json; charset=utf-8');

require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../helpers/jwt.php';
require_once __DIR__ . '/../../../helpers/response.php';

// ── JWT Authentication ────────────────────────────────────────────────────────
$token   = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;

if (!$payload || ($payload['role'] ?? '') !== 'vendor') {
    sendError('Unauthorized access. Vendor token required.', 401);
}

try {
    $pdo = getDBConnection();
    
    // Select online drivers whose current active orders are below their max capacity
    $stmt = $pdo->prepare("
        SELECT d.id, d.full_name, d.vehicle_number, d.phone_number, d.max_capacity,
               COUNT(o.order_id) as active_order_count
        FROM drivers d
        LEFT JOIN orders o ON o.driver_id = d.id AND o.status IN ('assigned', 'accepted_by_driver', 'picked_up')
        WHERE d.is_online = 1
        GROUP BY d.id
        HAVING active_order_count < d.max_capacity
    ");
    $stmt->execute();
    $drivers = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Map output types
    foreach ($drivers as &$driver) {
        $driver['id'] = (int)$driver['id'];
        $driver['max_capacity'] = (int)$driver['max_capacity'];
        $driver['active_order_count'] = (int)$driver['active_order_count'];
    }

    sendSuccess('Online drivers retrieved.', ['drivers' => $drivers]);

} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
