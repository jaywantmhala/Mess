<?php
/**
 * POST /api/auth/forgot-password/check-email
 * Verifies if customer email exists in the database.
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/validation.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'POST')    { sendError('Method not allowed. Use POST.', 405); }

$rawBody = file_get_contents('php://input');
$body = json_decode($rawBody, true) ?? [];

$email = strtolower(trim(sanitize($body['email'] ?? '')));

if (empty($email) || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    sendError('Email is not valid', 422);
}

try {
    $pdo = getDBConnection();
    $stmt = $pdo->prepare("SELECT id, full_name FROM customers WHERE LOWER(email) = LOWER(:email) AND is_active = 1 LIMIT 1");
    $stmt->execute([':email' => $email]);
    $user = $stmt->fetch();

    if ($user) {
        sendSuccess('Email is valid.', ['exists' => true]);
    } else {
        sendError('Email is not valid', 404, ['exists' => false]);
    }
} catch (Exception $e) {
    sendError('Server error: ' . $e->getMessage(), 500);
}
