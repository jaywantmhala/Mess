<?php
/**
 * tiffin_charge_helper.php
 * Resolves the area-specific tiffin charge and area name for a customer.
 * Includes original price, discounted price, and discount percentage.
 */

if (!function_exists('resolveAreaTiffinCharge')) {
    function resolveAreaTiffinCharge(
        PDO $pdo,
        int $customerId,
        ?int $hotelId = null,
        ?float $latitude = null,
        ?float $longitude = null
    ): array {
        $defaultCharge = 50.00;

        // 1. Check if customer has an active subscription
        try {
            $subStmt = $pdo->prepare("
                SELECT cs.id AS sub_id, cs.plan_id,
                       p.tiffin_charge AS plan_tiffin, p.original_tiffin_charge AS plan_orig_tiffin, p.plan_name,
                       sl.id AS sl_id, sl.location_name, sl.tiffin_charge AS sl_tiffin, sl.original_tiffin_charge AS sl_orig_tiffin,
                       sp.tiffin_charge AS sp_tiffin, sp.original_tiffin_charge AS sp_orig_tiffin, sp.plan_name AS sp_name
                FROM customer_subscriptions cs
                LEFT JOIN plans p ON p.id = cs.plan_id
                LEFT JOIN service_locations sl ON sl.id = p.service_location_id
                LEFT JOIN subscription_plans sp ON sp.id = cs.plan_id
                WHERE cs.customer_id = ?
                  AND cs.status = 'ACTIVE'
                  AND cs.end_date >= CURDATE()
                  AND cs.remaining_deliveries > 0
                ORDER BY cs.id DESC LIMIT 1
            ");
            $subStmt->execute([$customerId]);
            $subRow = $subStmt->fetch(PDO::FETCH_ASSOC);

            if ($subRow) {
                $charge = null;
                $origCharge = 0.0;
                if (!empty($subRow['sl_tiffin']) && (float)$subRow['sl_tiffin'] > 0) {
                    $charge = (float)$subRow['sl_tiffin'];
                    $origCharge = (float)($subRow['sl_orig_tiffin'] ?? 0.0);
                } elseif (!empty($subRow['plan_tiffin']) && (float)$subRow['plan_tiffin'] > 0) {
                    $charge = (float)$subRow['plan_tiffin'];
                    $origCharge = (float)($subRow['plan_orig_tiffin'] ?? 0.0);
                } elseif (!empty($subRow['sp_tiffin']) && (float)$subRow['sp_tiffin'] > 0) {
                    $charge = (float)$subRow['sp_tiffin'];
                    $origCharge = (float)($subRow['sp_orig_tiffin'] ?? 0.0);
                } else {
                    $charge = $defaultCharge;
                }

                $disc = ($origCharge > $charge && $origCharge > 0)
                    ? round((($origCharge - $charge) / $origCharge) * 100, 1)
                    : 0;

                return [
                    'tiffin_charge'          => $charge,
                    'original_tiffin_charge' => $origCharge,
                    'discount_percentage'    => $disc,
                    'has_discount'           => ($origCharge > $charge && $origCharge > 0),
                    'area_name'              => $subRow['location_name'] ?? $subRow['plan_name'] ?? $subRow['sp_name'] ?? 'Subscribed Area',
                    'source'                 => 'subscription',
                    'plan_id'                => (int)$subRow['plan_id'],
                    'subscription_id'        => (int)$subRow['sub_id'],
                    'service_location_id'    => $subRow['sl_id'] ? (int)$subRow['sl_id'] : null,
                ];
            }
        } catch (Exception $e) {
            // Ignore error and continue to location resolution
        }

        // 2. Resolve customer coordinates if not provided
        $lat = $latitude ?? 0.0;
        $lng = $longitude ?? 0.0;
        $custAreaName = null;

        if ($lat == 0.0 && $lng == 0.0) {
            try {
                $addrStmt = $pdo->prepare("
                    SELECT latitude, longitude, area, city
                    FROM customer_addresses
                    WHERE customer_id = ?
                    ORDER BY is_default DESC, id DESC LIMIT 1
                ");
                $addrStmt->execute([$customerId]);
                $addrRow = $addrStmt->fetch(PDO::FETCH_ASSOC);
                if ($addrRow) {
                    $lat = (float)($addrRow['latitude'] ?? 0);
                    $lng = (float)($addrRow['longitude'] ?? 0);
                    $custAreaName = $addrRow['area'] ?? null;
                }
            } catch (Exception $e) {}
        }

        // 3. Match customer GPS with service_locations
        if ($lat != 0.0 && $lng != 0.0) {
            try {
                $stmt = $pdo->prepare("
                    SELECT sl.id, sl.location_name, sl.tiffin_charge, sl.original_tiffin_charge,
                           ROUND(
                               ST_Distance_Sphere(
                                   sl.location,
                                   ST_PointFromText(CONCAT('POINT(', :lng, ' ', :lat, ')'), 4326)
                               ) / 1000, 3
                           ) AS distance_km
                    FROM service_locations sl
                    WHERE sl.status = 'active'
                      AND sl.latitude != 0 AND sl.longitude != 0
                      AND ST_Distance_Sphere(
                          sl.location,
                          ST_PointFromText(CONCAT('POINT(', :lng2, ' ', :lat2, ')'), 4326)
                      ) <= (sl.radius_km + 0.2) * 1000
                    ORDER BY distance_km ASC
                    LIMIT 1
                ");
                $stmt->execute([
                    ':lat' => $lat, ':lng' => $lng,
                    ':lat2' => $lat, ':lng2' => $lng,
                ]);
                $locRow = $stmt->fetch(PDO::FETCH_ASSOC);
                if ($locRow) {
                    $charge = (!empty($locRow['tiffin_charge']) && (float)$locRow['tiffin_charge'] > 0)
                        ? (float)$locRow['tiffin_charge']
                        : $defaultCharge;
                    $origCharge = !empty($locRow['original_tiffin_charge']) ? (float)$locRow['original_tiffin_charge'] : 0.0;
                    $disc = ($origCharge > $charge && $origCharge > 0)
                        ? round((($origCharge - $charge) / $origCharge) * 100, 1)
                        : 0;
                    return [
                        'tiffin_charge'          => $charge,
                        'original_tiffin_charge' => $origCharge,
                        'discount_percentage'    => $disc,
                        'has_discount'           => ($origCharge > $charge && $origCharge > 0),
                        'area_name'              => $locRow['location_name'],
                        'source'                 => 'customer_location',
                        'service_location_id'    => (int)$locRow['id'],
                    ];
                }
            } catch (Exception $e) {}
        }

        // 4. Try Hotel coordinates / area match if hotelId provided
        $hotelArea = null;
        if ($hotelId) {
            try {
                $hStmt = $pdo->prepare("SELECT latitude, longitude, area, city FROM hotels WHERE id = ?");
                $hStmt->execute([$hotelId]);
                $hRow = $hStmt->fetch(PDO::FETCH_ASSOC);
                if ($hRow) {
                    $hotelLat = (float)($hRow['latitude'] ?? 0);
                    $hotelLng = (float)($hRow['longitude'] ?? 0);
                    $hotelArea = $hRow['area'] ?? null;

                    if ($hotelLat != 0.0 && $hotelLng != 0.0) {
                        $stmt = $pdo->prepare("
                            SELECT sl.id, sl.location_name, sl.tiffin_charge, sl.original_tiffin_charge,
                                   ROUND(
                                       ST_Distance_Sphere(
                                           sl.location,
                                           ST_PointFromText(CONCAT('POINT(', :lng, ' ', :lat, ')'), 4326)
                                       ) / 1000, 3
                                   ) AS distance_km
                            FROM service_locations sl
                            WHERE sl.status = 'active'
                              AND sl.latitude != 0 AND sl.longitude != 0
                              AND ST_Distance_Sphere(
                                  sl.location,
                                  ST_PointFromText(CONCAT('POINT(', :lng2, ' ', :lat2, ')'), 4326)
                              ) <= (sl.radius_km + 0.5) * 1000
                            ORDER BY distance_km ASC
                            LIMIT 1
                        ");
                        $stmt->execute([
                            ':lat' => $hotelLat, ':lng' => $hotelLng,
                            ':lat2' => $hotelLat, ':lng2' => $hotelLng,
                        ]);
                        $locRow = $stmt->fetch(PDO::FETCH_ASSOC);
                        if ($locRow) {
                            $charge = (!empty($locRow['tiffin_charge']) && (float)$locRow['tiffin_charge'] > 0)
                                ? (float)$locRow['tiffin_charge']
                                : $defaultCharge;
                            $origCharge = !empty($locRow['original_tiffin_charge']) ? (float)$locRow['original_tiffin_charge'] : 0.0;
                            $disc = ($origCharge > $charge && $origCharge > 0)
                                ? round((($origCharge - $charge) / $origCharge) * 100, 1)
                                : 0;
                            return [
                                'tiffin_charge'          => $charge,
                                'original_tiffin_charge' => $origCharge,
                                'discount_percentage'    => $disc,
                                'has_discount'           => ($origCharge > $charge && $origCharge > 0),
                                'area_name'              => $locRow['location_name'],
                                'source'                 => 'hotel_location',
                                'service_location_id'    => (int)$locRow['id'],
                            ];
                        }
                    }
                }
            } catch (Exception $e) {}
        }

        // 5. Try name/text match with service locations
        $candidateArea = $custAreaName ?? $hotelArea;
        if (!empty($candidateArea)) {
            try {
                $stmt = $pdo->prepare("
                    SELECT id, location_name, tiffin_charge, original_tiffin_charge
                    FROM service_locations
                    WHERE status = 'active'
                      AND (LOWER(location_name) LIKE LOWER(?) OR LOWER(?) LIKE CONCAT('%', LOWER(location_name), '%'))
                    LIMIT 1
                ");
                $param = '%' . trim($candidateArea) . '%';
                $stmt->execute([$param, $candidateArea]);
                $locRow = $stmt->fetch(PDO::FETCH_ASSOC);
                if ($locRow) {
                    $charge = (!empty($locRow['tiffin_charge']) && (float)$locRow['tiffin_charge'] > 0)
                        ? (float)$locRow['tiffin_charge']
                        : $defaultCharge;
                    $origCharge = !empty($locRow['original_tiffin_charge']) ? (float)$locRow['original_tiffin_charge'] : 0.0;
                    $disc = ($origCharge > $charge && $origCharge > 0)
                        ? round((($origCharge - $charge) / $origCharge) * 100, 1)
                        : 0;
                    return [
                        'tiffin_charge'          => $charge,
                        'original_tiffin_charge' => $origCharge,
                        'discount_percentage'    => $disc,
                        'has_discount'           => ($origCharge > $charge && $origCharge > 0),
                        'area_name'              => $locRow['location_name'],
                        'source'                 => 'area_name_match',
                        'service_location_id'    => (int)$locRow['id'],
                    ];
                }
            } catch (Exception $e) {}
        }

        // 6. Default fallback: first active service location
        try {
            $stmt = $pdo->query("SELECT location_name, tiffin_charge, original_tiffin_charge FROM service_locations WHERE status = 'active' ORDER BY id ASC LIMIT 1");
            $firstLoc = $stmt->fetch(PDO::FETCH_ASSOC);
            if ($firstLoc) {
                $charge = (!empty($firstLoc['tiffin_charge']) && (float)$firstLoc['tiffin_charge'] > 0)
                    ? (float)$firstLoc['tiffin_charge']
                    : $defaultCharge;
                $origCharge = !empty($firstLoc['original_tiffin_charge']) ? (float)$firstLoc['original_tiffin_charge'] : 0.0;
                $disc = ($origCharge > $charge && $origCharge > 0)
                    ? round((($origCharge - $charge) / $origCharge) * 100, 1)
                    : 0;
                return [
                    'tiffin_charge'          => $charge,
                    'original_tiffin_charge' => $origCharge,
                    'discount_percentage'    => $disc,
                    'has_discount'           => ($origCharge > $charge && $origCharge > 0),
                    'area_name'              => $firstLoc['location_name'],
                    'source'                 => 'first_active_location',
                ];
            }
        } catch (Exception $e) {}

        return [
            'tiffin_charge'          => $defaultCharge,
            'original_tiffin_charge' => 0.00,
            'discount_percentage'    => 0,
            'has_discount'           => false,
            'area_name'              => 'Standard Area',
            'source'                 => 'default_fallback',
        ];
    }
}
