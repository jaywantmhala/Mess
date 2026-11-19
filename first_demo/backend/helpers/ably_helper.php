<?php
// backend/helpers/ably_helper.php

class AblyHelper {
    private static $primaryApiKey  = 'oSsZ2A.MVAVyA:EhxvHAEsSfx49DDHPqZ9_u3d7LzUETbyXpQl0sjW1Nk';
    private static $fallbackApiKey = 'oSsZ2A.RQCm6w:pKpGW30gh3lK2bg5OtmoXdWPhNY36H0d5oIHDj7mqmA';

    /**
     * Check if current environment is local / development.
     */
    public static function isLocal(): bool {
        $httpHost = $_SERVER['HTTP_HOST'] ?? '';
        if (strpos($httpHost, 'hungrilyfoods.com') !== false) {
            return false;
        }
        return true;
    }

    /**
     * Get environment channel prefix ('dev' or 'prod')
     */
    public static function getEnvPrefix(): string {
        return self::isLocal() ? 'dev' : 'prod';
    }

    /**
     * Get API key based on environment
     */
    public static function getApiKey(): string {
        return self::$primaryApiKey;
    }

    /**
     * Resolve environment-specific vendor channel name
     * Example: dev_vendor_5 or prod_vendor_5
     */
    public static function getVendorChannel($vendorId): string {
        $prefix = self::getEnvPrefix();
        return "{$prefix}_vendor_{$vendorId}";
    }

    /**
     * Resolve environment-specific driver channel name
     * Example: dev_driver_21 or prod_driver_21
     */
    public static function getDriverChannel($driverId): string {
        $prefix = self::getEnvPrefix();
        return "{$prefix}_driver_{$driverId}";
    }

    /**
     * Resolve environment-specific order/customer tracking channel name
     * Example: dev_order_450 or prod_order_450
     */
    public static function getOrderChannel($orderId): string {
        $prefix = self::getEnvPrefix();
        return "{$prefix}_order_{$orderId}";
    }

    /**
     * Resolve environment-specific hotel order channel name (legacy support)
     */
    public static function getHotelOrdersChannel($hotelId): string {
        $prefix = self::getEnvPrefix();
        return "{$prefix}_hotel_{$hotelId}_orders";
    }

    /**
     * Resolve environment-specific order chat channel name
     */
    public static function getOrderChatChannel($orderId): string {
        $prefix = self::getEnvPrefix();
        return "{$prefix}_order_{$orderId}_chat";
    }

    /**
     * Resolve default Ably channel name
     */
    public static function getDefaultChannel(): string {
        $prefix = self::getEnvPrefix();
        return "{$prefix}_global_events";
    }

    /**
     * Publish an event to Ably REST API with automatic key fallback
     * 
     * @param string $event Event name (e.g. new_order, order_assigned, order_updated)
     * @param array $data Event data payload
     * @param string|null $channel Target channel name
     * @return bool Success status
     */
    public static function publish($event, array $data, $channel = null) {
        ini_set('display_errors', '0');

        if (!$channel) {
            $hotelId = $data['hotel_id'] ?? null;
            if ($hotelId && $event !== 'ORDER_ASSIGNED' && $event !== 'order_assigned') {
                $channelName = self::getHotelOrdersChannel($hotelId);
            } else {
                $channelName = self::getDefaultChannel();
            }
        } else {
            $channelName = $channel;
        }

        $orderId = $data['order_id'] ?? ($data['id'] ?? 'unknown');
        $keysToTry = [self::$primaryApiKey, self::$fallbackApiKey];

        foreach ($keysToTry as $index => $apiKey) {
            if (empty($apiKey)) continue;

            $url = "https://rest.ably.io/channels/" . urlencode($channelName) . "/messages";

            $payload = json_encode([
                'name' => $event,
                'data' => [
                    'event' => $event,
                    'data'  => $data
                ]
            ]);

            $headers = [
                'Content-Type: application/json',
                'Authorization: Basic ' . base64_encode($apiKey)
            ];

            $ch = curl_init($url);
            curl_setopt($ch, CURLOPT_POST, true);
            curl_setopt($ch, CURLOPT_POSTFIELDS, $payload);
            curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_TIMEOUT, 5);
            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
            curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);

            $response = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            $error = curl_error($ch);

            if ($httpCode >= 200 && $httpCode < 300) {
                error_log("[ABLY] channel={$channelName} event={$event} order_id={$orderId} publish=success (key_index={$index})");
                return true;
            }

            error_log("[ABLY] Key index {$index} failed on channel={$channelName} Code: {$httpCode} Error: {$error} Response: {$response}");
        }

        error_log("[ABLY] All keys failed for channel={$channelName} event={$event} order_id={$orderId}");
        return false;
    }

    /**
     * Helper to publish vendor new order notification across vendor_{vendorId}, hotel_{hotelId}_orders, and global events channel
     */
    public static function publishVendorNewOrder($vendorId, array $data): bool {
        $success1 = self::publish('new_order', $data, self::getVendorChannel($vendorId));
        $success2 = self::publish('new_order', $data, "vendor_{$vendorId}");
        self::publish('NEW_ORDER', $data, self::getVendorChannel($vendorId));
        self::publish('NEW_ORDER', $data, "vendor_{$vendorId}");
        if (isset($data['hotel_id'])) {
            self::publish('NEW_ORDER', $data, self::getHotelOrdersChannel($data['hotel_id']));
            self::publish('new_order', $data, self::getHotelOrdersChannel($data['hotel_id']));
        }
        self::publish('NEW_ORDER', $data, self::getDefaultChannel());
        self::publish('new_order', $data, self::getDefaultChannel());
        return $success1 || $success2;
    }

    /**
     * Helper to publish driver assignment notification across driver_{driverId} and global events channel
     */
    public static function publishDriverAssignment($driverId, array $data): bool {
        $success1 = self::publish('order_assigned', $data, self::getDriverChannel($driverId));
        $success2 = self::publish('order_assigned', $data, "driver_{$driverId}");
        self::publish('ORDER_ASSIGNED', $data, self::getDriverChannel($driverId));
        self::publish('ORDER_ASSIGNED', $data, "driver_{$driverId}");
        self::publish('ORDER_ASSIGNED', $data, self::getDefaultChannel());
        self::publish('order_assigned', $data, self::getDefaultChannel());
        return $success1 || $success2;
    }

    /**
     * Helper to publish order status updates to order_{orderId}, hotel, and global channel
     */
    public static function publishOrderUpdate($orderId, array $data): bool {
        $success1 = self::publish('order_updated', $data, self::getOrderChannel($orderId));
        $success2 = self::publish('order_updated', $data, "order_{$orderId}");
        self::publish('ORDER_STATUS_UPDATED', $data, self::getOrderChannel($orderId));
        self::publish('ORDER_STATUS_UPDATED', $data, "order_{$orderId}");
        if (isset($data['hotel_id'])) {
            self::publish('ORDER_STATUS_UPDATED', $data, self::getHotelOrdersChannel($data['hotel_id']));
            self::publish('order_updated', $data, self::getHotelOrdersChannel($data['hotel_id']));
        }
        self::publish('ORDER_STATUS_UPDATED', $data, self::getDefaultChannel());
        self::publish('order_updated', $data, self::getDefaultChannel());
        return $success1 || $success2;
    }
}

