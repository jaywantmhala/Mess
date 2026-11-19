<?php
/**
 * POST /api/admin/notifications/send
 *
 * Broadcast push notification from Admin to All Users, Customers, Vendors, or Drivers
 * with optional location filters (state, district, taluka).
 * Body: { title, body, target ("all"|"customers"|"vendors"|"drivers"), state?, district?, taluka?, click_action?, image_url?, brand_color?, action_buttons? }
 */

require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../helpers/response.php';
require_once __DIR__ . '/../../../helpers/validation.php';
require_once __DIR__ . '/../../../helpers/jwt.php';
require_once __DIR__ . '/../../../helpers/fcm.php';
require_once __DIR__ . '/../../../helpers/ably_helper.php';

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

$body = requireJsonBody(['title', 'body']);
$title            = trim($body['title']);
$notificationBody = trim($body['body']);
$target           = strtolower(trim($body['target'] ?? 'all'));
$state            = trim($body['state'] ?? '');
$district         = trim($body['district'] ?? '');
$taluka           = trim($body['taluka'] ?? '');
$clickAction      = trim($body['click_action'] ?? 'HOME');
$imageUrl         = trim($body['image_url'] ?? '');
$brandColor       = trim($body['brand_color'] ?? '#FF6B35');
$actionButtons    = $body['action_buttons'] ?? []; // array of {title, action}

if ($district === 'all') $district = '';
if ($taluka === 'all')   $taluka   = '';
if ($state === 'all')    $state    = '';

if (empty($title))            { sendError('Notification title is required.', 422); }
if (empty($notificationBody)) { sendError('Notification body is required.', 422); }

if ($target === 'vendor') {
    $target = 'vendors';
} elseif ($target === 'customer') {
    $target = 'customers';
} elseif ($target === 'driver') {
    $target = 'drivers';
}

$validTargets = ['all', 'customers', 'vendors', 'drivers'];
if (!in_array($target, $validTargets, true)) {
    $target = 'all';
}

$pdo = getDBConnection();
$tokens = [];

try {
    // 1. Collect Customer FCM Tokens with Location Filters
    if ($target === 'customers' || $target === 'all') {
        $cWhere = ["c.fcm_token IS NOT NULL AND c.fcm_token != ''"];
        $cParams = [];

        if (!empty($state)) {
            $cWhere[] = "(c.state = :state OR ca.state = :state_ca OR LOWER(ca.full_address) LIKE :state_like)";
            $cParams[':state'] = $state;
            $cParams[':state_ca'] = $state;
            $cParams[':state_like'] = '%' . strtolower($state) . '%';
        }
        if (!empty($district)) {
            $cWhere[] = "(c.district = :dist OR ca.district = :dist_ca OR LOWER(ca.city) = LOWER(:city) OR LOWER(ca.full_address) LIKE :dist_like)";
            $cParams[':dist'] = $district;
            $cParams[':dist_ca'] = $district;
            $cParams[':city'] = $district;
            $cParams[':dist_like'] = '%' . strtolower($district) . '%';
        }
        if (!empty($taluka)) {
            $cWhere[] = "(c.taluka = :tal OR ca.taluka = :tal_ca OR LOWER(ca.full_address) LIKE :tal_like)";
            $cParams[':tal'] = $taluka;
            $cParams[':tal_ca'] = $taluka;
            $cParams[':tal_like'] = '%' . strtolower($taluka) . '%';
        }

        $cSql = "SELECT DISTINCT c.fcm_token FROM customers c LEFT JOIN customer_addresses ca ON ca.customer_id = c.id WHERE " . implode(' AND ', $cWhere);
        $cStmt = $pdo->prepare($cSql);
        $cStmt->execute($cParams);
        while ($row = $cStmt->fetch()) {
            if (!empty($row['fcm_token'])) { $tokens[] = $row['fcm_token']; }
        }
    }

    // 2. Collect Vendor FCM Tokens and IDs with Location Filters
    $vendorIds = [];
    if ($target === 'vendors' || $target === 'all') {
        $vWhere = [];
        $vParams = [];

        if (!empty($state)) {
            $vWhere[] = "(v.state = :state OR h.state = :state_h OR LOWER(h.hotel_address) LIKE :state_like)";
            $vParams[':state'] = $state;
            $vParams[':state_h'] = $state;
            $vParams[':state_like'] = '%' . strtolower($state) . '%';
        }
        if (!empty($district)) {
            $vWhere[] = "(v.district = :dist OR h.district = :dist_h OR LOWER(h.city) = LOWER(:city) OR LOWER(h.hotel_address) LIKE :dist_like)";
            $vParams[':dist'] = $district;
            $vParams[':dist_h'] = $district;
            $vParams[':city'] = $district;
            $vParams[':dist_like'] = '%' . strtolower($district) . '%';
        }
        if (!empty($taluka)) {
            $vWhere[] = "(v.taluka = :tal OR h.taluka = :tal_h OR LOWER(h.hotel_address) LIKE :tal_like)";
            $vParams[':tal'] = $taluka;
            $vParams[':tal_h'] = $taluka;
            $vParams[':tal_like'] = '%' . strtolower($taluka) . '%';
        }

        $vWhereClause = count($vWhere) > 0 ? ' WHERE ' . implode(' AND ', $vWhere) : '';
        $vSql = "SELECT DISTINCT v.id, v.fcm_token FROM vendors v LEFT JOIN hotels h ON h.vendor_id = v.id" . $vWhereClause;
        $vStmt = $pdo->prepare($vSql);
        $vStmt->execute($vParams);
        while ($row = $vStmt->fetch(PDO::FETCH_ASSOC)) {
            if (!empty($row['id'])) {
                $vendorIds[] = (int)$row['id'];
            }
            if (!empty($row['fcm_token'])) {
                $tokens[] = $row['fcm_token'];
            }
        }
    }

    // 3. Collect Driver FCM Tokens and IDs with Location Filters
    $driverIds = [];
    if ($target === 'drivers' || $target === 'all') {
        $dWhere = [];
        $dParams = [];

        if (!empty($state)) {
            $dWhere[] = "d.state = :state";
            $dParams[':state'] = $state;
        }
        if (!empty($district)) {
            $dWhere[] = "d.district = :dist";
            $dParams[':dist'] = $district;
        }
        if (!empty($taluka)) {
            $dWhere[] = "d.taluka = :tal";
            $dParams[':tal'] = $taluka;
        }

        $dWhereClause = count($dWhere) > 0 ? ' WHERE ' . implode(' AND ', $dWhere) : '';
        $dSql = "SELECT DISTINCT d.id, d.fcm_token FROM drivers d" . $dWhereClause;
        $dStmt = $pdo->prepare($dSql);
        $dStmt->execute($dParams);
        while ($row = $dStmt->fetch(PDO::FETCH_ASSOC)) {
            if (!empty($row['id'])) {
                $driverIds[] = (int)$row['id'];
            }
            if (!empty($row['fcm_token'])) {
                $tokens[] = $row['fcm_token'];
            }
        }
    }

    // Deduplicate tokens
    $tokens = array_unique($tokens);
    $sentCount = 0;

    // 4. Save to admin_notifications table first to obtain generated ID
    $insertStmt = $pdo->prepare("
        INSERT INTO admin_notifications (title, body, target, state, district, taluka, target_count, click_action, image_url, created_at)
        VALUES (:title, :body, :target, :state, :district, :taluka, :target_count, :click_action, :image_url, NOW())
    ");
    $insertStmt->execute([
        ':title'        => $title,
        ':body'         => $notificationBody,
        ':target'       => $target,
        ':state'        => $state ?: null,
        ':district'     => $district ?: null,
        ':taluka'       => $taluka ?: null,
        ':target_count' => 0,
        ':click_action' => $clickAction,
        ':image_url'    => $imageUrl
    ]);

    $logId = (int)$pdo->lastInsertId();

    $extraData = [
        'event'          => 'ADMIN_BROADCAST',
        'type'           => 'admin_notification',
        'id'             => $logId,
        'notification_id'=> 'admin_' . $logId,
        'target'         => $target,
        'state'          => $state,
        'district'       => $district,
        'taluka'         => $taluka,
        'click_action'   => $clickAction,
        'image_url'      => $imageUrl,
        'image'          => $imageUrl,
        'brand_color'    => $brandColor,
        'action_buttons' => json_encode($actionButtons),
        'title'          => $title,
        'body'           => $notificationBody,
        'timestamp'      => date('Y-m-d H:i:s')
    ];

    // Send via FCM HTTP v1 Native Push in parallel (cURL Multi)
    if (!empty($tokens)) {
        $sentCount = FcmHelper::sendBatchNotifications($tokens, $title, $notificationBody, $extraData);
    }

    // Update target_count in database with delivered count
    if ($sentCount > 0) {
        $upStmt = $pdo->prepare("UPDATE admin_notifications SET target_count = ? WHERE id = ?");
        $upStmt->execute([$sentCount, $logId]);
    }

    // Publish via Ably Realtime to Global Events channel
    AblyHelper::publish('ADMIN_BROADCAST', $extraData);

    // Also publish directly to individual targeted Vendor and Driver channels so online clients update immediately
    if ($target === 'vendors' || $target === 'all') {
        foreach (array_unique($vendorIds) as $vId) {
            $vChan = AblyHelper::getVendorChannel($vId);
            AblyHelper::publish('ADMIN_BROADCAST', $extraData, $vChan);
        }
    }
    if ($target === 'drivers' || $target === 'all') {
        foreach (array_unique($driverIds) as $dId) {
            $dChan = AblyHelper::getDriverChannel($dId);
            AblyHelper::publish('ADMIN_BROADCAST', $extraData, $dChan);
        }
    }

    $filterSummary = [];
    if ($state)    $filterSummary[] = "State: $state";
    if ($district) $filterSummary[] = "District: $district";
    if ($taluka)   $filterSummary[] = "Taluka: $taluka";
    $filterStr = count($filterSummary) > 0 ? ' (' . implode(', ', $filterSummary) . ')' : '';

    $totalTokens = count($tokens);
    if ($totalTokens === 0) {
        $msg = "No registered devices found matching the selected filters$filterStr.";
    } elseif ($sentCount > 0) {
        $msg = "Notification broadcasted successfully to $sentCount device(s)$filterStr.";
    } else {
        $msg = "Broadcast processed for $totalTokens target device(s), but 0 were delivered because the FCM tokens were expired/unregistered by Google Firebase. Stale tokens have been cleaned up from database.";
    }

    sendSuccess($msg, [
        'id'           => (int)$logId,
        'title'        => $title,
        'body'         => $notificationBody,
        'target'       => $target,
        'district'     => $district,
        'taluka'       => $taluka,
        'sent_count'   => $sentCount,
        'total_tokens' => $totalTokens,
        'created_at'   => date('Y-m-d H:i:s')
    ]);

} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
