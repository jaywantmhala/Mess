<?php
/**
 * GET  /api/auth/address         — fetch all saved addresses for the authenticated customer
 * POST /api/auth/address         — add or edit address for the authenticated customer
 * POST /api/auth/address/delete  — delete a saved address
 * POST /api/auth/address/select  — set active default address
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

// ── Migration / Table Setup ───────────────────────────────────────────────────
try {
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS customer_addresses (
            id            INT AUTO_INCREMENT PRIMARY KEY,
            customer_id   INT NOT NULL,
            name          VARCHAR(255) DEFAULT '',
            mobile_number VARCHAR(20) DEFAULT '',
            tag           VARCHAR(20) NOT NULL DEFAULT 'HOME',
            full_address  TEXT NOT NULL,
            house_no      VARCHAR(255) DEFAULT '',
            area          VARCHAR(255) DEFAULT '',
            city          VARCHAR(255) DEFAULT '',
            state         VARCHAR(255) DEFAULT '',
            country       VARCHAR(255) DEFAULT '',
            pincode       VARCHAR(20) DEFAULT '',
            landmark      VARCHAR(255) DEFAULT '',
            place_id      VARCHAR(255) DEFAULT '',
            latitude      DECIMAL(10,7) DEFAULT 0,
            longitude     DECIMAL(10,7) DEFAULT 0,
            is_default    TINYINT(1) DEFAULT 0,
            created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_customer (customer_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ");

    $stmtAddr = $pdo->query("DESCRIBE `customer_addresses`");
    $addrCols = $stmtAddr->fetchAll(PDO::FETCH_COLUMN);

    if (!in_array('name', $addrCols)) {
        $pdo->exec("ALTER TABLE `customer_addresses` ADD COLUMN `name` VARCHAR(255) DEFAULT ''");
    }
    if (!in_array('mobile_number', $addrCols)) {
        $pdo->exec("ALTER TABLE `customer_addresses` ADD COLUMN `mobile_number` VARCHAR(20) DEFAULT ''");
    }
    if (!in_array('tag', $addrCols)) {
        $pdo->exec("ALTER TABLE `customer_addresses` ADD COLUMN `tag` VARCHAR(20) NOT NULL DEFAULT 'HOME'");
    }
    if (!in_array('house_no', $addrCols)) {
        $pdo->exec("ALTER TABLE `customer_addresses` ADD COLUMN `house_no` VARCHAR(255) DEFAULT ''");
    }
    if (!in_array('is_default', $addrCols)) {
        $pdo->exec("ALTER TABLE `customer_addresses` ADD COLUMN `is_default` TINYINT(1) DEFAULT 0");
    }
    if (!in_array('district', $addrCols)) {
        $pdo->exec("ALTER TABLE `customer_addresses` ADD COLUMN `district` VARCHAR(255) DEFAULT ''");
    }
    if (!in_array('taluka', $addrCols)) {
        $pdo->exec("ALTER TABLE `customer_addresses` ADD COLUMN `taluka` VARCHAR(255) DEFAULT ''");
    }

    // Drop old single-address constraint if present
    try {
        $pdo->exec("ALTER TABLE `customer_addresses` DROP INDEX `uq_customer`");
    } catch (Exception $exDrop) {}
} catch (Exception $exTable) {}

$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

// ── GET — fetch saved addresses ───────────────────────────────────────────────
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $stmt = $pdo->prepare("SELECT * FROM customer_addresses WHERE customer_id = :cid ORDER BY is_default DESC, id DESC");
    $stmt->execute([':cid' => $customerId]);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $primary = null;
    if (!empty($rows)) {
        $primary = $rows[0];
    }

    sendSuccess('Addresses fetched.', [
        'addresses' => $rows,
        'address'   => $primary
    ]);
}

// ── POST — save, update, delete, or set default address ───────────────────────
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $raw  = file_get_contents('php://input');
    $body = json_decode($raw, true) ?: [];
    if (empty($body) && !empty($_POST)) {
        $body = $_POST;
    }

    $action = strtolower($body['action'] ?? $_GET['action'] ?? '');
    
    // ── Delete Address Handler ────────────────────────────────────────────────
    if (stripos($uri, 'delete') !== false || $action === 'delete' || $action === 'remove') {
        $addressId = (int)($body['id'] ?? $body['address_id'] ?? $body['addressId'] ?? $_GET['id'] ?? $_GET['address_id'] ?? 0);
        if ($addressId <= 0) {
            sendError('Valid address id is required for deletion.', 422);
            exit;
        }

        $delStmt = $pdo->prepare("DELETE FROM customer_addresses WHERE id = ? AND customer_id = ?");
        $delStmt->execute([$addressId, $customerId]);

        // If no default left, set latest address as default
        $cntStmt = $pdo->prepare("SELECT id FROM customer_addresses WHERE customer_id = ? AND is_default = 1");
        $cntStmt->execute([$customerId]);
        if (!$cntStmt->fetch()) {
            $defUpd = $pdo->prepare("UPDATE customer_addresses SET is_default = 1 WHERE customer_id = ? ORDER BY id DESC LIMIT 1");
            $defUpd->execute([$customerId]);
        }

        sendSuccess('Address deleted successfully.', ['deleted_id' => $addressId]);
        exit;
    }

    // ── Set Default / Select Address Handler ─────────────────────────────────
    if (stripos($uri, 'set_default') !== false || stripos($uri, 'select') !== false || $action === 'set_default' || $action === 'select') {
        $addressId = (int)($body['id'] ?? $body['address_id'] ?? $body['addressId'] ?? $_GET['id'] ?? $_GET['address_id'] ?? 0);
        if ($addressId <= 0) {
            sendError('Valid address id is required.', 422);
            exit;
        }

        $pdo->prepare("UPDATE customer_addresses SET is_default = 0 WHERE customer_id = ?")->execute([$customerId]);
        $pdo->prepare("UPDATE customer_addresses SET is_default = 1 WHERE id = ? AND customer_id = ?")->execute([$addressId, $customerId]);

        sendSuccess('Default address updated.', ['selected_id' => $addressId]);
        exit;
    }

    // ── Save or Edit Address ──────────────────────────────────────────────────
    if (empty($body['full_address'])) {
        sendError('full_address is required.', 422);
    }

    $addressId   = isset($body['id']) && (int)$body['id'] > 0 ? (int)$body['id'] : null;
    $name        = trim($body['name'] ?? $body['receiver_name'] ?? '');
    $mobile      = trim($body['mobile_number'] ?? $body['mobile_no'] ?? $body['phone'] ?? '');
    $tag         = strtoupper(trim($body['tag'] ?? 'HOME'));
    $fullAddress = trim($body['full_address']);
    $houseNo     = isset($body['house_no'])   ? trim($body['house_no'])   : '';
    $latitude    = isset($body['latitude'])   ? (float) $body['latitude'] : 0.0;
    $longitude   = isset($body['longitude'])  ? (float) $body['longitude']: 0.0;
    $area        = isset($body['area'])       ? trim($body['area'])       : '';
    $city        = isset($body['city'])       ? trim($body['city'])       : '';
    $state       = isset($body['state'])      ? trim($body['state'])      : '';
    $district    = isset($body['district'])   ? trim($body['district'])   : '';
    $taluka      = isset($body['taluka'])     ? trim($body['taluka'])     : '';
    $country     = !empty($body['country'])   ? trim($body['country'])    : 'India';
    $pincode     = isset($body['pincode'])    ? trim($body['pincode'])    : '';
    $landmark    = isset($body['landmark'])   ? trim($body['landmark'])   : '';
    $placeId     = isset($body['place_id'])   ? trim($body['place_id'])   : '';
    $isDefault   = isset($body['is_default']) ? ((bool)$body['is_default'] ? 1 : 0) : 0;

    if (!in_array($tag, ['HOME', 'OFFICE', 'WORK', 'OTHER'])) {
        $tag = 'OTHER';
    }
    if ($tag === 'WORK') {
        $tag = 'OFFICE';
    }

    // Check if this is customer's first address
    $cntStmt = $pdo->prepare("SELECT COUNT(*) FROM customer_addresses WHERE customer_id = ?");
    $cntStmt->execute([$customerId]);
    $existingCount = (int)$cntStmt->fetchColumn();
    if ($existingCount === 0) {
        $isDefault = 1;
    }

    if ($isDefault === 1) {
        $pdo->prepare("UPDATE customer_addresses SET is_default = 0 WHERE customer_id = ?")->execute([$customerId]);
    }

    if ($addressId) {
        // UPDATE
        $updSql = "
            UPDATE customer_addresses SET
                name          = :name,
                mobile_number = :mobile,
                tag           = :tag,
                full_address  = :full_address,
                house_no      = :house_no,
                area          = :area,
                city          = :city,
                state         = :state,
                district      = :district,
                taluka        = :taluka,
                country       = :country,
                pincode       = :pincode,
                landmark      = :landmark,
                place_id      = :place_id,
                latitude      = :lat,
                longitude     = :lng,
                is_default    = :is_def,
                updated_at    = NOW()
            WHERE id = :id AND customer_id = :cid
        ";
        $stmt = $pdo->prepare($updSql);
        $stmt->execute([
            ':name'         => $name,
            ':mobile'       => $mobile,
            ':tag'          => $tag,
            ':full_address' => $fullAddress,
            ':house_no'     => $houseNo,
            ':area'         => $area,
            ':city'         => $city,
            ':state'        => $state,
            ':district'     => $district,
            ':taluka'       => $taluka,
            ':country'      => $country,
            ':pincode'      => $pincode,
            ':landmark'     => $landmark,
            ':place_id'     => $placeId,
            ':lat'          => $latitude,
            ':lng'          => $longitude,
            ':is_def'       => $isDefault,
            ':id'           => $addressId,
            ':cid'          => $customerId,
        ]);
        $savedId = $addressId;
    } else {
        // INSERT
        $insSql = "
            INSERT INTO customer_addresses
                (customer_id, name, mobile_number, tag, full_address, house_no, area, city, state, district, taluka, country, pincode, landmark, place_id, latitude, longitude, is_default, created_at, updated_at)
            VALUES
                (:cid, :name, :mobile, :tag, :full_address, :house_no, :area, :city, :state, :district, :taluka, :country, :pincode, :landmark, :place_id, :lat, :lng, :is_def, NOW(), NOW())
        ";
        $stmt = $pdo->prepare($insSql);
        $stmt->execute([
            ':cid'          => $customerId,
            ':name'         => $name,
            ':mobile'       => $mobile,
            ':tag'          => $tag,
            ':full_address' => $fullAddress,
            ':house_no'     => $houseNo,
            ':area'         => $area,
            ':city'         => $city,
            ':state'        => $state,
            ':district'     => $district,
            ':taluka'       => $taluka,
            ':country'      => $country,
            ':pincode'      => $pincode,
            ':landmark'     => $landmark,
            ':place_id'     => $placeId,
            ':lat'          => $latitude,
            ':lng'          => $longitude,
            ':is_def'       => $isDefault,
        ]);
        $savedId = (int)$pdo->lastInsertId();
    }

    // Fetch and return saved address row
    $fetchStmt = $pdo->prepare("SELECT * FROM customer_addresses WHERE id = ? AND customer_id = ?");
    $fetchStmt->execute([$savedId, $customerId]);
    $saved = $fetchStmt->fetch(PDO::FETCH_ASSOC);

    sendSuccess('Address saved successfully.', ['address' => $saved]);
}

sendError('Method not allowed.', 405);
