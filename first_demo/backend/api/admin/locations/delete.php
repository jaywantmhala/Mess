<?php
/**
 * POST /api/admin/locations/delete
 *
 * Delete a location component (city, pincode, area, sub_area, plan).
 * Requires: Authorization: Bearer <JWT>
 */

require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../helpers/response.php';
require_once __DIR__ . '/../../../helpers/validation.php';
require_once __DIR__ . '/../../../helpers/jwt.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'POST')    { sendError('Method not allowed. Use POST.', 405); }

$token   = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;

if (!$payload || !isset($payload['sub']) || ($payload['role'] ?? '') !== 'admin') {
    sendError('Unauthorized. Admin access required.', 401);
}

$body = requireJsonBody(['type', 'id']);
$type = trim($body['type']);
$id   = (int)$body['id'];

if ($id <= 0) { sendError('Invalid ID.', 422); }

$allowedTypes = ['city', 'pincode', 'area', 'sub_area', 'plan'];
if (!in_array($type, $allowedTypes)) {
    sendError('Invalid type. Must be city, pincode, area, sub_area, or plan.', 422);
}

// Map types to tables
$tables = [
    'city'     => 'cities',
    'pincode'  => 'pincodes',
    'area'     => 'areas',
    'sub_area' => 'sub_areas',
    'plan'     => 'subscription_plans'
];
$table = $tables[$type];

$pdo = getDBConnection();

try {
    if ($type === 'plan') {
        $del1 = $pdo->prepare("DELETE FROM subscription_plans WHERE id = :id");
        $del1->execute([':id' => $id]);

        $del2 = $pdo->prepare("DELETE FROM plans WHERE id = :id OR legacy_plan_id = :id");
        $del2->execute([':id' => $id]);

        sendSuccess("Successfully deleted the specified plan.", ['id' => $id, 'type' => 'plan']);
        exit;
    }

    if ($type === 'sub_area') {
        $del1 = $pdo->prepare("DELETE FROM subscription_plans WHERE sub_area_id = :id");
        $del1->execute([':id' => $id]);
        $del2 = $pdo->prepare("DELETE FROM sub_areas WHERE id = :id");
        $del2->execute([':id' => $id]);

        $del3 = $pdo->prepare("DELETE FROM plans WHERE service_location_id = :id");
        $del3->execute([':id' => $id]);
        $del4 = $pdo->prepare("DELETE FROM service_locations WHERE id = :id");
        $del4->execute([':id' => $id]);

        sendSuccess("Successfully deleted the specified sub area.", ['id' => $id, 'type' => 'sub_area']);
        exit;
    }

    // Check if record exists
    $stmt = $pdo->prepare("SELECT id FROM `{$table}` WHERE id = :id LIMIT 1");
    $stmt->execute([':id' => $id]);
    if (!$stmt->fetch()) {
        sendError(ucfirst($type) . ' not found.', 404);
    }
    
    // Delete record (CASCADE deletes children automatically)
    $stmt = $pdo->prepare("DELETE FROM `{$table}` WHERE id = :id");
    $stmt->execute([':id' => $id]);
    
    sendSuccess("Successfully deleted the specified " . str_replace('_', ' ', $type) . ".", [
        'id'   => $id,
        'type' => $type
    ]);
} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
