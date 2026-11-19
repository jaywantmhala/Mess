<?php
/**
 * POST /api/admin/notifications/upload_image
 *
 * Securely uploads an image for push notifications (Admin Panel).
 * Saves locally to backend/uploads/notifications/ and optionally mirrors to Cloudinary.
 */

require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../helpers/response.php';
require_once __DIR__ . '/../../../helpers/jwt.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendError('Method not allowed. Use POST.', 405);
}

// 1. Verify Admin Token
$token = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;
if (!$payload || !isset($payload['sub']) || ($payload['role'] ?? '') !== 'admin') {
    sendError('Unauthorized. Admin access required.', 401);
}

// 2. Validate Uploaded File
if (!isset($_FILES['image']) || $_FILES['image']['error'] !== UPLOAD_ERR_OK) {
    $errCode = $_FILES['image']['error'] ?? UPLOAD_ERR_NO_FILE;
    $msg = 'No image file uploaded or upload error occurred.';
    if ($errCode === UPLOAD_ERR_INI_SIZE || $errCode === UPLOAD_ERR_FORM_SIZE) {
        $msg = 'File size exceeds maximum upload limit.';
    }
    sendError($msg, 422);
}

$file = $_FILES['image'];
$maxSize = 10 * 1024 * 1024; // 10MB
if ($file['size'] > $maxSize) {
    sendError('File size exceeds 10MB limit.', 422);
}

// Check real MIME type using finfo
$finfo = new finfo(FILEINFO_MIME_TYPE);
$mime = $finfo->file($file['tmp_name']);
$allowedMimes = [
    'image/jpeg' => 'jpg',
    'image/png'  => 'png',
    'image/webp' => 'webp',
    'image/gif'  => 'gif'
];

if (!isset($allowedMimes[$mime])) {
    sendError('Invalid image format. Allowed formats: JPG, PNG, WEBP, GIF.', 422);
}

$ext = $allowedMimes[$mime];
$safeFilename = 'notif_' . time() . '_' . bin2hex(random_bytes(6)) . '.' . $ext;

// 3. Save to local upload directory
$uploadDir = realpath(__DIR__ . '/../../../') . DIRECTORY_SEPARATOR . 'uploads' . DIRECTORY_SEPARATOR . 'notifications';
if (!is_dir($uploadDir)) {
    @mkdir($uploadDir, 0755, true);
}

$destination = $uploadDir . DIRECTORY_SEPARATOR . $safeFilename;
if (!move_uploaded_file($file['tmp_name'], $destination)) {
    sendError('Failed to save uploaded image on server.', 500);
}

// Build local URL
$scheme = (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on') ? 'https://' : 'http://';
$host = $_SERVER['HTTP_HOST'] ?? '10.44.177.233:8000';
$localUrl = $scheme . $host . '/backend/uploads/notifications/' . $safeFilename;

// 4. Mirror to Cloudinary CDN for ultra-fast, global public delivery
$finalUrl = $localUrl;
$cloudinaryUrl = null;

$cloudName = 'dzyhoeurm';
$apiKey = '826648439174773';
$apiSecret = 'wI6oL1bHuwTtDgaq3XBKZuZVpTQ';

if (function_exists('curl_init') && !empty($cloudName) && !empty($apiKey)) {
    try {
        $timestamp = time();
        $folder = 'notifications';
        $stringToSign = "folder={$folder}&timestamp={$timestamp}{$apiSecret}";
        $signature = sha1($stringToSign);

        $cFile = new CURLFile($destination, $mime, $safeFilename);

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, "https://api.cloudinary.com/v1_1/{$cloudName}/image/upload");
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, [
            'file'      => $cFile,
            'api_key'   => $apiKey,
            'timestamp' => $timestamp,
            'folder'    => $folder,
            'signature' => $signature,
        ]);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_TIMEOUT, 15);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);

        $cRes = curl_exec($ch);
        $cCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if ($cCode === 200 && $cRes) {
            $cJson = json_decode($cRes, true);
            if (!empty($cJson['secure_url'])) {
                $cloudinaryUrl = $cJson['secure_url'];
                $finalUrl = $cloudinaryUrl;
            }
        }
    } catch (Exception $e) {
        // Fall back gracefully to localUrl
        error_log('Cloudinary upload error in upload_image.php: ' . $e->getMessage());
    }
}

sendSuccess('Image uploaded successfully.', [
    'url'            => $finalUrl,
    'local_url'      => $localUrl,
    'cloudinary_url' => $cloudinaryUrl,
    'filename'       => $safeFilename,
    'size'           => filesize($destination),
    'mime'           => $mime
]);
