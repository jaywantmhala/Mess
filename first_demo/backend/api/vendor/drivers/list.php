<?php
/**
 * GET /api/vendor/drivers/list
 * Returns list of all drivers associated with the authenticated vendor.
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

$vendorId = (int)$payload['sub'];

try {
    $pdo = getDBConnection();
    
    $stmt = $pdo->prepare("
        SELECT d.id, d.full_name, d.email, d.phone_number, d.vehicle_number, 
               d.is_online, d.max_capacity, d.created_at,
               COUNT(o.order_id) as active_order_count
        FROM drivers d
        LEFT JOIN orders o ON o.driver_id = d.id AND o.status IN ('assigned', 'accepted_by_driver', 'picked_up')
        WHERE d.vendor_id = ?
        GROUP BY d.id
        ORDER BY d.id DESC
    ");
    $stmt->execute([$vendorId]);
    $drivers = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Map output types
    foreach ($drivers as &$driver) {
        $driver['id'] = (int)$driver['id'];
        $driver['is_online'] = (bool)$driver['is_online'];
        $driver['max_capacity'] = (int)$driver['max_capacity'];
        $driver['active_order_count'] = (int)$driver['active_order_count'];
    }

    sendSuccess('Vendor drivers retrieved.', ['drivers' => $drivers]);

} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
