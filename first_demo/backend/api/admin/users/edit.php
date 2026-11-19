<?php
/**
 * POST /api/admin/users/edit
 *
 * Edit a customer account's full details:
 * - full_name, email, phone_number, password (optional)
 * - is_active (status)
 * - location: country, state, district, taluka
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

$rawBody = file_get_contents('php://input');
$body = json_decode($rawBody, true) ?? [];

$userId   = (int)($body['id'] ?? 0);
$fullName = sanitize($body['full_name'] ?? '');
$email    = strtolower(trim($body['email'] ?? ''));
$phone    = sanitize($body['phone_number'] ?? ($body['phone'] ?? ''));
$password = isset($body['password']) ? trim($body['password']) : '';

$country  = sanitize($body['country'] ?? 'India');
$state    = sanitize($body['state'] ?? '');
$district = sanitize($body['district'] ?? '');
$taluka   = sanitize($body['taluka'] ?? '');

$isActive = isset($body['is_active']) ? (int)(bool)$body['is_active'] : 1;
$status   = $isActive ? 'active' : 'inactive';

if ($userId <= 0) { sendError('Invalid user ID.', 422); }
if (strlen($fullName) < 2) { sendError('Full name must be at least 2 characters long.', 422); }
if (!isValidEmail($email)) { sendError('Please enter a valid email address.', 422); }

$pdo = getDBConnection();

// Check if customer exists
$stmt = $pdo->prepare("SELECT id FROM customers WHERE id = :id LIMIT 1");
$stmt->execute([':id' => $userId]);
if (!$stmt->fetch()) { sendError('Customer not found.', 404); }

// Check if email is already taken by another customer
$stmt = $pdo->prepare("SELECT id FROM customers WHERE email = :email AND id != :id LIMIT 1");
$stmt->execute([':email' => $email, ':id' => $userId]);
if ($stmt->fetch()) { sendError('This email is already in use by another customer.', 409); }

try {
    $fields = [
        'full_name = :full_name',
        'email = :email',
        'phone_number = :phone_number',
        'phone = :phone',
        'country = :country',
        'state = :state',
        'district = :district',
        'taluka = :taluka',
        'is_active = :is_active',
        'status = :status',
        'updated_at = NOW()'
    ];

    $params = [
        ':full_name'    => $fullName,
        ':email'        => $email,
        ':phone_number' => $phone,
        ':phone'        => $phone,
        ':country'      => $country,
        ':state'        => $state,
        ':district'     => $district,
        ':taluka'       => $taluka,
        ':is_active'    => $isActive,
        ':status'       => $status,
        ':id'           => $userId,
    ];

    if (!empty($password)) {
        $fields[] = 'password = :password';
        $params[':password'] = password_hash($password, PASSWORD_BCRYPT, ['cost' => 12]);
    }

    $sql = "UPDATE customers SET " . implode(', ', $fields) . " WHERE id = :id";
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    
    sendSuccess('Customer details updated successfully.', [
        'user' => [
            'id'           => $userId,
            'full_name'    => $fullName,
            'email'        => $email,
            'phone_number' => $phone,
            'country'      => $country,
            'state'        => $state,
            'district'     => $district,
            'taluka'       => $taluka,
            'is_active'    => (bool)$isActive,
            'status'       => $status
        ]
    ]);
} catch (PDOException $e) {
    sendError('Failed to update customer: ' . $e->getMessage(), 500);
}
