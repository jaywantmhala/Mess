<?php
/**
 * GET /api/admin/users/addresses?customer_id=X
 *
 * Fetch all saved delivery addresses for a specific customer from customer_addresses table,
 * with fallback to their latest order address if no saved addresses exist.
 * Requires: Authorization: Bearer <JWT> (Admin)
 */

require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../helpers/response.php';
require_once __DIR__ . '/../../../helpers/jwt.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'GET')     { sendError('Method not allowed. Use GET.', 405); }

$token   = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;

if (!$payload || !isset($payload['sub']) || ($payload['role'] ?? '') !== 'admin') {
    sendError('Unauthorized. Admin access required.', 401);
}

$customerId = isset($_GET['customer_id']) ? (int)$_GET['customer_id'] : (isset($_GET['id']) ? (int)$_GET['id'] : 0);
if ($customerId <= 0) {
    sendError('Valid customer_id is required.', 422);
}

$pdo = getDBConnection();

try {
    $addresses = [];

    // 1. Primary: Query customer_addresses table
    try {
        $stmt = $pdo->prepare("
            SELECT id, customer_id, full_address, COALESCE(area, '') AS area, COALESCE(city, '') AS city, 
                   COALESCE(state, '') AS state, COALESCE(country, '') AS country,
                   COALESCE(latitude, 0.0) AS latitude, COALESCE(longitude, 0.0) AS longitude, 
                   COALESCE(pincode, '') AS pincode, COALESCE(is_default, 0) AS is_default, 
                   COALESCE(tag, 'HOME') AS address_type, COALESCE(tag, 'HOME') AS tag
            FROM customer_addresses
            WHERE customer_id = :cid
            ORDER BY is_default DESC, id DESC
        ");
        $stmt->execute([':cid' => $customerId]);
        $addresses = $stmt->fetchAll(PDO::FETCH_ASSOC);
    } catch (PDOException $e) {
        $addresses = [];
    }

    // 2. Fallback: If customer_addresses has no records, check orders table for latest delivery_address
    if (empty($addresses)) {
        try {
            $ordStmt = $pdo->prepare("
                SELECT delivery_address 
                FROM orders 
                WHERE customer_id = :cid AND delivery_address IS NOT NULL AND TRIM(delivery_address) != '' 
                ORDER BY order_id DESC 
                LIMIT 1
            ");
            $ordStmt->execute([':cid' => $customerId]);
            $lastOrderAddr = $ordStmt->fetchColumn();

            if ($lastOrderAddr) {
                // Extract 6-digit pincode if present in string
                $pincode = '';
                if (preg_match('/\b\d{6}\b/', $lastOrderAddr, $pMatch)) {
                    $pincode = $pMatch[0];
                }

                $addresses[] = [
                    'id'           => 0,
                    'customer_id'  => $customerId,
                    'full_address' => trim($lastOrderAddr),
                    'area'         => '',
                    'city'         => '',
                    'state'        => '',
                    'country'      => '',
                    'latitude'     => 0.0,
                    'longitude'    => 0.0,
                    'pincode'      => $pincode,
                    'is_default'   => 1,
                    'address_type' => 'Last Order Address',
                    'tag'          => 'LAST ORDER'
                ];
            }
        } catch (PDOException $e) {}
    }

    // 3. Fallback: If still empty, check customers table for profile location / coords
    if (empty($addresses)) {
        try {
            $cStmt = $pdo->prepare("
                SELECT location, district, taluka, state, country, latitude, longitude
                FROM customers
                WHERE id = :cid
                LIMIT 1
            ");
            $cStmt->execute([':cid' => $customerId]);
            $cData = $cStmt->fetch(PDO::FETCH_ASSOC);
            if ($cData && (!empty($cData['location']) || !empty($cData['district']) || !empty($cData['taluka']) || ((float)$cData['latitude'] != 0.0))) {
                $addrParts = array_filter([$cData['location'], $cData['taluka'], $cData['district'], $cData['state'], $cData['country']]);
                $fullAddr = implode(', ', $addrParts);
                $addresses[] = [
                    'id'           => 0,
                    'customer_id'  => $customerId,
                    'full_address' => $fullAddr ?: 'Profile Location',
                    'area'         => $cData['taluka'] ?? '',
                    'city'         => $cData['district'] ?? '',
                    'state'        => $cData['state'] ?? '',
                    'country'      => $cData['country'] ?? 'India',
                    'latitude'     => (float)($cData['latitude'] ?? 0.0),
                    'longitude'    => (float)($cData['longitude'] ?? 0.0),
                    'pincode'      => '',
                    'is_default'   => 1,
                    'address_type' => 'Profile Location',
                    'tag'          => 'PROFILE'
                ];
            }
        } catch (PDOException $e) {}
    }

    // Format fields
    foreach ($addresses as &$addr) {
        $addr['id']          = (int)$addr['id'];
        $addr['customer_id'] = (int)$addr['customer_id'];
        $addr['latitude']    = (float)$addr['latitude'];
        $addr['longitude']   = (float)$addr['longitude'];
        $addr['is_default']  = (bool)$addr['is_default'];
    }
    unset($addr);

    sendSuccess('Customer addresses retrieved successfully.', [
        'customer_id' => $customerId,
        'addresses'   => $addresses
    ]);

} catch (Exception $e) {
    sendError('Failed to retrieve customer addresses: ' . $e->getMessage(), 500);
}
