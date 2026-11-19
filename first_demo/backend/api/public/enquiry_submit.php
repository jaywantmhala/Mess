<?php
/**
 * POST /api/enquiries/submit
 *
 * Public endpoint to submit customer website inquiries.
 * Saves visitor contact info and location hierarchy (State, District, Taluka, Area).
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept, Origin');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendError('Method not allowed. Use POST.', 405);
}

// Read and decode JSON request payload or fallback to $_POST
$rawInput = file_get_contents('php://input');
$input = !empty($rawInput) ? json_decode($rawInput, true) : null;
if (!is_array($input)) {
    $input = $_POST;
}

$name     = isset($input['name'])     ? trim(strip_tags((string)$input['name']))     : '';
$phone    = isset($input['phone'])    ? trim(strip_tags((string)$input['phone']))    : '';
$state    = isset($input['state'])    ? trim(strip_tags((string)$input['state']))    : '';
$district = isset($input['district']) ? trim(strip_tags((string)$input['district'])) : '';
$taluka   = isset($input['taluka'])   ? trim(strip_tags((string)$input['taluka']))   : '';
$area     = isset($input['area'])     ? trim(strip_tags((string)$input['area']))     : '';
$notes    = isset($input['notes'])    ? trim(strip_tags((string)$input['notes']))    : null;

// Validation
if ($name === '') {
    sendError('Please enter your full name.', 422);
}

if ($phone === '') {
    sendError('Please enter your phone number.', 422);
}

// Clean phone and check basic length
$phoneDigits = preg_replace('/[^\d]/', '', $phone);
if (strlen($phoneDigits) < 7 || strlen($phoneDigits) > 15) {
    sendError('Please enter a valid phone number (at least 10 digits).', 422);
}

if ($state === '') {
    sendError('Please select or specify your state.', 422);
}

if ($district === '') {
    sendError('Please select or specify your district.', 422);
}

if ($taluka === '') {
    sendError('Please select or specify your taluka.', 422);
}

if ($area === '') {
    sendError('Please enter your area or locality.', 422);
}

try {
    $pdo = getDBConnection();
    ensureEnquiriesTable($pdo);

    $stmt = $pdo->prepare("
        INSERT INTO `enquiries` (`name`, `phone`, `state`, `district`, `taluka`, `area`, `notes`, `status`, `created_at`)
        VALUES (:name, :phone, :state, :district, :taluka, :area, :notes, 'New', NOW())
    ");

    $stmt->execute([
        ':name'     => $name,
        ':phone'    => $phone,
        ':state'    => $state,
        ':district' => $district,
        ':taluka'   => $taluka,
        ':area'     => $area,
        ':notes'    => $notes !== '' ? $notes : null,
    ]);

    $insertedId = (int)$pdo->lastInsertId();

    sendSuccess('Thank you! Your enquiry has been received successfully. Our team will contact you shortly.', [
        'id'         => $insertedId,
        'name'       => $name,
        'phone'      => $phone,
        'state'      => $state,
        'district'   => $district,
        'taluka'     => $taluka,
        'area'       => $area,
        'status'     => 'New',
        'created_at' => date('Y-m-d H:i:s'),
    ], 201);

} catch (PDOException $e) {
    sendError('Database error while saving enquiry: ' . $e->getMessage(), 500);
} catch (Exception $e) {
    sendError('Failed to process enquiry: ' . $e->getMessage(), 500);
}
