<?php
/**
 * GET /api/customer/subscription/current
 *
 * Fetch the authenticated customer's current/latest subscription.
 */

require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../helpers/response.php';
require_once __DIR__ . '/../../../helpers/jwt.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    sendError('Method not allowed. Use GET.', 405);
}

$token   = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;

if (!$payload || !isset($payload['sub'])) {
    sendError('Unauthorized. Please log in.', 401);
}

$customerId = (int)$payload['sub'];

try {
    $pdo = getDBConnection();

    // ── Fallback: expire overdue subscriptions & reset wallet balance to 0 ──
    try {
        $expUpd = $pdo->prepare("UPDATE customer_subscriptions SET status = 'EXPIRED', expiration_timestamp = NOW(), updated_at = NOW() WHERE customer_id = ? AND status = 'ACTIVE' AND end_date <= CURDATE()");
        $expUpd->execute([$customerId]);

        $actCheck = $pdo->prepare("SELECT COUNT(*) FROM customer_subscriptions WHERE customer_id = ? AND status = 'ACTIVE' AND end_date > CURDATE() AND remaining_deliveries > 0");
        $actCheck->execute([$customerId]);

        if ((int)$actCheck->fetchColumn() === 0) {
            $wStmt = $pdo->prepare("SELECT wallet_id, balance FROM wallets WHERE customer_id = ? FOR UPDATE");
            $wStmt->execute([$customerId]);
            $w = $wStmt->fetch(PDO::FETCH_ASSOC);
            if ($w && (float)$w['balance'] > 0) {
                $prev = (float)$w['balance'];
                $pdo->prepare("UPDATE wallets SET balance = 0.00, plan_credit_balance = 0.00 WHERE wallet_id = ?")->execute([(int)$w['wallet_id']]);
                $pdo->prepare("INSERT INTO wallet_resets (customer_id, subscription_id, previous_balance, reset_amount, balance_after, reason) VALUES (?, NULL, ?, ?, 0.00, 'NO_ACTIVE_PLAN_EXPIRED')")->execute([$customerId, $prev, $prev]);
                $pdo->prepare("INSERT INTO wallet_transactions (wallet_id, type, amount, description, balance_after) VALUES (?, 'DEBIT', ?, 'Plan Expired - Wallet Reset to 0', 0.00)")->execute([(int)$w['wallet_id'], $prev]);
            }
        }
    } catch (Exception $e) {
        // Silently continue
    }

    // 1. Fetch ACTIVE subscription (must be active, not expired, have remaining deliveries)
    $subSql = "
        SELECT cs.*, 
               COALESCE(p.plan_name, sp.plan_name, 'Active Subscription') AS plan_name,
               COALESCE(p.price, sp.price, 0.00) AS price,
               COALESCE(p.duration, sp.duration, cs.total_deliveries) AS duration,
               COALESCE(p.total_deliveries, sp.total_deliveries, cs.total_deliveries) AS plan_total_deliveries, 
               COALESCE(p.meals_per_day, sp.meals_per_day, 1) AS meals_per_day,
               COALESCE(p.meal_type, sp.meal_type, 'VEG') AS meal_type,
               COALESCE(p.delivery_time_slot, sp.delivery_time_slot, '12:00 PM - 02:00 PM') AS delivery_time_slot,
               COALESCE(p.service_location_id, sp.sub_area_id, 0) AS sub_area_id,
               COALESCE(sl.location_name, sa.sub_area_name, 'Service Zone') AS sub_area_name,
               COALESCE(sl.region, a.area_name, '') AS area_name
        FROM customer_subscriptions cs
        LEFT JOIN plans p ON cs.plan_id = p.id
        LEFT JOIN service_locations sl ON p.service_location_id = sl.id
        LEFT JOIN subscription_plans sp ON cs.plan_id = sp.id
        LEFT JOIN sub_areas sa ON sp.sub_area_id = sa.id
        LEFT JOIN areas a ON sa.area_id = a.id
        WHERE cs.customer_id = ?
          AND cs.status = 'ACTIVE'
          AND cs.end_date >= CURDATE()
          AND cs.remaining_deliveries > 0
        ORDER BY cs.id DESC
        LIMIT 1
    ";
    $subStmt = $pdo->prepare($subSql);
    $subStmt->execute([$customerId]);
    $subscription = $subStmt->fetch(PDO::FETCH_ASSOC);

    if (!$subscription) {
        sendSuccess('No subscription found.', [
            'subscription' => null,
            'next_delivery' => null,
            'deliveries' => [],
            'is_serviceable_at_address' => true,
            'address_warning' => null
        ]);
        exit;
    }

    // Format fields
    $subscription['id'] = (int)$subscription['id'];
    $subscription['customer_id'] = (int)$subscription['customer_id'];
    $subscription['plan_id'] = (int)$subscription['plan_id'];
    $subscription['remaining_deliveries'] = (int)$subscription['remaining_deliveries'];
    $subscription['total_deliveries'] = (int)$subscription['total_deliveries'];
    $subscription['completed_deliveries'] = (int)$subscription['completed_deliveries'];
    $subscription['auto_renew'] = (bool)$subscription['auto_renew'];
    $subscription['price'] = number_format((float)$subscription['price'], 2, '.', '');
    $subscription['pause_history'] = json_decode($subscription['pause_history'] ?? '[]', true);

    // 2. Check if active subscription plan is serviceable at customer's current address
    //    Resolves the plan's service_location (new model) or falls back to sub_area (legacy).
    //    Rule §6: distance_km <= radius_km + 0.2 (GPS tolerance)
    $isServiceableAtAddress = true;
    $addressWarning         = null;

    if ($subscription['status'] === 'ACTIVE') {
        // Prefer GET parameters (current selected address from app), fallback to saved default
        $customerLat = isset($_GET['latitude'])  ? (float)$_GET['latitude']  : 0.0;
        $customerLng = isset($_GET['longitude']) ? (float)$_GET['longitude'] : 0.0;

        if ($customerLat == 0.0 && $customerLng == 0.0) {
            $addrStmt = $pdo->prepare(
                "SELECT latitude, longitude FROM customer_addresses
                 WHERE customer_id = ? AND latitude != 0 AND longitude != 0
                 ORDER BY is_default DESC, id DESC LIMIT 1"
            );
            $addrStmt->execute([$customerId]);
            $addrRow = $addrStmt->fetch(PDO::FETCH_ASSOC);
            if ($addrRow) {
                $customerLat = (float)($addrRow['latitude']  ?? 0.0);
                $customerLng = (float)($addrRow['longitude'] ?? 0.0);
            }
        }

        $hasCoords = ($customerLat != 0.0 && $customerLng != 0.0);

        if ($hasCoords) {
            // Try the new plans table first (service_location_id)
            $planId = (int)$subscription['plan_id'];
            $geoRow = null;

            // Check new plans table
            $newPlanStmt = $pdo->prepare("
                SELECT sl.latitude, sl.longitude, sl.radius_km,
                       ROUND(ST_Distance_Sphere(
                           sl.location,
                           ST_PointFromText(CONCAT('POINT(', :clng, ' ', :clat, ')'), 4326)
                       ) / 1000, 3) AS distance_km
                FROM plans p
                JOIN service_locations sl ON p.service_location_id = sl.id
                WHERE p.id = :plan_id AND sl.latitude != 0 AND sl.longitude != 0
                LIMIT 1
            ");
            $newPlanStmt->execute([':clat' => $customerLat, ':clng' => $customerLng, ':plan_id' => $planId]);
            $geoRow = $newPlanStmt->fetch(PDO::FETCH_ASSOC);

            // Fallback: legacy sub_area (subscription_plans table)
            if (!$geoRow) {
                $legacyStmt = $pdo->prepare("
                    SELECT sa.latitude, sa.longitude, sa.delivery_radius AS radius_km,
                           ROUND(ST_Distance_Sphere(
                               sa.location,
                               ST_PointFromText(CONCAT('POINT(', :clng, ' ', :clat, ')'), 4326)
                           ) / 1000, 3) AS distance_km
                    FROM subscription_plans sp
                    JOIN sub_areas sa ON sp.sub_area_id = sa.id
                    WHERE sp.id = :plan_id AND sa.latitude != 0 AND sa.longitude != 0
                    LIMIT 1
                ");
                $legacyStmt->execute([':clat' => $customerLat, ':clng' => $customerLng, ':plan_id' => $planId]);
                $geoRow = $legacyStmt->fetch(PDO::FETCH_ASSOC);
            }

            if ($geoRow) {
                $distKm      = (float)$geoRow['distance_km'];
                $radiusKm    = (float)($geoRow['radius_km'] ?? 5.0);
                $allowedKm   = $radiusKm + 0.2; // GPS_TOLERANCE_KM

                if ($distKm > $allowedKm) {
                    $isServiceableAtAddress = false;
                    $addressWarning = "Your activated subscription is not available at this selected location. "
                        . "(Distance: {$distKm} km, Plan zone: {$radiusKm} km radius)";
                }
            }
        }
    }

    // 3. Fetch next pending delivery date
    $nextDelSql = "
        SELECT delivery_date 
        FROM subscription_deliveries 
        WHERE subscription_id = ? AND status = 'PENDING' AND delivery_date >= CURDATE()
        ORDER BY delivery_date ASC
        LIMIT 1
    ";
    $nextDelStmt = $pdo->prepare($nextDelSql);
    $nextDelStmt->execute([$subscription['id']]);
    $nextDeliveryDate = $nextDelStmt->fetchColumn() ?: null;

    // 4. Fetch deliveries calendar (list of dates and statuses)
    $delSql = "
        SELECT id, delivery_date, status, order_id 
        FROM subscription_deliveries 
        WHERE subscription_id = ? 
        ORDER BY delivery_date ASC
    ";
    $delStmt = $pdo->prepare($delSql);
    $delStmt->execute([$subscription['id']]);
    $deliveries = $delStmt->fetchAll(PDO::FETCH_ASSOC);

    foreach ($deliveries as &$d) {
        $d['id'] = (int)$d['id'];
        $d['order_id'] = $d['order_id'] ? (int)$d['order_id'] : null;
    }
    unset($d);

    sendSuccess('Subscription details retrieved successfully.', [
        'subscription'  => $subscription,
        'next_delivery' => $nextDeliveryDate,
        'deliveries'    => $deliveries,
        'is_serviceable_at_address' => $isServiceableAtAddress,
        'address_warning' => $addressWarning
    ]);

} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
