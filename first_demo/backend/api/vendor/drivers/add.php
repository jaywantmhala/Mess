<?php
/**
 * POST /api/vendor/drivers/add
 * Creates a new driver associated with the authenticated vendor,
 * validates duplicate phone number & email,
 * and automatically dispatches onboarding credentials (with the ORIGINAL unencrypted password)
 * directly to the driver's phone via the Click2Api WhatsApp API (used in Admin Panel).
 *
 * Requires: Authorization: Bearer <JWT> (Vendor role required)
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'POST') { sendError('Method not allowed.', 405); }

require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../helpers/jwt.php';
require_once __DIR__ . '/../../../helpers/response.php';
require_once __DIR__ . '/../../../helpers/click2api_helper.php';

$token   = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;

if (!$payload || ($payload['role'] ?? '') !== 'vendor') {
    sendError('Unauthorized access. Vendor token required.', 401);
}

$vendorId = (int)$payload['sub'];

$body = json_decode(file_get_contents('php://input'), true);
if (!$body) {
    sendError('Invalid JSON body.', 400);
}

$fullName      = trim($body['full_name'] ?? '');
$email         = trim(strtolower($body['email'] ?? ''));
$originalPass  = trim($body['password'] ?? '');
$vehicleNumber = trim($body['vehicle_number'] ?? '');
$phoneNumber   = trim($body['phone_number'] ?? '');

if (empty($fullName))      { sendError('Driver full name is required.', 422); }
if (empty($email))         { sendError('Driver email address is required.', 422); }
if (empty($originalPass))  { sendError('Driver password is required.', 422); }
if (empty($vehicleNumber)) { sendError('Vehicle number is required.', 422); }
if (empty($phoneNumber))   { sendError('Phone number is required.', 422); }

// Clean and normalize phone number
$cleanPhone = preg_replace('/[^0-9]/', '', $phoneNumber);
$last10 = substr($cleanPhone, -10);

if (strlen($last10) !== 10 || !preg_match('/^[6-9][0-9]{9}$/', $last10)) {
    sendError('Please enter a valid 10-digit Indian mobile number.', 422);
}

try {
    $pdo = getDBConnection();

    // ── 1. Check if Phone Number is Already Present ──────────────────────────
    $phoneChk = $pdo->prepare("
        SELECT id, full_name, phone_number 
        FROM drivers 
        WHERE phone_number = ? 
           OR phone_number = ? 
           OR phone_number = ? 
           OR phone_number LIKE ?
        LIMIT 1
    ");
    $phoneChk->execute([
        $phoneNumber,
        $last10,
        '+91' . $last10,
        '%' . $last10
    ]);
    $existingPhone = $phoneChk->fetch(PDO::FETCH_ASSOC);
    if ($existingPhone) {
        sendError('Mobile number +91 ' . $last10 . ' is already registered with driver: "' . $existingPhone['full_name'] . '".', 409);
    }

    // ── 2. Check if Email is Already Present ─────────────────────────────────
    $emailChk = $pdo->prepare("SELECT id, full_name FROM drivers WHERE email = ? LIMIT 1");
    $emailChk->execute([$email]);
    $existingEmail = $emailChk->fetch(PDO::FETCH_ASSOC);
    if ($existingEmail) {
        sendError('A driver with email address "' . $email . '" already exists (' . $existingEmail['full_name'] . ').', 409);
    }

    // ── 3. Hash Password for Secure DB Storage ───────────────────────────────
    $hashedPassword = password_hash($originalPass, PASSWORD_BCRYPT);

    // ── 4. Insert New Driver ─────────────────────────────────────────────────
    $insStmt = $pdo->prepare("
        INSERT INTO drivers 
            (vendor_id, full_name, email, password, vehicle_number, phone_number, is_online, max_capacity, created_at, updated_at) 
        VALUES (?, ?, ?, ?, ?, ?, 1, 5, NOW(), NOW())
    ");
    $insStmt->execute([
        $vendorId,
        $fullName,
        $email,
        $hashedPassword,
        $vehicleNumber,
        $last10
    ]);

    $driverId = (int)$pdo->lastInsertId();

    // ── 5. Fetch Vendor & Mess Info for Personalized WhatsApp Message ────────
    $vStmt = $pdo->prepare("
        SELECT v.full_name, v.phone, COALESCE(h.hotel_name, v.full_name) AS mess_name
        FROM vendors v
        LEFT JOIN hotels h ON h.vendor_id = v.id
        WHERE v.id = ?
        LIMIT 1
    ");
    $vStmt->execute([$vendorId]);
    $vInfo = $vStmt->fetch(PDO::FETCH_ASSOC);

    $vendorName = !empty($vInfo['mess_name']) ? $vInfo['mess_name'] : (!empty($vInfo['full_name']) ? $vInfo['full_name'] : 'Hungrily Partner');
    $vendorPhone = !empty($vInfo['phone']) ? $vInfo['phone'] : '';

    // ── 6. Compose WhatsApp Onboarding Message (Original Unencrypted Password) 
    $detailsMsg = "Welcome to the Hungrily Delivery Team! Your driver account has been created by *" . $vendorName . "*.\n\n"
        . "Here are your login credentials for the *Hungrily Driver App*:\n\n"
        . "📱 *Mobile (Login ID):* +91 " . $last10 . "\n"
        . "🔑 *Password:* " . $originalPass . "\n"
        . "🛵 *Vehicle Number:* " . $vehicleNumber . "\n"
        . "🏢 *Mess / Vendor:* " . $vendorName . "\n\n"
        . "📲 *How to Log In & Start Delivering:*\n"
        . "1. Open the *Hungrily Driver App* on your mobile device\n"
        . "2. Enter your Registered Mobile: +91 " . $last10 . "\n"
        . "3. Enter your Password: " . $originalPass . "\n"
        . "4. Tap *Login* and toggle *Go Online* to receive orders!\n\n"
        . "⚠️ *Important Security Note:*\n"
        . "Please keep your credentials safe and do not share your password with anyone."
        . (!empty($vendorPhone) ? "\n📞 *Vendor Contact:* +91 " . $vendorPhone : "");

    $whatsappMsg = "Hello *" . $fullName . "*,\n\n" . $detailsMsg;

    // ── 7. Dispatch via Meta Template WhatsApp API (hungrily_broadcast)
    $waSuccess = false;
    $waMessage = '';

    try {
        $waRes = sendDriverCredentialsWhatsApp($last10, $fullName, $detailsMsg);
        if (!empty($waRes['success'])) {
            $waSuccess = true;
            $waMessage = 'WhatsApp credentials dispatched successfully via WhatsApp API.';
        } else {
            $waMessage = $waRes['message'] ?? 'WhatsApp API delivery failed.';
        }
    } catch (Throwable $wEx) {
        $waMessage = $wEx->getMessage();
        error_log("[Driver Registration WhatsApp API Exception] " . $wEx->getMessage());
    }

    // ── 8. Return Response ───────────────────────────────────────────────────
    $successMessage = $waSuccess
        ? 'Driver created successfully! Credentials sent to ' . $fullName . '\'s WhatsApp.'
        : 'Driver created successfully! (WhatsApp API notice: ' . $waMessage . ')';

    sendSuccess($successMessage, [
        'driver_id'        => $driverId,
        'vendor_id'        => $vendorId,
        'full_name'        => $fullName,
        'email'            => $email,
        'vehicle_number'   => $vehicleNumber,
        'phone_number'     => $last10,
        'is_online'        => 1,
        'whatsapp_sent'    => $waSuccess,
        'whatsapp_message' => $waMessage,
        'message_content'  => $whatsappMsg,
    ], 201);

} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
