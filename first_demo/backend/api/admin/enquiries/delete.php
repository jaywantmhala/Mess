<?php
/**
 * POST /api/admin/enquiries/delete
 *
 * Delete an enquiry record.
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

$id = isset($input['id']) ? (int)$input['id'] : 0;

if ($id <= 0) {
    sendError('Invalid or missing enquiry ID.', 422);
}

try {
    $pdo = getDBConnection();
    ensureEnquiriesTable($pdo);

    $stmt = $pdo->prepare("DELETE FROM `enquiries` WHERE `id` = :id");
    $stmt->execute([':id' => $id]);

    if ($stmt->rowCount() === 0) {
        sendError('Enquiry record not found or already deleted.', 404);
    }

    sendSuccess("Enquiry #{$id} deleted successfully.", [
        'id' => $id,
    ]);

} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
} catch (Exception $e) {
    sendError('Server error: ' . $e->getMessage(), 500);
}
