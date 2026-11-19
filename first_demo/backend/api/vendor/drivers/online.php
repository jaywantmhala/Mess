<?php
/**
 * GET /api/vendor/drivers/online
 * Returns list of drivers available for assignment to the authenticated vendor.
 * Includes drivers registered under this vendor as well as independent drivers.
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

    // Fetch drivers associated with this vendor
    $sql = "
        SELECT d.id, d.full_name, d.vehicle_number, d.phone_number, d.max_capacity, d.is_online,
               COUNT(o.order_id) as active_order_count
        FROM drivers d
        LEFT JOIN orders o ON o.driver_id = d.id AND o.status IN ('assigned', 'accepted_by_driver', 'picked_up')
        WHERE d.vendor_id = ?
        GROUP BY d.id
        ORDER BY d.is_online DESC, active_order_count ASC, d.id DESC
    ";
    $stmt = $pdo->prepare($sql);
    $stmt->execute([$vendorId]);

    $drivers = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Map output types
    foreach ($drivers as &$driver) {
        $driver['id'] = (int)$driver['id'];
        $driver['max_capacity'] = (int)$driver['max_capacity'];
        $driver['active_order_count'] = (int)$driver['active_order_count'];
        $driver['is_online'] = (int)($driver['is_online'] ?? 0);
    }

    sendSuccess('Online drivers retrieved.', ['drivers' => $drivers]);

} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}

