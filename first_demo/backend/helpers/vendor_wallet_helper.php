<?php
/**
 * Vendor Wallet Helper Functions
 */

require_once __DIR__ . '/../config/database.php';

class VendorWalletHelper {

    /**
     * Resolves the Area Tiffin Charge for a vendor dynamically.
     * Matches via:
     * 1. Hotel GPS coordinates against service_locations radius
     * 2. Hotel area / city / address matching service_locations
     * 3. Vendor state / district / taluka matching service_locations (address, region, location_name)
     * 4. First active service_locations fallback
     * 5. Default 50.00
     */
    public static function resolveVendorAreaTiffinCharge(PDO $pdo, int $vendorId, ?int $hotelId = null): array {
        $defaultCharge = 50.00;

        // 1. Fetch vendor hotel(s)
        try {
            if ($hotelId && $hotelId > 0) {
                $hStmt = $pdo->prepare("SELECT id, hotel_name, hotel_address, state, district, taluka, area, city, latitude, longitude FROM hotels WHERE id = ? LIMIT 1");
                $hStmt->execute([$hotelId]);
            } else {
                $hStmt = $pdo->prepare("SELECT id, hotel_name, hotel_address, state, district, taluka, area, city, latitude, longitude FROM hotels WHERE vendor_id = ? ORDER BY id ASC LIMIT 1");
                $hStmt->execute([$vendorId]);
            }
            $hotel = $hStmt->fetch(PDO::FETCH_ASSOC);

            if ($hotel) {
                $lat = (float)($hotel['latitude'] ?? 0);
                $lng = (float)($hotel['longitude'] ?? 0);

                // 1A. GPS distance match with active service_locations
                if ($lat != 0.0 && $lng != 0.0) {
                    $gpsStmt = $pdo->prepare("
                        SELECT sl.id, sl.location_name, sl.tiffin_charge,
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
                          ) <= (sl.radius_km + 1.0) * 1000
                        ORDER BY distance_km ASC
                        LIMIT 1
                    ");
                    $gpsStmt->execute([
                        ':lat' => $lat, ':lng' => $lng,
                        ':lat2' => $lat, ':lng2' => $lng,
                    ]);
                    $locRow = $gpsStmt->fetch(PDO::FETCH_ASSOC);
                    if ($locRow && !empty($locRow['tiffin_charge']) && (float)$locRow['tiffin_charge'] > 0) {
                        return [
                            'tiffin_charge'       => (float)$locRow['tiffin_charge'],
                            'area_name'           => $locRow['location_name'],
                            'source'              => 'hotel_gps',
                            'service_location_id' => (int)$locRow['id'],
                        ];
                    }
                }

                // 1B. Hotel area / city / address text match
                $candidates = array_filter([$hotel['area'] ?? null, $hotel['city'] ?? null, $hotel['taluka'] ?? null, $hotel['district'] ?? null]);
                foreach ($candidates as $cand) {
                    $cand = trim((string)$cand);
                    if (empty($cand)) continue;
                    $textStmt = $pdo->prepare("
                        SELECT id, location_name, tiffin_charge
                        FROM service_locations
                        WHERE status = 'active'
                          AND (
                              LOWER(location_name) LIKE LOWER(?)
                              OR LOWER(?) LIKE CONCAT('%', LOWER(location_name), '%')
                              OR LOWER(address) LIKE LOWER(?)
                          )
                        LIMIT 1
                    ");
                    $likeCand = '%' . $cand . '%';
                    $textStmt->execute([$likeCand, $cand, $likeCand]);
                    $locRow = $textStmt->fetch(PDO::FETCH_ASSOC);
                    if ($locRow && !empty($locRow['tiffin_charge']) && (float)$locRow['tiffin_charge'] > 0) {
                        return [
                            'tiffin_charge'       => (float)$locRow['tiffin_charge'],
                            'area_name'           => $locRow['location_name'],
                            'source'              => 'hotel_area_text',
                            'service_location_id' => (int)$locRow['id'],
                        ];
                    }
                }
            }
        } catch (Throwable $e) {
            error_log("Error in resolveVendorAreaTiffinCharge hotel check: " . $e->getMessage());
        }

        // 2. Check vendor profile location: district, taluka, state
        try {
            $vStmt = $pdo->prepare("SELECT state, district, taluka, country FROM vendors WHERE id = ? LIMIT 1");
            $vStmt->execute([$vendorId]);
            $vendor = $vStmt->fetch(PDO::FETCH_ASSOC);

            if ($vendor) {
                $vDistrict = trim((string)($vendor['district'] ?? ''));
                $vTaluka   = trim((string)($vendor['taluka'] ?? ''));
                $vState    = trim((string)($vendor['state'] ?? ''));

                // Priority 1: Match vendor district (e.g. Pune)
                if (!empty($vDistrict)) {
                    $distStmt = $pdo->prepare("
                        SELECT id, location_name, tiffin_charge
                        FROM service_locations
                        WHERE status = 'active'
                          AND (
                              LOWER(location_name) LIKE LOWER(?)
                              OR LOWER(address) LIKE LOWER(?)
                              OR LOWER(region) LIKE LOWER(?)
                          )
                        ORDER BY id ASC
                        LIMIT 1
                    ");
                    $likeDist = '%' . $vDistrict . '%';
                    $distStmt->execute([$likeDist, $likeDist, $likeDist]);
                    $locRow = $distStmt->fetch(PDO::FETCH_ASSOC);
                    if ($locRow && !empty($locRow['tiffin_charge']) && (float)$locRow['tiffin_charge'] > 0) {
                        return [
                            'tiffin_charge'       => (float)$locRow['tiffin_charge'],
                            'area_name'           => $locRow['location_name'],
                            'source'              => 'vendor_district',
                            'service_location_id' => (int)$locRow['id'],
                        ];
                    }
                }

                // Priority 2: Match vendor taluka (e.g. Haveli)
                if (!empty($vTaluka)) {
                    $talukaStmt = $pdo->prepare("
                        SELECT id, location_name, tiffin_charge
                        FROM service_locations
                        WHERE status = 'active'
                          AND (
                              LOWER(location_name) LIKE LOWER(?)
                              OR LOWER(address) LIKE LOWER(?)
                          )
                        ORDER BY id ASC
                        LIMIT 1
                    ");
                    $likeTaluka = '%' . $vTaluka . '%';
                    $talukaStmt->execute([$likeTaluka, $likeTaluka]);
                    $locRow = $talukaStmt->fetch(PDO::FETCH_ASSOC);
                    if ($locRow && !empty($locRow['tiffin_charge']) && (float)$locRow['tiffin_charge'] > 0) {
                        return [
                            'tiffin_charge'       => (float)$locRow['tiffin_charge'],
                            'area_name'           => $locRow['location_name'],
                            'source'              => 'vendor_taluka',
                            'service_location_id' => (int)$locRow['id'],
                        ];
                    }
                }

                // Priority 3: Match vendor state (e.g. Maharashtra)
                if (!empty($vState)) {
                    $stateStmt = $pdo->prepare("
                        SELECT id, location_name, tiffin_charge
                        FROM service_locations
                        WHERE status = 'active'
                          AND (
                              LOWER(address) LIKE LOWER(?)
                              OR LOWER(region) LIKE LOWER(?)
                          )
                        ORDER BY id ASC
                        LIMIT 1
                    ");
                    $likeState = '%' . $vState . '%';
                    $stateStmt->execute([$likeState, $likeState]);
                    $locRow = $stateStmt->fetch(PDO::FETCH_ASSOC);
                    if ($locRow && !empty($locRow['tiffin_charge']) && (float)$locRow['tiffin_charge'] > 0) {
                        return [
                            'tiffin_charge'       => (float)$locRow['tiffin_charge'],
                            'area_name'           => $locRow['location_name'],
                            'source'              => 'vendor_state',
                            'service_location_id' => (int)$locRow['id'],
                        ];
                    }
                }
            }
        } catch (Throwable $e) {
            error_log("Error in resolveVendorAreaTiffinCharge vendor check: " . $e->getMessage());
        }

        // 3. Fallback: First active service location in database
        try {
            $firstStmt = $pdo->query("SELECT id, location_name, tiffin_charge FROM service_locations WHERE status = 'active' ORDER BY id ASC LIMIT 1");
            $firstLoc = $firstStmt->fetch(PDO::FETCH_ASSOC);
            if ($firstLoc && !empty($firstLoc['tiffin_charge']) && (float)$firstLoc['tiffin_charge'] > 0) {
                return [
                    'tiffin_charge'       => (float)$firstLoc['tiffin_charge'],
                    'area_name'           => $firstLoc['location_name'],
                    'source'              => 'active_service_location',
                    'service_location_id' => (int)$firstLoc['id'],
                ];
            }
        } catch (Throwable $e) {}

        // 4. Default standard fallback
        return [
            'tiffin_charge' => $defaultCharge,
            'area_name'     => 'Standard Area',
            'source'        => 'default_fallback',
        ];
    }
    
    /**
     * Credits the dynamic Area Tiffin Charge to vendor wallet for a completed order.
     * Prevents duplicate crediting for the same order.
     * Returns the credited float amount on success, or 0.00 on failure.
     */
    public static function creditVendorWalletForOrder($pdo, int $orderId, ?float $amount = null): float {
        if ($orderId <= 0) return 0.00;

        try {
            // 1. Get vendor_id and order's tiffin_charge from order -> hotel -> vendor
            $stmt = $pdo->prepare("
                SELECT o.order_id, o.hotel_id, o.tiffin_charge, o.area_tiffin_charge, h.vendor_id 
                FROM orders o 
                JOIN hotels h ON o.hotel_id = h.id 
                WHERE o.order_id = ? 
                LIMIT 1
            ");
            $stmt->execute([$orderId]);
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            if (!$row || empty($row['vendor_id'])) return 0.00;

            $vendorId = (int)$row['vendor_id'];
            $hotelId  = (int)$row['hotel_id'];

            // 2. Resolve dynamic amount if not explicitly passed or if default 50.00 passed
            if ($amount === null || $amount <= 0) {
                if (!empty($row['tiffin_charge']) && (float)$row['tiffin_charge'] > 0) {
                    $amount = (float)$row['tiffin_charge'];
                } elseif (!empty($row['area_tiffin_charge']) && (float)$row['area_tiffin_charge'] > 0) {
                    $amount = (float)$row['area_tiffin_charge'];
                } else {
                    $resolved = self::resolveVendorAreaTiffinCharge($pdo, $vendorId, $hotelId);
                    $amount = (float)$resolved['tiffin_charge'];
                }
            } else {
                // If caller passed 50.00 as legacy default, check if order has a specific area tiffin charge
                if ($amount == 50.00) {
                    if (!empty($row['tiffin_charge']) && (float)$row['tiffin_charge'] > 0) {
                        $amount = (float)$row['tiffin_charge'];
                    } elseif (!empty($row['area_tiffin_charge']) && (float)$row['area_tiffin_charge'] > 0) {
                        $amount = (float)$row['area_tiffin_charge'];
                    } else {
                        $resolved = self::resolveVendorAreaTiffinCharge($pdo, $vendorId, $hotelId);
                        if (!empty($resolved['tiffin_charge']) && (float)$resolved['tiffin_charge'] > 0) {
                            $amount = (float)$resolved['tiffin_charge'];
                        }
                    }
                }
            }

            if ($amount <= 0) {
                $amount = 50.00; // Safeguard
            }

            // 3. Check if already credited for this order_id to avoid double crediting
            $checkTx = $pdo->prepare("
                SELECT id, amount 
                FROM vendor_wallet_transactions 
                WHERE order_id = ? AND type = 'CREDIT' AND vendor_id = ? 
                LIMIT 1
            ");
            $checkTx->execute([$orderId, $vendorId]);
            $existingTx = $checkTx->fetch(PDO::FETCH_ASSOC);
            if ($existingTx) {
                return (float)$existingTx['amount']; // Already credited
            }

            // 4. Ensure vendor_wallets row exists with lock
            $checkWallet = $pdo->prepare("SELECT id, balance FROM vendor_wallets WHERE vendor_id = ? FOR UPDATE");
            $checkWallet->execute([$vendorId]);
            $wallet = $checkWallet->fetch(PDO::FETCH_ASSOC);

            if (!$wallet) {
                $insWallet = $pdo->prepare("INSERT INTO vendor_wallets (vendor_id, balance) VALUES (?, 0.00)");
                $insWallet->execute([$vendorId]);
                $currentBalance = 0.00;
            } else {
                $currentBalance = (float)$wallet['balance'];
            }

            $newBalance = round($currentBalance + $amount, 2);

            // 5. Update balance
            $updWallet = $pdo->prepare("UPDATE vendor_wallets SET balance = ?, updated_at = NOW() WHERE vendor_id = ?");
            $updWallet->execute([$newBalance, $vendorId]);

            // 6. Insert transaction record
            $insTx = $pdo->prepare("
                INSERT INTO vendor_wallet_transactions 
                (vendor_id, order_id, type, amount, balance_after, description, created_at)
                VALUES (?, ?, 'CREDIT', ?, ?, ?, NOW())
            ");
            $formattedAmount = number_format($amount, 2, '.', '');
            $insTx->execute([
                $vendorId,
                $orderId,
                $amount,
                $newBalance,
                "Earning credit for completed Order #$orderId (₹$formattedAmount)"
            ]);

            return $amount;
        } catch (Throwable $e) {
            error_log("Error crediting vendor wallet for Order #$orderId: " . $e->getMessage());
            return 0.00;
        }
    }

    /**
     * Gets vendor wallet balance. Auto-creates wallet if not existing.
     * Includes dynamic area_tiffin_charge and area_name.
     */
    public static function getBalance(int $vendorId): array {
        $pdo = getDBConnection();
        $stmt = $pdo->prepare("SELECT id, vendor_id, balance FROM vendor_wallets WHERE vendor_id = ? LIMIT 1");
        $stmt->execute([$vendorId]);
        $wallet = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$wallet) {
            $ins = $pdo->prepare("INSERT INTO vendor_wallets (vendor_id, balance) VALUES (?, 0.00)");
            $ins->execute([$vendorId]);
            $id = (int)$pdo->lastInsertId();
            $wallet = [
                'id'        => $id,
                'vendor_id' => $vendorId,
                'balance'   => '0.00'
            ];
        }

        $todayStmt = $pdo->prepare("
            SELECT COALESCE(SUM(amount), 0) as today_earnings, COUNT(*) as today_orders_count 
            FROM vendor_wallet_transactions 
            WHERE vendor_id = ? AND type = 'CREDIT' AND DATE(created_at) = CURDATE()
        ");
        $todayStmt->execute([$vendorId]);
        $todayData = $todayStmt->fetch(PDO::FETCH_ASSOC);

        $dailyStmt = $pdo->prepare("
            SELECT DATE(created_at) as date, SUM(amount) as daily_total, COUNT(*) as orders_count
            FROM vendor_wallet_transactions
            WHERE vendor_id = ? AND type = 'CREDIT'
            GROUP BY DATE(created_at)
            ORDER BY date DESC
            LIMIT 7
        ");
        $dailyStmt->execute([$vendorId]);
        $dailyRows = $dailyStmt->fetchAll(PDO::FETCH_ASSOC);

        $dailyBreakdown = array_map(function($r) {
            return [
                'date'         => $r['date'],
                'daily_total'  => number_format((float)$r['daily_total'], 2, '.', ''),
                'orders_count' => (int)$r['orders_count'],
            ];
        }, $dailyRows);

        // Dynamic Area Tiffin Charge resolution
        $areaInfo = self::resolveVendorAreaTiffinCharge($pdo, $vendorId);
        $areaTiffinCharge = (float)$areaInfo['tiffin_charge'];

        return [
            'vendor_id'          => (int)$wallet['vendor_id'],
            'balance'            => number_format((float)$wallet['balance'], 2, '.', ''),
            'today_earnings'     => number_format((float)($todayData['today_earnings'] ?? 0), 2, '.', ''),
            'today_orders_count' => (int)($todayData['today_orders_count'] ?? 0),
            'area_tiffin_charge' => number_format($areaTiffinCharge, 2, '.', ''),
            'area_name'          => $areaInfo['area_name'] ?? 'Area',
            'daily_breakdown'    => $dailyBreakdown,
        ];
    }

    /**
     * Gets vendor transaction history.
     */
    public static function getTransactions(int $vendorId, int $page = 1, int $limit = 20): array {
        $pdo = getDBConnection();
        $offset = ($page - 1) * $limit;

        $countStmt = $pdo->prepare("SELECT COUNT(*) FROM vendor_wallet_transactions WHERE vendor_id = ?");
        $countStmt->execute([$vendorId]);
        $total = (int)$countStmt->fetchColumn();

        $stmt = $pdo->prepare("
            SELECT id, vendor_id, order_id, type, amount, balance_after, description, created_at
            FROM vendor_wallet_transactions
            WHERE vendor_id = ?
            ORDER BY id DESC
            LIMIT ? OFFSET ?
        ");
        $stmt->bindValue(1, $vendorId, PDO::PARAM_INT);
        $stmt->bindValue(2, $limit, PDO::PARAM_INT);
        $stmt->bindValue(3, $offset, PDO::PARAM_INT);
        $stmt->execute();
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $transactions = array_map(function($r) {
            return [
                'id'            => (int)$r['id'],
                'vendor_id'     => (int)$r['vendor_id'],
                'order_id'      => $r['order_id'] ? (int)$r['order_id'] : null,
                'type'          => $r['type'],
                'amount'        => (float)$r['amount'],
                'balance_after' => (float)$r['balance_after'],
                'description'   => $r['description'],
                'created_at'    => $r['created_at'],
            ];
        }, $rows);

        return [
            'transactions' => $transactions,
            'page'         => $page,
            'limit'        => $limit,
            'total'        => $total,
        ];
    }
}
