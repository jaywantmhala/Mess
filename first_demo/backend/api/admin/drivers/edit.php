<?php
/**
 * POST /api/admin/drivers/edit
 *
 * Edit a delivery driver's full details:
 * - full_name, email, phone_number, vehicle_number
 * - password (optional)
 * - is_online, status, max_capacity
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

$driverId      = (int)($body['id'] ?? 0);
$fullName      = sanitize($body['full_name'] ?? '');
$email         = strtolower(trim($body['email'] ?? ''));
$phoneNumber   = sanitize($body['phone_number'] ?? ($body['phone'] ?? ''));
$vehicleNumber = strtoupper(trim(sanitize($body['vehicle_number'] ?? '')));
$password      = isset($body['password']) ? trim($body['password']) : '';

$country       = sanitize($body['country'] ?? 'India');
$state         = sanitize($body['state'] ?? '');
$district      = sanitize($body['district'] ?? '');
$taluka        = sanitize($body['taluka'] ?? '');

$isOnline      = isset($body['is_online']) ? (int)(bool)$body['is_online'] : 0;
$status        = isset($body['status']) && in_array(strtolower($body['status']), ['active', 'inactive']) ? strtolower($body['status']) : 'active';
$maxCapacity   = isset($body['max_capacity']) ? max(1, min(20, (int)$body['max_capacity'])) : 3;

if ($driverId <= 0) { sendError('Invalid driver ID.', 422); }
if (strlen($fullName) < 2) { sendError('Full name must be at least 2 characters long.', 422); }
if (!isValidEmail($email)) { sendError('Please enter a valid email address.', 422); }
if (empty($vehicleNumber)) { sendError('Vehicle number is required.', 422); }

$pdo = getDBConnection();

// Check if driver exists
$stmt = $pdo->prepare("SELECT id FROM drivers WHERE id = :id LIMIT 1");
$stmt->execute([':id' => $driverId]);
if (!$stmt->fetch()) { sendError('Driver not found.', 404); }

// Check if email is already taken by another driver
$stmt = $pdo->prepare("SELECT id FROM drivers WHERE email = :email AND id != :id LIMIT 1");
$stmt->execute([':email' => $email, ':id' => $driverId]);
if ($stmt->fetch()) { sendError('This email is already in use by another driver.', 409); }

try {
    $fields = [
        'full_name = :full_name',
        'email = :email',
        'phone_number = :phone_number',
        'vehicle_number = :vehicle_number',
        'is_online = :is_online',
        'status = :status',
        'max_capacity = :max_capacity',
        'country = :country',
        'state = :state',
        'district = :district',
        'taluka = :taluka',
        'updated_at = NOW()'
    ];

    $params = [
        ':full_name'      => $fullName,
        ':email'          => $email,
        ':phone_number'   => $phoneNumber,
        ':vehicle_number' => $vehicleNumber,
        ':is_online'      => $isOnline,
        ':status'         => $status,
        ':max_capacity'   => $maxCapacity,
        ':country'        => $country,
        ':state'          => $state,
        ':district'       => $district,
        ':taluka'         => $taluka,
        ':id'             => $driverId,
    ];

    if (!empty($password)) {
        $fields[] = 'password = :password';
        $params[':password'] = password_hash($password, PASSWORD_BCRYPT, ['cost' => 12]);
    }

    $sql = "UPDATE drivers SET " . implode(', ', $fields) . " WHERE id = :id";
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);

    sendSuccess('Driver details updated successfully.', [
        'driver' => [
            'id'             => $driverId,
            'full_name'      => $fullName,
            'email'          => $email,
            'phone_number'   => $phoneNumber,
            'vehicle_number' => $vehicleNumber,
            'is_online'      => (bool)$isOnline,
            'status'         => $status,
            'max_capacity'   => $maxCapacity,
            'country'        => $country,
            'state'          => $state,
            'district'       => $district,
            'taluka'         => $taluka
        ]
    ]);
} catch (PDOException $e) {
    sendError('Failed to update driver: ' . $e->getMessage(), 500);
}
