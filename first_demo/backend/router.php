<?php
require_once __DIR__ . '/helpers/cors.php';

$uri    = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
if (strpos($uri, '/backend') === 0) {
    $uri = substr($uri, 8);
}
$uri    = rtrim($uri, '/');
$method = $_SERVER['REQUEST_METHOD'];

// ── Helper to serve static files with proper Mime Type ─────────────────
if (!function_exists('serveStaticFile')) {
    function serveStaticFile($filePath) {
        if (file_exists($filePath) && !is_dir($filePath)) {
            $mime_types = [
                'html'  => 'text/html; charset=utf-8',
                'htm'   => 'text/html; charset=utf-8',
                'css'   => 'text/css',
                'js'    => 'application/javascript',
                'json'  => 'application/json',
                'png'   => 'image/png',
                'jpg'   => 'image/jpeg',
                'jpeg'  => 'image/jpeg',
                'gif'   => 'image/gif',
                'ico'   => 'image/x-icon',
                'svg'   => 'image/svg+xml',
                'webp'  => 'image/webp',
                'mp4'   => 'video/mp4',
                'webm'  => 'video/webm',
                'woff'  => 'font/woff',
                'woff2' => 'font/woff2',
                'ttf'   => 'font/ttf',
                'eot'   => 'application/vnd.ms-fontobject',
            ];
            $ext = strtolower(pathinfo($filePath, PATHINFO_EXTENSION));
            $contentType = isset($mime_types[$ext]) ? $mime_types[$ext] : 'application/octet-stream';

            // Support Range Requests for Video Streaming (Required for MP4 in Safari/Chrome)
            if ($ext === 'mp4' || $ext === 'webm') {
                $fileSize = filesize($filePath);
                $fp = @fopen($filePath, 'rb');
                if (!$fp) {
                    header("HTTP/1.1 500 Internal Server Error");
                    exit;
                }

                $start = 0;
                $end = $fileSize - 1;

                if (isset($_SERVER['HTTP_RANGE'])) {
                    if (preg_match('/bytes=\h*(\d+)-(\d*)[\D.*]?/i', $_SERVER['HTTP_RANGE'], $matches)) {
                        $start = intval($matches[1]);
                        if (!empty($matches[2])) {
                            $end = intval($matches[2]);
                        }
                    }
                    header('HTTP/1.1 206 Partial Content');
                    header("Content-Range: bytes $start-$end/$fileSize");
                }

                header("Content-Type: $contentType");
                header('Accept-Ranges: bytes');
                header('Content-Length: ' . ($end - $start + 1));
                header("Cache-Control: public, max-age=86400");

                fseek($fp, $start);
                $bufferSize = 1024 * 64; // 64KB chunks
                while (!feof($fp) && ($pos = ftell($fp)) <= $end) {
                    if ($pos + $bufferSize > $end) {
                        $bufferSize = $end - $pos + 1;
                    }
                    echo fread($fp, $bufferSize);
                    flush();
                }
                fclose($fp);
                exit;
            }

            header("Content-Type: $contentType");
            header("Cache-Control: no-cache, no-store, must-revalidate");
            header("Pragma: no-cache");
            header("Expires: 0");
            readfile($filePath);
            exit;
        }
    }
}

// ── Serve admin static files if requested ──────────────────────────────
if (strpos($uri, '/admin/') === 0) {
    serveStaticFile(__DIR__ . $uri);
}

// ── Serve website static files if requested ────────────────────────────
if (strpos($uri, '/website/') === 0) {
    serveStaticFile(__DIR__ . $uri);
}

// ── Route non-API page requests ───────────────────────────────────────
if (strpos($uri, '/api') !== 0) {
    // Route to Admin Panel SPA if URI is /admin, /admin/*, or /admin/index.php
if (strpos($uri, '/uploads/') === 0) {
    serveStaticFile(__DIR__ . $uri);
}

    $adminSpaRoutes = ['/admin', '/dashboard', '/vendors', '/payouts', '/revenue', '/users', '/drivers', '/delivery-tracking', '/areas', '/subscriptions', '/notifications', '/whatsapp', '/profile', '/enquiries'];
    if ($uri === '/admin' || strpos($uri, '/admin/') === 0 || $uri === '/admin/index.php' || in_array($uri, $adminSpaRoutes)) {
        $adminIndex = __DIR__ . '/admin/index.php';
        if (file_exists($adminIndex)) {
            require_once $adminIndex;
            exit;
        }
    }

    // Check direct website file or HTML page (e.g., /styles.css, /partner.html, /dineout.html)
    if ($uri !== '' && $uri !== '/') {
        $webFile = __DIR__ . '/website' . $uri;
        if (file_exists($webFile) && !is_dir($webFile)) {
            serveStaticFile($webFile);
        }
        $webHtmlFile = __DIR__ . '/website' . $uri . '.html';
        if (file_exists($webHtmlFile) && !is_dir($webHtmlFile)) {
            serveStaticFile($webHtmlFile);
        }
    }

    // Route all other page requests (Home, /, /index.html, /index.php) to Website Frontend
    $websiteIndexHtml = __DIR__ . '/website/index.html';
    $websiteIndexPhp  = __DIR__ . '/website/index.php';
    if (file_exists($websiteIndexHtml)) {
        serveStaticFile($websiteIndexHtml);
    } elseif (file_exists($websiteIndexPhp)) {
        require_once $websiteIndexPhp;
        exit;
    }
}

$routes = [
    // ── Auth ──────────────────────────────────────────────────────────────
    'POST /api/auth/signup'                       => __DIR__ . '/api/auth/signup.php',
    'POST /api/auth/register'                     => __DIR__ . '/api/auth/signup.php',
    'POST /api/auth/login'                        => __DIR__ . '/api/auth/login.php',
    'POST /api/auth/refresh'                      => __DIR__ . '/api/auth/refresh.php',
    'GET  /api/auth/me'                           => __DIR__ . '/api/auth/me.php',
    'GET  /api/migrate'                           => __DIR__ . '/api/migrate.php',
    'POST /api/migrate'                          => __DIR__ . '/api/migrate.php',
    'GET  /api/migrate.php'                       => __DIR__ . '/api/migrate.php',
    'POST /api/migrate.php'                      => __DIR__ . '/api/migrate.php',
    'GET  /api/admin/migrate'                    => __DIR__ . '/api/migrate.php',
    'POST /api/admin/migrate'                   => __DIR__ . '/api/migrate.php',
    'GET  /api/admin/migrate.php'                => __DIR__ . '/api/migrate.php',
    'POST /api/admin/migrate.php'               => __DIR__ . '/api/migrate.php',
    'POST /api/auth/logout'                       => __DIR__ . '/api/auth/logout.php',
    'GET  /api/auth/address'                      => __DIR__ . '/api/auth/address.php',
    'POST /api/auth/address'                      => __DIR__ . '/api/auth/address.php',
    'POST /api/auth/address/delete'               => __DIR__ . '/api/auth/address.php',
    'POST /api/auth/address/select'               => __DIR__ . '/api/auth/address.php',
    'POST /api/auth/update_fcm_token'             => __DIR__ . '/api/auth/update_fcm_token.php',
    'POST /api/auth/forgot-password/check-email' => __DIR__ . '/api/auth/forgot_password_check_email.php',
    'POST /api/auth/forgot-password/send-otp'    => __DIR__ . '/api/auth/forgot_password_send_otp.php',
    'POST /api/auth/forgot-password/verify-otp'  => __DIR__ . '/api/auth/forgot_password_verify_otp.php',
    'POST /api/auth/forgot-password/reset'       => __DIR__ . '/api/auth/forgot_password_reset.php',
    'POST /api/auth/delete_account'               => __DIR__ . '/api/auth/delete_account.php',
    'POST /api/auth/delete-account'               => __DIR__ . '/api/auth/delete_account.php',
    'POST /api/auth/send-otp'                     => __DIR__ . '/api/auth/send_otp_whatsapp.php',
    'POST /api/auth/verify-otp'                   => __DIR__ . '/api/auth/verify_otp_whatsapp.php',

    // ── Admin ─────────────────────────────────────────────────────────────
    'POST /api/admin/signup'             => __DIR__ . '/api/admin/signup.php',
    'POST /api/admin/login'              => __DIR__ . '/api/admin/login.php',
    'GET  /api/admin/me'                 => __DIR__ . '/api/admin/me.php',
    'GET  /api/admin/dashboard/summary'  => __DIR__ . '/api/admin/dashboard/summary.php',
    'GET  /api/admin/vendors'            => __DIR__ . '/api/admin/vendors/list.php',
    'GET  /api/admin/vendors/details'    => __DIR__ . '/api/admin/vendors/details.php',
    'POST /api/admin/vendors/add'        => __DIR__ . '/api/admin/vendors/add.php',
    'POST /api/admin/vendors/edit'       => __DIR__ . '/api/admin/vendors/edit.php',
    'POST /api/admin/vendors/status'     => __DIR__ . '/api/admin/vendors/status.php',
    'POST /api/admin/vendors/delete'     => __DIR__ . '/api/admin/vendors/delete.php',
    'GET  /api/admin/payouts'                       => __DIR__ . '/api/admin/payouts/list.php',
    'GET  /api/admin/payouts/razorpay-contacts'     => __DIR__ . '/api/admin/payouts/razorpay_contacts.php',
    'GET  /api/admin/payouts/razorpay-fund-account' => __DIR__ . '/api/admin/payouts/razorpay_fund_account.php',
    'POST /api/admin/payouts/sync-vendors'          => __DIR__ . '/api/admin/payouts/sync_vendors.php',
    'GET  /api/admin/payouts/banking-balances'      => __DIR__ . '/api/admin/payouts/banking_balances.php',
    'GET  /api/admin/payouts/settings'              => __DIR__ . '/api/admin/payouts/settings.php',
    'POST /api/admin/payouts/settings'             => __DIR__ . '/api/admin/payouts/settings.php',
    'POST /api/admin/payouts/trigger-now'          => __DIR__ . '/api/admin/payouts/trigger_now.php',
    'GET  /api/admin/payouts/dashboard'            => __DIR__ . '/api/admin/payouts/dashboard.php',
    'GET  /api/admin/payouts/records'              => __DIR__ . '/api/admin/payouts/records.php',
    'GET  /api/admin/payouts/record-details'       => __DIR__ . '/api/admin/payouts/record_details.php',
    'POST /api/admin/payouts/reconcile'            => __DIR__ . '/api/admin/payouts/reconcile.php',
    'GET  /api/admin/payouts/runs'                 => __DIR__ . '/api/admin/payouts/runs.php',
    'POST /api/admin/payouts/add-earning'          => __DIR__ . '/api/admin/payouts/add_earning.php',
    'GET  /api/cron/payout-dispatcher'             => __DIR__ . '/cron/payout_dispatcher.php',
    'GET  /api/admin/users'              => __DIR__ . '/api/admin/users/list.php',
    'GET  /api/admin/users/details'      => __DIR__ . '/api/admin/users/details.php',
    'POST /api/admin/users/add'          => __DIR__ . '/api/admin/users/add.php',
    'POST /api/admin/users/edit'         => __DIR__ . '/api/admin/users/edit.php',
    'POST /api/admin/users/status'       => __DIR__ . '/api/admin/users/status.php',
    'POST /api/admin/users/delete'       => __DIR__ . '/api/admin/users/delete.php',

    // ── Admin Locations & Subscription Plans Management (legacy) ─────────
    'GET  /api/admin/locations'          => __DIR__ . '/api/admin/locations/list.php',
    'POST /api/admin/locations/save'     => __DIR__ . '/api/admin/locations/save.php',
    'POST /api/admin/locations/status'   => __DIR__ . '/api/admin/locations/status.php',
    'POST /api/admin/locations/delete'   => __DIR__ . '/api/admin/locations/delete.php',
    'POST /api/admin/locations/geocode'  => __DIR__ . '/api/admin/locations/geocode.php',

    // ── Admin Service Locations (new flat model with per-location radius) ──
    'GET  /api/admin/service-locations'                => __DIR__ . '/api/admin/service_locations/list.php',
    'POST /api/admin/service-locations/save'           => __DIR__ . '/api/admin/service_locations/save.php',
    'POST /api/admin/service-locations/delete'         => __DIR__ . '/api/admin/service_locations/delete.php',
    'POST /api/admin/service-locations/replicate-plan' => __DIR__ . '/api/admin/service_locations/replicate_plan.php',

    // ── Admin Push Notifications ──────────────────────────────────────────
    'POST /api/admin/notifications/send'         => __DIR__ . '/api/admin/notifications/send.php',
    'POST /api/admin/notifications/upload_image' => __DIR__ . '/api/admin/notifications/upload_image.php',
    'POST /api/admin/notifications/upload-image' => __DIR__ . '/api/admin/notifications/upload_image.php',
    'GET  /api/admin/notifications/targets'    => __DIR__ . '/api/admin/notifications/targets.php',
    'POST /api/admin/notifications/targets'   => __DIR__ . '/api/admin/notifications/targets.php',
    'GET  /api/admin/notifications/history'    => __DIR__ . '/api/admin/notifications/history.php',

    // ── Admin WhatsApp Broadcast ──────────────────────────────────────────
    'POST /api/admin/whatsapp/send'            => __DIR__ . '/api/admin/whatsapp/send.php',
    'GET  /api/admin/whatsapp/targets'         => __DIR__ . '/api/admin/whatsapp/targets.php',
    'POST /api/admin/whatsapp/targets'        => __DIR__ . '/api/admin/whatsapp/targets.php',
    'GET  /api/admin/whatsapp/history'         => __DIR__ . '/api/admin/whatsapp/history.php',

    // ── Admin Drivers & Revenue ───────────────────────────────────────────
    'GET  /api/admin/drivers'                  => __DIR__ . '/api/admin/drivers/list.php',
    'GET  /api/admin/drivers/details'          => __DIR__ . '/api/admin/drivers/details.php',
    'POST /api/admin/drivers/edit'             => __DIR__ . '/api/admin/drivers/edit.php',
    'GET  /api/admin/revenue/list'             => __DIR__ . '/api/admin/revenue/list.php',
    'GET  /api/admin/delivery_tracking/list.php' => __DIR__ . '/api/admin/delivery_tracking/list.php',
    'GET  /api/admin/delivery-tracking'           => __DIR__ . '/api/admin/delivery_tracking/list.php',

    // ── Vendor ────────────────────────────────────────────────────────────
    'POST /api/vendor/signup'                         => __DIR__ . '/api/vendor/signup.php',
    'POST /api/vendor/login'                          => __DIR__ . '/api/vendor/login.php',
    'POST /api/vendor/send-otp'                       => __DIR__ . '/api/auth/send_otp_whatsapp.php',
    'POST /api/vendor/verify-otp'                     => __DIR__ . '/api/auth/verify_otp_whatsapp.php',
    'POST /api/vendor/refresh'                        => __DIR__ . '/api/auth/refresh.php',
    'POST /api/vendor/update_profile'                 => __DIR__ . '/api/vendor/update_profile.php',
    'POST /api/vendor/forgot-password/check-email'     => __DIR__ . '/api/vendor/forgot_password_check_email.php',
    'POST /api/vendor/forgot-password/send-otp'        => __DIR__ . '/api/vendor/forgot_password_send_otp.php',
    'POST /api/vendor/forgot-password/verify-otp'      => __DIR__ . '/api/vendor/forgot_password_verify_otp.php',
    'POST /api/vendor/forgot-password/reset'           => __DIR__ . '/api/vendor/forgot_password_reset.php',
    'POST /api/vendor/add_hotel'          => __DIR__ . '/api/vendor/add_hotel.php',
    'GET  /api/vendor/get_bank_details'   => __DIR__ . '/api/vendor/get_bank_details.php',
    'POST /api/vendor/update_bank_details'=> __DIR__ . '/api/vendor/update_bank_details.php',
    'GET  /api/vendor/hotels'             => __DIR__ . '/api/vendor/hotels.php',
    'POST /api/vendor/edit_hotel'         => __DIR__ . '/api/vendor/edit_hotel.php',
    'POST /api/vendor/delete_hotel'       => __DIR__ . '/api/vendor/delete_hotel.php',
    'POST /api/vendor/menu/add'           => __DIR__ . '/api/vendor/menu/add.php',
    'GET  /api/vendor/menu/list'          => __DIR__ . '/api/vendor/menu/list.php',
    'POST /api/vendor/menu/edit'          => __DIR__ . '/api/vendor/menu/edit.php',
    'POST /api/vendor/menu/delete'        => __DIR__ . '/api/vendor/menu/delete.php',
    'GET  /api/vendor/orders'             => __DIR__ . '/api/vendor/orders/list.php',
    'POST /api/vendor/orders/status'      => __DIR__ . '/api/vendor/orders/status.php',
    'GET  /api/vendor/drivers/online'     => __DIR__ . '/api/vendor/drivers/online.php',
    'GET  /api/vendor/drivers/list'       => __DIR__ . '/api/vendor/drivers/list.php',
    'POST /api/vendor/drivers/add'        => __DIR__ . '/api/vendor/drivers/add.php',
    'POST /api/vendor/drivers/whatsapp'   => __DIR__ . '/api/vendor/drivers/whatsapp.php',
    'POST /api/vendor/orders/assign'      => __DIR__ . '/api/vendor/orders/assign.php',
    'POST /api/vendor/update_fcm_token'   => __DIR__ . '/api/vendor/update_fcm_token.php',
    'POST /api/vendor/status'             => __DIR__ . '/api/vendor/status.php',
    'GET  /api/vendor/wallet/balance'     => __DIR__ . '/api/vendor/wallet/balance.php',
    'GET  /api/vendor/wallet/transactions'=> __DIR__ . '/api/vendor/wallet/transactions.php',
    'GET  /api/vendor/payouts'            => __DIR__ . '/api/vendor/payouts.php',
    'GET  /api/vendor/notifications'           => __DIR__ . '/api/vendor/notifications.php',
    'POST /api/vendor/notifications/mark-read' => __DIR__ . '/api/vendor/notifications_mark_read.php',
    'POST /api/admin/cron/vendor-payouts' => __DIR__ . '/api/admin/cron/vendor_payouts.php',
    'POST /api/payu/payout/webhook'       => __DIR__ . '/api/payu/payout_webhook.php',

    // ── Driver ────────────────────────────────────────────────────────────
    'POST /api/driver/signup'              => __DIR__ . '/api/driver/signup.php',
    'POST /api/driver/login'               => __DIR__ . '/api/driver/login.php',
    'POST /api/driver/refresh'             => __DIR__ . '/api/auth/refresh.php',
    'GET  /api/driver/me'                  => __DIR__ . '/api/driver/me.php',
    'POST /api/driver/status'              => __DIR__ . '/api/driver/status.php',
    'GET  /api/driver/orders'              => __DIR__ . '/api/driver/orders/list.php',
    'POST /api/driver/orders/status'       => __DIR__ . '/api/driver/orders/status.php',
    'POST /api/driver/orders/tiffin_verify'=> __DIR__ . '/api/driver/orders/tiffin_verify.php',
    'GET  /api/driver/orders/pending_tiffin'=> __DIR__ . '/api/driver/orders/pending_tiffin.php',
    'POST /api/driver/location'            => __DIR__ . '/api/driver/location.php',
    'POST /api/driver/update_fcm_token'    => __DIR__ . '/api/driver/update_fcm_token.php',

    // ── Hotels (public) ───────────────────────────────────────────────────
    'GET  /api/hotels/nearby' => __DIR__ . '/api/hotels/nearby.php',
    'GET  /api/hotels/menu'   => __DIR__ . '/api/hotels/menu.php',

    // ── Wallet ────────────────────────────────────────────────────────────
    'GET  /api/wallet/balance'      => __DIR__ . '/api/wallet/balance.php',
    'POST /api/wallet/recharge'     => __DIR__ . '/api/wallet/recharge.php',
    'GET  /api/wallet/transactions' => __DIR__ . '/api/wallet/transactions.php',

    // ── Cart ──────────────────────────────────────────────────────────────
    'POST /api/cart/add'    => __DIR__ . '/api/cart/add.php',
    'GET  /api/cart/list'   => __DIR__ . '/api/cart/list.php',
    'POST /api/cart/update' => __DIR__ . '/api/cart/update.php',
    'POST /api/cart/clear'  => __DIR__ . '/api/cart/clear.php',

    // ── Orders ────────────────────────────────────────────────────────────
    'POST /api/orders/place'   => __DIR__ . '/api/orders/place.php',
    'GET  /api/orders/history' => __DIR__ . '/api/orders/history.php',
    'GET  /api/orders/details' => __DIR__ . '/api/orders/details.php',

    // ── Order Chat ────────────────────────────────────────────────────────
    'GET  /api/orders/chat/messages'  => __DIR__ . '/api/orders/chat/messages.php',
    'POST /api/orders/chat/send'      => __DIR__ . '/api/orders/chat/send.php',
    'POST /api/orders/chat/mark_read' => __DIR__ . '/api/orders/chat/mark_read.php',

    // ── Customer Status / Presence ────────────────────────────────────────
    'POST /api/customer/status'                  => __DIR__ . '/api/customer/status.php',
    'POST /api/auth/status'                      => __DIR__ . '/api/customer/status.php',

    // ── Customer Plans Resolver & Subscription Purchase ───────────────────
    'POST /api/customer/serviceable-plans'       => __DIR__ . '/api/customer/serviceable_plans.php',
    'POST /api/customer/serviceable-plans-v2'    => __DIR__ . '/api/customer/serviceable_plans_v2.php',
    'POST /api/customer/subscribe'               => __DIR__ . '/api/customer/subscribe.php',
    'POST /api/customer/upi_pay'                 => __DIR__ . '/api/customer/upi_pay.php',
    'POST /api/customer/cashfree/create_order'   => __DIR__ . '/api/customer/cashfree_create_order.php',
    'POST /api/customer/cashfree/verify_payment' => __DIR__ . '/api/customer/cashfree_verify_payment.php',
    'POST /api/customer/payu/create_order'       => __DIR__ . '/api/customer/payu_create_order.php',
    'POST /api/customer/payu/verify_payment'     => __DIR__ . '/api/customer/payu_verify_payment.php',
    'POST /api/customer/payu/success'            => __DIR__ . '/api/customer/payu_success.php',
    'GET  /api/customer/payu/success'            => __DIR__ . '/api/customer/payu_success.php',
    'POST /api/customer/payu/failure'            => __DIR__ . '/api/customer/payu_failure.php',
    'GET  /api/customer/payu/failure'            => __DIR__ . '/api/customer/payu_failure.php',
    'POST /api/customer/razorpay/create_order'   => __DIR__ . '/api/customer/payu_create_order.php',
    'POST /api/customer/razorpay/verify_payment' => __DIR__ . '/api/customer/payu_verify_payment.php',

    // ── Customer Subscriptions ───────────────────────────────────────────
    'GET  /api/customer/subscription/current' => __DIR__ . '/api/customer/subscription/current.php',
    'POST /api/customer/subscription/pause'   => __DIR__ . '/api/customer/subscription/pause.php',
    'POST /api/customer/subscription/resume'  => __DIR__ . '/api/customer/subscription/resume.php',
    'POST /api/customer/subscription/renew'   => __DIR__ . '/api/customer/subscription/renew.php',
    'GET  /api/customer/subscription/history' => __DIR__ . '/api/customer/subscription/history.php',
    'GET  /api/customer/notifications'           => __DIR__ . '/api/customer/notifications.php',
    'POST /api/customer/notifications/mark-read' => __DIR__ . '/api/customer/notifications_mark_read.php',

    // ── Admin Subscriptions ──────────────────────────────────────────────
    'GET  /api/admin/subscriptions/list'      => __DIR__ . '/api/admin/subscriptions/list.php',
    'POST /api/admin/subscriptions/action'    => __DIR__ . '/api/admin/subscriptions/action.php',
    'POST /api/admin/subscriptions/assign'    => __DIR__ . '/api/admin/subscriptions/assign.php',
    'GET  /api/admin/users/addresses'         => __DIR__ . '/api/admin/users/addresses.php',

    // ── Cron Job ──────────────────────────────────────────────────────────
    'GET  /api/cron/verify_subscriptions'     => __DIR__ . '/cron/verify_subscriptions.php',
    'GET  /api/cron/process_daily_payouts'    => __DIR__ . '/cron/process_daily_payouts.php',

    // ── Public Platform Stats ─────────────────────────────────────────────
    'GET  /api/public/stats'                  => __DIR__ . '/api/public/stats.php',
    'GET  /api/stats'                         => __DIR__ . '/api/public/stats.php',

    // ── Website Enquiries ──────────────────────────────────────────────────
    'POST /api/enquiries/submit'              => __DIR__ . '/api/public/enquiry_submit.php',
    'POST /api/enquiries'                     => __DIR__ . '/api/public/enquiry_submit.php',
    'GET  /api/admin/enquiries/list'          => __DIR__ . '/api/admin/enquiries/list.php',
    'GET  /api/admin/enquiries'               => __DIR__ . '/api/admin/enquiries/list.php',
    'POST /api/admin/enquiries/status'        => __DIR__ . '/api/admin/enquiries/status.php',
    'POST /api/admin/enquiries/delete'        => __DIR__ . '/api/admin/enquiries/delete.php',
];

foreach ($routes as $pattern => $file) {
    [$routeMethod, $routePath] = explode(' ', $pattern, 2);
    if (trim($routeMethod) === $method && trim($routePath) === $uri) {
        if (file_exists($file)) {
            require $file;
            exit;
        }
        http_response_code(500);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode(['success' => false, 'message' => "Handler file not found: $file"]);
        exit;
    }
}

// ── Root health-check ──────────────────────────────────────────────────────
if ($uri === '' || $uri === '/') {
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode(
        [
            'success' => true,
            'service' => 'first_demo PHP REST API',
            'version' => '2.0.0',
            'status'  => 'running',
        ],
        JSON_PRETTY_PRINT
    );
    exit;
}

// ── 404 ────────────────────────────────────────────────────────────────────
http_response_code(404);
header('Content-Type: application/json; charset=utf-8');
echo json_encode(
    [
        'success'          => false,
        'message'          => "Route not found: $method $uri",
        'available_routes' => array_keys($routes),
    ],
    JSON_PRETTY_PRINT
);
