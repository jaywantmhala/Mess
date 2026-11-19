<?php
/**
 * POST /api/auth/verify-otp
 *
 * Verify 6-digit WhatsApp OTP for customer or vendor.
 * Body: { phone: "9876543210", otp: "123456", role: "customer", full_name: "Optional Name", email: "optional@email.com" }
 */

require_once __DIR__ . '/../../helpers/cors.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/razorpay.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/validation.php';
require_once __DIR__ . '/../../helpers/jwt.php';

header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendError('Method not allowed. Use POST.', 405);
}

$rawBody = file_get_contents('php://input');
$body = json_decode($rawBody, true) ?? [];

$phone    = preg_replace('/[^0-9]/', '', trim($body['phone'] ?? ''));
$otp      = trim($body['otp'] ?? '');
$role     = strtolower(trim($body['role'] ?? 'customer'));
$fullName = trim($body['full_name'] ?? '');
$email    = strtolower(trim($body['email'] ?? ''));
$fcmToken = trim($body['fcm_token'] ?? '');

if (strlen($phone) > 10) {
    $phone = substr($phone, -10);
}

if (strlen($phone) < 10) {
    sendError('Please enter a valid 10-digit mobile number.', 422);
}
if (empty($otp)) {
    sendError('OTP code is required.', 422);
}

try {
    $pdo = getDBConnection();

    // Verify OTP in database
    $stmt = $pdo->prepare("
        SELECT id FROM otp_verifications
        WHERE phone = :phone AND otp = :otp AND role = :role AND expires_at > NOW()
        ORDER BY id DESC LIMIT 1
    ");
    $stmt->execute([':phone' => $phone, ':otp' => $otp, ':role' => $role]);
    $otpRecord = $stmt->fetch();

    if (!$otpRecord) {
        sendError('Invalid or expired OTP. Please try again.', 400);
    }

    if ($role === 'vendor') {
        // Check vendor account
        $stmtV = $pdo->prepare("
            SELECT id, full_name, email, phone, country, state, district, taluka, is_active, created_at
            FROM vendors WHERE phone = :phone OR phone LIKE :phone_like LIMIT 1
        ");
        $stmtV->execute([':phone' => $phone, ':phone_like' => '%' . $phone]);
        $vendor = $stmtV->fetch();

        if ($vendor) {
            // Delete verified OTP so it cannot be reused
            $del = $pdo->prepare("DELETE FROM otp_verifications WHERE phone = :phone AND role = :role");
            $del->execute([':phone' => $phone, ':role' => $role]);

            if (!(bool)$vendor['is_active']) {
                sendError('Your vendor account has been deactivated. Please contact support.', 403);
            }

            if (!empty($fcmToken)) {
                $pdo->prepare("UPDATE vendors SET fcm_token = :fcm, updated_at = NOW() WHERE id = :id")->execute([':fcm' => $fcmToken, ':id' => $vendor['id']]);
            }

            $token = JWT::generate([
                'sub'       => (int)$vendor['id'],
                'role'      => 'vendor',
                'email'     => $vendor['email'],
                'full_name' => $vendor['full_name'],
            ]);
            $refreshToken = JWT::generateRefreshToken((int)$vendor['id'], 'vendor', $pdo);

            sendSuccess('Login successful.', [
                'is_new_user'   => false,
                'token'         => $token,
                'refresh_token' => $refreshToken,
                'vendor'        => $vendor,
            ]);
        } else {
            // New vendor registration required
            if (!empty($fullName) && !empty($email)) {
                // Delete verified OTP so it cannot be reused
                $del = $pdo->prepare("DELETE FROM otp_verifications WHERE phone = :phone AND role = :role");
                $del->execute([':phone' => $phone, ':role' => $role]);

                $chkE = $pdo->prepare("SELECT id FROM vendors WHERE LOWER(email) = :email LIMIT 1");
                $chkE->execute([':email' => $email]);
                if ($chkE->fetch()) {
                    sendError('This email is already registered with another account.', 422);
                }

                $dummyPassword = password_hash(bin2hex(random_bytes(16)), PASSWORD_BCRYPT);
                $country  = sanitize($body['country'] ?? 'India');
                $state    = sanitize($body['state'] ?? '');
                $district = sanitize($body['district'] ?? '');
                $taluka   = sanitize($body['taluka'] ?? '');

                $insV = $pdo->prepare("
                    INSERT INTO vendors (full_name, email, password, phone, country, state, district, taluka, created_at, updated_at)
                    VALUES (:full_name, :email, :password, :phone, :country, :state, :district, :taluka, NOW(), NOW())
                ");
                $insV->execute([
                    ':full_name' => $fullName,
                    ':email'     => $email,
                    ':password'  => $dummyPassword,
                    ':phone'     => $phone,
                    ':country'   => $country,
                    ':state'     => $state,
                    ':district'  => $district,
                    ':taluka'    => $taluka,
                ]);
                $vendorId = (int)$pdo->lastInsertId();

                $stmtV = $pdo->prepare("SELECT id, full_name, email, phone, country, state, district, taluka, is_active, created_at FROM vendors WHERE id = :id");
                $stmtV->execute([':id' => $vendorId]);
                $vendor = $stmtV->fetch();

                // Create Razorpay Contact
                $rzpRes = createRazorpayContact([
                    'name'         => $fullName,
                    'email'        => $email,
                    'contact'      => $phone,
                    'type'         => 'vendor',
                    'reference_id' => 'vendor_' . $vendorId,
                    'notes'        => [
                        'vendor_id'   => (string)$vendorId,
                        'created_via' => 'whatsapp_otp_signup',
                    ],
                ]);
                if (!empty($rzpRes['success']) && !empty($rzpRes['id'])) {
                    $pdo->prepare("UPDATE vendors SET razorpay_contact_id = :cid, updated_at = NOW() WHERE id = :id")
                        ->execute([':cid' => $rzpRes['id'], ':id' => $vendorId]);
                    $vendor['razorpay_contact_id'] = $rzpRes['id'];
                }

                if (!empty($fcmToken)) {
                    $pdo->prepare("UPDATE vendors SET fcm_token = :fcm, updated_at = NOW() WHERE id = :id")->execute([':fcm' => $fcmToken, ':id' => $vendorId]);
                }

                $token = JWT::generate([
                    'sub'       => $vendorId,
                    'role'      => 'vendor',
                    'email'     => $vendor['email'],
                    'full_name' => $vendor['full_name'],
                ]);
                $refreshToken = JWT::generateRefreshToken($vendorId, 'vendor', $pdo);

                sendSuccess('Vendor account created and logged in.', [
                    'is_new_user'   => false,
                    'token'         => $token,
                    'refresh_token' => $refreshToken,
                    'vendor'        => $vendor,
                ]);
            } else {
                sendSuccess('OTP verified. Vendor account registration required.', [
                    'is_new_user' => true,
                    'phone'       => $phone,
                    'role'        => 'vendor'
                ]);
            }
        }
    } else {
        // Customer Role
        $stmtC = $pdo->prepare("
            SELECT id, full_name, email, phone_number, is_active, created_at
            FROM customers WHERE phone_number = :phone OR phone_number LIKE :phone_like LIMIT 1
        ");
        $stmtC->execute([':phone' => $phone, ':phone_like' => '%' . $phone]);
        $customer = $stmtC->fetch();

        if ($customer) {
            // Delete verified OTP so it cannot be reused
            $del = $pdo->prepare("DELETE FROM otp_verifications WHERE phone = :phone AND role = :role");
            $del->execute([':phone' => $phone, ':role' => $role]);

            if (!(bool)$customer['is_active']) {
                sendError('Your account has been deactivated. Please contact support.', 403);
            }

            // Update last_login_at and mark online
            $pdo->prepare("UPDATE customers SET last_login_at = NOW(), last_seen_at = NOW(), is_online = 1, updated_at = NOW() WHERE id = :id")
                ->execute([':id' => $customer['id']]);

            if (!empty($fcmToken)) {
                $pdo->prepare("UPDATE customers SET fcm_token = :fcm, updated_at = NOW() WHERE id = :id")->execute([':fcm' => $fcmToken, ':id' => $customer['id']]);
            }

            $token = JWT::generate([
                'sub'       => (int)$customer['id'],
                'role'      => 'customer',
                'email'     => $customer['email'],
                'full_name' => $customer['full_name'],
            ]);
            $refreshToken = JWT::generateRefreshToken((int)$customer['id'], 'customer', $pdo);

            sendSuccess('Login successful.', [
                'is_new_user'   => false,
                'token'         => $token,
                'refresh_token' => $refreshToken,
                'customer'      => $customer,
            ]);
        } else {
            // New customer registration
            if (!empty($fullName)) {
                // Delete verified OTP so it cannot be reused
                $del = $pdo->prepare("DELETE FROM otp_verifications WHERE phone = :phone AND role = :role");
                $del->execute([':phone' => $phone, ':role' => $role]);

                $userEmail = !empty($email) ? $email : ('user_' . $phone . '@hungrily.app');

                // Check duplicate email
                $chkE = $pdo->prepare("SELECT id FROM customers WHERE LOWER(email) = :email LIMIT 1");
                $chkE->execute([':email' => $userEmail]);
                if ($chkE->fetch()) {
                    $userEmail = 'user_' . $phone . '_' . time() . '@hungrily.app';
                }

                $dummyPassword = password_hash(bin2hex(random_bytes(16)), PASSWORD_BCRYPT);
                $insC = $pdo->prepare("
                    INSERT INTO customers (full_name, email, password, phone_number, is_active, is_online, last_seen_at, created_at, updated_at)
                    VALUES (:full_name, :email, :password, :phone, 1, 1, NOW(), NOW(), NOW())
                ");
                $insC->execute([
                    ':full_name' => $fullName,
                    ':email'     => $userEmail,
                    ':password'  => $dummyPassword,
                    ':phone'     => $phone,
                ]);
                $customerId = (int)$pdo->lastInsertId();

                $stmtC = $pdo->prepare("SELECT id, full_name, email, phone_number, is_active, created_at FROM customers WHERE id = :id");
                $stmtC->execute([':id' => $customerId]);
                $customer = $stmtC->fetch();

                if (!empty($fcmToken)) {
                    $pdo->prepare("UPDATE customers SET fcm_token = :fcm, updated_at = NOW() WHERE id = :id")->execute([':fcm' => $fcmToken, ':id' => $customerId]);
                }

            $token = JWT::generate([
                    'sub'       => $customerId,
                    'role'      => 'customer',
                    'email'     => $customer['email'],
                    'full_name' => $customer['full_name'],
                ]);
                $refreshToken = JWT::generateRefreshToken($customerId, 'customer', $pdo);

                sendSuccess('Account created successfully.', [
                    'is_new_user'   => false,
                    'token'         => $token,
                    'refresh_token' => $refreshToken,
                    'customer'      => $customer,
                ]);
            } else {
                sendSuccess('OTP verified. Profile completion required.', [
                    'is_new_user' => true,
                    'phone'       => $phone,
                    'role'        => 'customer'
                ]);
            }
        }
    }
} catch (Exception $e) {
    sendError('Server error: ' . $e->getMessage(), 500);
}
