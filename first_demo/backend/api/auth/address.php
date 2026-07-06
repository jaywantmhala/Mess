<?php
/**
 * GET  /api/auth/address  — fetch saved address for the authenticated customer
 * POST /api/auth/address  — upsert (save/update) address for the authenticated customer
 *
 * Body (POST): {
 *   full_address, latitude, longitude,
 *   area?, city?, state?, country?, pincode?, landmark?, place_id?
 * }
 * Header: Authorization: Bearer <token>
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/jwt.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }

// ── Auth ──────────────────────────────────────────────────────────────────────
$token = JWT::getBearerToken();
if (!$token) {
    sendError('Authorization token is required.', 401);
}
$payload = JWT::verify($token);
if (!$payload || !isset($payload['sub'])) {
    sendError('Invalid or expired token.', 401);
}
$customerId = (int) $payload['sub'];

$pdo = getDBConnection();

// ── Ensure table exists ───────────────────────────────────────────────────────
$pdo->exec("
    CREATE TABLE IF NOT EXISTS customer_addresses (
        id           INT AUTO_INCREMENT PRIMARY KEY,
        customer_id  INT NOT NULL,
        full_address TEXT NOT NULL,
        area         VARCHAR(255) DEFAULT '',
        city         VARCHAR(255) DEFAULT '',
        state        VARCHAR(255) DEFAULT '',
        country      VARCHAR(255) DEFAULT '',
        pincode      VARCHAR(20)  DEFAULT '',
        landmark     VARCHAR(255) DEFAULT '',
        place_id     VARCHAR(255) DEFAULT '',
        latitude     DECIMAL(10,7) DEFAULT 0,
        longitude    DECIMAL(10,7) DEFAULT 0,
        created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        UNIQUE KEY uq_customer (customer_id)
    )
");

// ── GET — return saved address ────────────────────────────────────────────────
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $stmt = $pdo->prepare("SELECT * FROM customer_addresses WHERE customer_id = :cid LIMIT 1");
    $stmt->execute([':cid' => $customerId]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$row) {
        sendSuccess('No address saved.', ['address' => null]);
    }

    sendSuccess('Address fetched.', ['address' => $row]);
}

// ── POST — upsert address ─────────────────────────────────────────────────────
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $raw  = file_get_contents('php://input');
    $body = json_decode($raw, true);

    if (!$body || empty($body['full_address'])) {
        sendError('full_address is required.', 422);
    }

    $fullAddress = trim($body['full_address']);
    $latitude    = isset($body['latitude'])  ? (float) $body['latitude']  : 0.0;
    $longitude   = isset($body['longitude']) ? (float) $body['longitude'] : 0.0;
    $area        = isset($body['area'])      ? trim($body['area'])        : '';
    $city        = isset($body['city'])      ? trim($body['city'])        : '';
    $state       = isset($body['state'])     ? trim($body['state'])       : '';
    $country     = isset($body['country'])   ? trim($body['country'])     : '';
    $pincode     = isset($body['pincode'])   ? trim($body['pincode'])     : '';
    $landmark    = isset($body['landmark'])  ? trim($body['landmark'])    : '';
    $placeId     = isset($body['place_id'])  ? trim($body['place_id'])    : '';

    // UPSERT using INSERT ... ON DUPLICATE KEY UPDATE
    $stmt = $pdo->prepare("
        INSERT INTO customer_addresses
            (customer_id, full_address, area, city, state, country, pincode, landmark, place_id, latitude, longitude, created_at, updated_at)
        VALUES
            (:cid, :full_address, :area, :city, :state, :country, :pincode, :landmark, :place_id, :lat, :lng, NOW(), NOW())
        ON DUPLICATE KEY UPDATE
            full_address = VALUES(full_address),
            area         = VALUES(area),
            city         = VALUES(city),
            state        = VALUES(state),
            country      = VALUES(country),
            pincode      = VALUES(pincode),
            landmark     = VALUES(landmark),
            place_id     = VALUES(place_id),
            latitude     = VALUES(latitude),
            longitude    = VALUES(longitude),
            updated_at   = NOW()
    ");

    $stmt->execute([
        ':cid'          => $customerId,
        ':full_address' => $fullAddress,
        ':area'         => $area,
        ':city'         => $city,
        ':state'        => $state,
        ':country'      => $country,
        ':pincode'      => $pincode,
        ':landmark'     => $landmark,
        ':place_id'     => $placeId,
        ':lat'          => $latitude,
        ':lng'          => $longitude,
    ]);

    // Fetch and return the saved row
    $stmt2 = $pdo->prepare("SELECT * FROM customer_addresses WHERE customer_id = :cid LIMIT 1");
    $stmt2->execute([':cid' => $customerId]);
    $saved = $stmt2->fetch(PDO::FETCH_ASSOC);

    sendSuccess('Address saved successfully.', ['address' => $saved]);
}

sendError('Method not allowed.', 405);
