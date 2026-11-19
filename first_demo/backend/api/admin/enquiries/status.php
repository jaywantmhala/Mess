<?php
/**
 * POST /api/admin/enquiries/status
 *
 * Update enquiry status and optional notes.
 * Headers: Authorization: Bearer <admin_token>
 */

require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../helpers/response.php';
require_once __DIR__ . '/../../../helpers/jwt.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, Accept, Origin');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendError('Method not allowed. Use POST.', 405);
}

$token   = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;

if (!$payload || !isset($payload['sub'])) {
    sendError('Unauthorized. Please log in with admin account.', 401);
}

$rawInput = file_get_contents('php://input');
$input = !empty($rawInput) ? json_decode($rawInput, true) : null;
if (!is_array($input)) {
    $input = $_POST;
}

$id     = isset($input['id'])     ? (int)$input['id'] : 0;
$status = isset($input['status']) ? trim(strip_tags((string)$input['status'])) : '';
$notes  = isset($input['notes'])  ? trim(strip_tags((string)$input['notes']))  : null;

if ($id <= 0) {
    sendError('Invalid or missing enquiry ID.', 422);
}

$allowedStatuses = ['New', 'Contacted', 'In Progress', 'Closed', 'Cancelled'];
if (!in_array($status, $allowedStatuses, true)) {
    sendError('Invalid status. Allowed values: ' . implode(', ', $allowedStatuses), 422);
}

try {
    $pdo = getDBConnection();
    ensureEnquiriesTable($pdo);

    if ($notes !== null) {
        $stmt = $pdo->prepare("UPDATE `enquiries` SET `status` = :status, `notes` = :notes, `updated_at` = NOW() WHERE `id` = :id");
        $stmt->execute([':status' => $status, ':notes' => $notes, ':id' => $id]);
    } else {
        $stmt = $pdo->prepare("UPDATE `enquiries` SET `status` = :status, `updated_at` = NOW() WHERE `id` = :id");
        $stmt->execute([':status' => $status, ':id' => $id]);
    }

    if ($stmt->rowCount() === 0) {
        // Check if enquiry actually exists
        $check = $pdo->prepare("SELECT `id`, `status` FROM `enquiries` WHERE `id` = :id");
        $check->execute([':id' => $id]);
        if (!$check->fetch()) {
            sendError('Enquiry record not found.', 404);
        }
    }

    sendSuccess("Enquiry #{$id} status updated to '{$status}'.", [
        'id'         => $id,
        'status'     => $status,
        'updated_at' => date('Y-m-d H:i:s'),
    ]);

} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
} catch (Exception $e) {
    sendError('Server error: ' . $e->getMessage(), 500);
}
