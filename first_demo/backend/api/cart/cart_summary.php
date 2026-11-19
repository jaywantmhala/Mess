<?php
/**
 * cart_summary.php — Shared helper: returns cart summary array for a customer.
 * Included by add.php, list.php, update.php — NOT a standalone endpoint.
 */

require_once __DIR__ . '/../../helpers/tiffin_charge_helper.php';

if (!function_exists('getCartSummary')) {
    function getCartSummary(PDO $pdo, int $customerId): array
    {
        $stmt = $pdo->prepare(
            "SELECT
                ci.cart_item_id,
                ci.menu_item_id,
                m.food_name AS name,
                m.price,
                ci.quantity,
                (m.price * ci.quantity) AS subtotal,
                m.image_url,
                m.food_type,
                ci.hotel_id,
                ci.customizations,
                h.hotel_name AS hotel_name
             FROM cart_items ci
             JOIN menus  m ON m.id = ci.menu_item_id
             JOIN hotels h ON h.id = ci.hotel_id
             WHERE ci.customer_id = ?
             ORDER BY ci.cart_item_id ASC"
        );
        $stmt->execute([$customerId]);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        if (empty($rows)) {
            $areaInfo = resolveAreaTiffinCharge($pdo, $customerId);
            return [
                'items'          => [],
                'hotel'          => null,
                'total_quantity' => 0,
                'subtotal'       => '0.00',
                'delivery_fee'   => '0.00',
                'tax_amount'     => '0.00',
                'grand_total'    => '0.00',
                'tiffin_charge'          => number_format((float)($areaInfo['tiffin_charge'] > 0 ? $areaInfo['tiffin_charge'] : 50.0), 2, '.', ''),
                'original_tiffin_charge' => number_format((float)($areaInfo['original_tiffin_charge'] ?? 0.0), 2, '.', ''),
                'discount_percentage'    => (float)($areaInfo['discount_percentage'] ?? 0.0),
                'has_discount'           => !empty($areaInfo['has_discount']),
                'area_name'              => $areaInfo['area_name'],
            ];
        }

        $items         = [];
        $subtotal      = 0.0;
        $totalQuantity = 0;
        $hotelId       = (int) $rows[0]['hotel_id'];
        $hotelName     = $rows[0]['hotel_name'];

        foreach ($rows as $row) {
            $itemSubtotal  = (float) $row['price'] * (int) $row['quantity'];
            $subtotal     += $itemSubtotal;
            $totalQuantity += (int) $row['quantity'];

            $customizations = null;
            if (!empty($row['customizations'])) {
                $decoded = json_decode($row['customizations'], true);
                $customizations = is_array($decoded) ? $decoded : [$row['customizations']];
            }

            $items[] = [
                'cart_item_id'   => (int)    $row['cart_item_id'],
                'menu_item_id'   => (int)    $row['menu_item_id'],
                'name'           =>          $row['name'],
                'price'          => number_format((float) $row['price'], 2, '.', ''),
                'quantity'       => (int)    $row['quantity'],
                'subtotal'       => number_format($itemSubtotal, 2, '.', ''),
                'image_url'      =>          $row['image_url'],
                'food_type'      =>          $row['food_type'],
                'customizations' =>          $customizations,
            ];
        }

        $areaInfo = resolveAreaTiffinCharge($pdo, $customerId, $hotelId);
        $tiffinCharge = (float)$areaInfo['tiffin_charge'];
        if ($tiffinCharge <= 0) {
            $tiffinCharge = 50.00;
        }
        $areaName = $areaInfo['area_name'];

        $deliveryFee = 0.00;
        $taxAmount   = 0.00;
        $grandTotal  = $subtotal + $deliveryFee + $taxAmount + $tiffinCharge;

        return [
            'items'          => $items,
            'hotel'          => ['id' => $hotelId, 'name' => $hotelName],
            'total_quantity' => $totalQuantity,
            'subtotal'       => number_format($subtotal,     2, '.', ''),
            'delivery_fee'   => number_format($deliveryFee,  2, '.', ''),
            'tax_amount'     => number_format($taxAmount,    2, '.', ''),
            'grand_total'    => number_format($grandTotal,   2, '.', ''),
            'tiffin_charge'          => number_format($tiffinCharge, 2, '.', ''),
            'original_tiffin_charge' => number_format((float)($areaInfo['original_tiffin_charge'] ?? 0.0), 2, '.', ''),
            'discount_percentage'    => (float)($areaInfo['discount_percentage'] ?? 0.0),
            'has_discount'           => !empty($areaInfo['has_discount']),
            'area_name'              => $areaName,
        ];
    }
}
