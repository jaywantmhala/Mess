<?php
/**
 * POST /api/admin/whatsapp/send
 *
 * Broadcast bulk WhatsApp messages from Admin to All Users, Customers, Vendors, or Drivers
 * with optional location filters (state, district, taluka).
 * Body: { message, target ("all"|"customers"|"vendors"|"drivers"), state?, district?, taluka? }
 */

require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../helpers/response.php';
require_once __DIR__ . '/../../../helpers/validation.php';
require_once __DIR__ . '/../../../helpers/jwt.php';
require_once __DIR__ . '/../../../helpers/click2api_helper.php';

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

$rawInput  = file_get_contents('php://input');
$inputJson = json_decode($rawInput, true);
if (!is_array($inputJson)) {
    $inputJson = $_POST ?: [];
}
$message         = trim($inputJson['message'] ?? '');
$target          = strtolower(trim($inputJson['target'] ?? 'all'));
$state           = trim($inputJson['state'] ?? '');
$district        = trim($inputJson['district'] ?? '');
$taluka          = trim($inputJson['taluka'] ?? '');
$templateName    = trim($inputJson['template_name'] ?? ($inputJson['template']['name'] ?? ''));
$langCode        = trim($inputJson['language_code'] ?? ($inputJson['template']['language']['code'] ?? 'en'));
$components      = is_array($inputJson['components'] ?? null) ? $inputJson['components'] : (is_array($inputJson['template']['components'] ?? null) ? $inputJson['template']['components'] : []);

// Role-specific dynamic messages
$customerMessage = trim($inputJson['customer_message'] ?? ($inputJson['role_messages']['customers'] ?? ''));
$vendorMessage   = trim($inputJson['vendor_message']   ?? ($inputJson['role_messages']['vendors'] ?? ''));
$driverMessage   = trim($inputJson['driver_message']   ?? ($inputJson['role_messages']['drivers'] ?? ''));
$dynamicMode     = trim($inputJson['dynamic_mode'] ?? 'single'); // 'single' or 'per_role'

if ($district === 'all') $district = '';
if ($taluka === 'all')   $taluka   = '';
if ($state === 'all')    $state    = '';

if ($target === 'customers' && !empty($customerMessage) && empty($message)) {
    $message = $customerMessage;
} elseif ($target === 'vendors' && !empty($vendorMessage) && empty($message)) {
    $message = $vendorMessage;
} elseif ($target === 'drivers' && !empty($driverMessage) && empty($message)) {
    $message = $driverMessage;
}

if (empty($message) && empty($customerMessage) && empty($vendorMessage) && empty($driverMessage) && empty($templateName)) {
    sendError('WhatsApp message content or template name is required.', 422);
}

// If a custom message exists, ensure it is NOT overridden by the static 'welcome' template
if (empty($templateName) || $templateName === 'welcome') {
    if (!empty($message) && $message !== 'Template Broadcast: welcome') {
        $templateName = 'text';
    } else {
        $templateName = !empty($templateName) ? $templateName : 'text';
    }
}

if (empty($message)) {
    $message = !empty($customerMessage) ? $customerMessage : (!empty($vendorMessage) ? $vendorMessage : ($driverMessage ?: ('Template Broadcast: ' . $templateName)));
}

$validTargets = ['all', 'customers', 'vendors', 'drivers'];
if (!in_array($target, $validTargets, true)) {
    $target = 'all';
}

$pdo = getDBConnection();
$recipients = [];

function renderDynamicWhatsAppText(string $template, array $rec): string {
    $fullName = trim($rec['name'] ?: $rec['role']);
    $nameParts = preg_split('/\s+/', $fullName);
    $firstName = $nameParts[0] ?? $fullName;

    $cleanPhone = preg_replace('/[^0-9]/', '', $rec['phone'] ?? '');
    $phone = substr($cleanPhone, -10);
    $district = !empty($rec['district']) ? $rec['district'] : 'your area';
    $taluka   = !empty($rec['taluka']) ? $rec['taluka'] : $district;
    $state    = !empty($rec['state']) ? $rec['state'] : 'Maharashtra';
    $hotel    = !empty($rec['hotel_name']) ? $rec['hotel_name'] : 'Hungrily Foods';
    $vehicle  = !empty($rec['vehicle_number']) ? $rec['vehicle_number'] : '';

    $map = [
        '{name}'           => $fullName,
        '{full_name}'      => $fullName,
        '{first_name}'     => $firstName,
        '{role}'           => $rec['role'],
        '{role_type}'      => $rec['role'],
        '{phone}'          => $phone,
        '{mobile}'         => $phone,
        '{district}'       => $district,
        '{taluka}'         => $taluka,
        '{state}'          => $state,
        '{hotel_name}'     => $hotel,
        '{hotel}'          => $hotel,
        '{business_name}'  => $hotel,
        '{vehicle_number}' => $vehicle,
        '{vehicle}'        => $vehicle,
        '{date}'           => date('d M Y'),
        '{time}'           => date('h:i A'),
    ];

    return str_ireplace(array_keys($map), array_values($map), $template);
}

try {
    // 1. Collect Customer Recipients
    if ($target === 'customers' || $target === 'all') {
        $cWhere = ["c.phone_number IS NOT NULL AND TRIM(c.phone_number) != ''"];
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

        $cSql = "SELECT c.id, c.full_name, c.email, c.phone_number, c.state,
                        COALESCE(NULLIF(TRIM(c.district), ''), MAX(ca.district), '') AS district,
                        COALESCE(NULLIF(TRIM(c.taluka), ''), MAX(ca.taluka), '') AS taluka
                 FROM customers c
                 LEFT JOIN customer_addresses ca ON ca.customer_id = c.id
                 WHERE " . implode(' AND ', $cWhere) . "
                 GROUP BY c.id, c.full_name, c.email, c.phone_number, c.state, c.district, c.taluka";
        $cStmt = $pdo->prepare($cSql);
        $cStmt->execute($cParams);
        while ($row = $cStmt->fetch(PDO::FETCH_ASSOC)) {
            if (!empty($row['phone_number'])) {
                $recipients[] = [
                    'role'           => 'Customer',
                    'role_type'      => 'customer',
                    'name'           => trim($row['full_name'] ?: 'Customer'),
                    'phone'          => $row['phone_number'],
                    'district'       => trim($row['district'] ?: ''),
                    'taluka'         => trim($row['taluka'] ?: ''),
                    'state'          => trim($row['state'] ?: ''),
                    'hotel_name'     => 'Hungrily Foods',
                    'vehicle_number' => ''
                ];
            }
        }
    }

    // 2. Collect Vendor Recipients
    if ($target === 'vendors' || $target === 'all') {
        $vWhere = ["(v.phone IS NOT NULL AND TRIM(v.phone) != '') OR (v.mobile_number IS NOT NULL AND TRIM(v.mobile_number) != '')"];
        $vParams = [];

        if (!empty($state)) {
            $vWhere[] = "(v.state = :state OR LOWER(h.hotel_address) LIKE :state_like)";
            $vParams[':state'] = $state;
            $vParams[':state_like'] = '%' . strtolower($state) . '%';
        }
        if (!empty($district)) {
            $vWhere[] = "(v.district = :dist OR LOWER(h.city) = LOWER(:city) OR LOWER(h.hotel_address) LIKE :dist_like)";
            $vParams[':dist'] = $district;
            $vParams[':city'] = $district;
            $vParams[':dist_like'] = '%' . strtolower($district) . '%';
        }
        if (!empty($taluka)) {
            $vWhere[] = "(v.taluka = :tal OR LOWER(h.hotel_address) LIKE :tal_like)";
            $vParams[':tal'] = $taluka;
            $vParams[':tal_like'] = '%' . strtolower($taluka) . '%';
        }

        $vSql = "SELECT v.id, v.full_name, v.owner_name, v.business_name,
                        COALESCE(NULLIF(TRIM(v.phone), ''), v.mobile_number) AS phone,
                        v.state,
                        COALESCE(NULLIF(TRIM(v.district), ''), MAX(h.city), '') AS district,
                        COALESCE(NULLIF(TRIM(v.taluka), ''), '') AS taluka,
                        COALESCE(MAX(h.hotel_name), v.business_name, 'Hungrily Vendor') AS hotel_name
                 FROM vendors v
                 LEFT JOIN hotels h ON h.vendor_id = v.id
                 WHERE " . implode(' AND ', $vWhere) . "
                 GROUP BY v.id, v.full_name, v.owner_name, v.business_name, v.phone, v.mobile_number, v.state, v.district, v.taluka";
        $vStmt = $pdo->prepare($vSql);
        $vStmt->execute($vParams);
        while ($row = $vStmt->fetch(PDO::FETCH_ASSOC)) {
            if (!empty($row['phone'])) {
                $vendorName = trim($row['owner_name'] ?: ($row['full_name'] ?: 'Vendor'));
                $recipients[] = [
                    'role'           => 'Vendor',
                    'role_type'      => 'vendor',
                    'name'           => $vendorName,
                    'phone'          => $row['phone'],
                    'district'       => trim($row['district'] ?: ''),
                    'taluka'         => trim($row['taluka'] ?: ''),
                    'state'          => trim($row['state'] ?: ''),
                    'hotel_name'     => trim($row['hotel_name'] ?: 'Hungrily Vendor'),
                    'vehicle_number' => ''
                ];
            }
        }
    }

    // 3. Collect Driver Recipients
    if ($target === 'drivers' || $target === 'all') {
        $dWhere = ["d.phone_number IS NOT NULL AND TRIM(d.phone_number) != ''"];
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

        $dSql = "SELECT d.id, d.full_name, d.phone_number, d.vehicle_number, d.state, d.district, d.taluka
                 FROM drivers d
                 WHERE " . implode(' AND ', $dWhere);
        $dStmt = $pdo->prepare($dSql);
        $dStmt->execute($dParams);
        while ($row = $dStmt->fetch(PDO::FETCH_ASSOC)) {
            if (!empty($row['phone_number'])) {
                $recipients[] = [
                    'role'           => 'Driver',
                    'role_type'      => 'driver',
                    'name'           => trim($row['full_name'] ?: 'Driver'),
                    'phone'          => $row['phone_number'],
                    'district'       => trim($row['district'] ?: ''),
                    'taluka'         => trim($row['taluka'] ?: ''),
                    'state'          => trim($row['state'] ?: ''),
                    'hotel_name'     => 'Hungrily Delivery',
                    'vehicle_number' => trim($row['vehicle_number'] ?: '')
                ];
            }
        }
    }

    // Deduplicate recipients by clean 10-digit mobile number
    $dedupedRecipients = [];
    $seenPhones = [];
    foreach ($recipients as $rec) {
        $clean = preg_replace('/[^0-9]/', '', $rec['phone']);
        if (strlen($clean) >= 10) {
            $last10 = substr($clean, -10);
            if (!isset($seenPhones[$last10])) {
                $seenPhones[$last10] = true;
                $dedupedRecipients[] = $rec;
            }
        }
    }

    if (empty($dedupedRecipients)) {
        sendError('No recipients with valid mobile phone numbers matched the selected filters.', 404);
    }

    // Build personalized payloads for each recipient
    $batchPayloads = [];
    $countsByRole = ['customers' => 0, 'vendors' => 0, 'drivers' => 0];

    foreach ($dedupedRecipients as $rec) {
        $rType = strtolower($rec['role_type']);
        if ($rType === 'customer') $countsByRole['customers']++;
        elseif ($rType === 'vendor') $countsByRole['vendors']++;
        elseif ($rType === 'driver') $countsByRole['drivers']++;

        // Determine template text for this role
        $templateForRec = $message;
        if ($rType === 'customer' && !empty($customerMessage)) {
            $templateForRec = $customerMessage;
        } elseif ($rType === 'vendor' && !empty($vendorMessage)) {
            $templateForRec = $vendorMessage;
        } elseif ($rType === 'driver' && !empty($driverMessage)) {
            $templateForRec = $driverMessage;
        }

        // Render dynamic variables ({name}, {role}, {district}, {taluka}, {hotel_name}, etc.)
        $personalizedMsg = renderDynamicWhatsAppText($templateForRec, $rec);

        // Also replace dynamic variables in Meta template components if present
        $recComponents = $components;
        if (!empty($recComponents) && is_array($recComponents)) {
            $jsonStr = json_encode($recComponents);
            $replacedJson = renderDynamicWhatsAppText($jsonStr, $rec);
            $recComponents = json_decode($replacedJson, true) ?: $components;
        }

        // If hungrily_broadcast is selected and components are empty, auto-populate with recipient name and message
        if ($templateName === 'hungrily_broadcast' && empty($recComponents)) {
            $recComponents = [
                [
                    'type' => 'body',
                    'parameters' => [
                        ['type' => 'text', 'text' => trim($rec['name'] ?: $rec['role'])],
                        ['type' => 'text', 'text' => $personalizedMsg]
                    ]
                ]
            ];
        }

        $batchPayloads[] = [
            'name'          => trim($rec['name'] ?: $rec['role']),
            'role'          => $rec['role'],
            'phone'         => $rec['phone'],
            'message'       => $personalizedMsg,
            'template_name' => $templateName,
            'components'    => $recComponents,
            'lang_code'     => $langCode,
        ];
    }

    // Dispatch dynamic WhatsApp messages via Click2Api in parallel
    $batchRes = sendWhatsAppBatchMessages($batchPayloads, $message, $templateName, $components, $langCode);
    $sentCount = $batchRes['sent'] ?? 0;
    $failedCount = $batchRes['failed'] ?? 0;

    // Ensure database table exists
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS `admin_whatsapp_notifications` (
            `id`            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            `message`       TEXT NOT NULL,
            `target`        VARCHAR(50) NOT NULL DEFAULT 'all',
            `state`         VARCHAR(100) DEFAULT NULL,
            `district`      VARCHAR(100) DEFAULT NULL,
            `taluka`        VARCHAR(100) DEFAULT NULL,
            `target_count`  INT UNSIGNED DEFAULT 0,
            `sent_count`    INT UNSIGNED DEFAULT 0,
            `failed_count`  INT UNSIGNED DEFAULT 0,
            `created_at`    DATETIME DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ");

    $storedMessage = $message;
    if (!empty($customerMessage) || !empty($vendorMessage) || !empty($driverMessage)) {
        $storedParts = [];
        if (!empty($customerMessage)) $storedParts[] = "[Customer]: " . $customerMessage;
        if (!empty($vendorMessage))   $storedParts[] = "[Vendor]: " . $vendorMessage;
        if (!empty($driverMessage))   $storedParts[] = "[Driver]: " . $driverMessage;
        if (!empty($storedParts)) {
            $storedMessage = implode("\n---\n", $storedParts);
        }
    }

    $insertStmt = $pdo->prepare("
        INSERT INTO admin_whatsapp_notifications (message, target, state, district, taluka, target_count, sent_count, failed_count, created_at)
        VALUES (:message, :target, :state, :district, :taluka, :target_count, :sent_count, :failed_count, NOW())
    ");
    $insertStmt->execute([
        ':message'      => $storedMessage,
        ':target'       => $target,
        ':state'        => $state ?: null,
        ':district'     => $district ?: null,
        ':taluka'       => $taluka ?: null,
        ':target_count' => count($dedupedRecipients),
        ':sent_count'   => $sentCount,
        ':failed_count' => $failedCount,
    ]);

    $logId = $pdo->lastInsertId();

    $filterSummary = [];
    if ($state)    $filterSummary[] = "State: $state";
    if ($district) $filterSummary[] = "District: $district";
    if ($taluka)   $filterSummary[] = "Taluka: $taluka";
    $filterStr = count($filterSummary) > 0 ? ' (' . implode(', ', $filterSummary) . ')' : '';

    sendSuccess("WhatsApp bulk broadcast sent to $sentCount phone number(s)$filterStr.", [
        'id'             => (int)$logId,
        'message'        => $storedMessage,
        'target'         => $target,
        'district'       => $district,
        'taluka'         => $taluka,
        'sent_count'     => $sentCount,
        'failed_count'   => $failedCount,
        'total_phones'   => count($dedupedRecipients),
        'counts_by_role' => $countsByRole,
        'created_at'     => date('Y-m-d H:i:s')
    ]);

} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
