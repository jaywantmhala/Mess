<?php
require_once __DIR__ . '/config/database.php';
require_once __DIR__ . '/helpers/jwt.php';

// Generate a valid token for customer 2
$token = JWT::generate([
    'sub'       => 2,
    'email'     => 'jaywant61495@gmail.com',
    'full_name' => 'jaywant mhala',
]);

// Hit the API
$url = 'http://localhost:8000/api/hotels/nearby?latitude=18.5771196&longitude=73.9582365';

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Authorization: Bearer ' . $token,
    'Content-Type: application/json'
]);

$response = curl_exec($ch);
if(curl_errno($ch)){
    echo 'Curl error: ' . curl_error($ch);
}
curl_close($ch);

// Pretty print the JSON response
$decoded = json_decode($response, true);
echo json_encode($decoded, JSON_PRETTY_PRINT);
