<?php
// backend/websocket_server.php

// Set execution time limit to infinite (run indefinitely)
set_time_limit(0);
ob_implicit_flush();

require_once __DIR__ . '/config/database.php';
require_once __DIR__ . '/helpers/jwt.php';

$address = '0.0.0.0';
$port = 8081;

// Create a TCP stream server socket (built-in, no extra php extensions required!)
$server = @stream_socket_server("tcp://$address:$port", $errno, $errstr);
if (!$server) {
    die("Error: stream_socket_server failed: $errstr ($errno)\n");
}

echo "Native PHP Stream WebSocket server running on $address:$port...\n";

// List of all active sockets (including the listening server socket)
$sockets = [$server];

// Socket metadata: holds auth & role info for each connection
// Structure: [ (int)socket_id => [ 'role' => 'vendor'|'customer', 'id' => int, 'hotels' => [int] ] ]
$socket_metadata = [];

// Database connection
$pdo = null;
function getWSDBConnection() {
    global $pdo;
    if ($pdo === null) {
        try {
            $pdo = getDBConnection();
        } catch (Exception $e) {
            echo "Database connection error: " . $e->getMessage() . "\n";
        }
    }
    return $pdo;
}

// Perform WebSocket Handshake
function performHandshake($headers, $client_socket) {
    if (preg_match("/Sec-WebSocket-Key:\s*([^\r\n]+)/i", $headers, $matches)) {
        $key = trim($matches[1]);
        $accept = base64_encode(pack('H*', sha1($key . '258EAFA5-E914-47DA-95CA-C5AB0DC85B11')));
        $response = "HTTP/1.1 101 Switching Protocols\r\n" .
                    "Upgrade: websocket\r\n" .
                    "Connection: Upgrade\r\n" .
                    "Sec-WebSocket-Accept: $accept\r\n\r\n";
        @fwrite($client_socket, $response);
        return true;
    }
    return false;
}

// Encode data into a WebSocket frame (Server -> Client)
function encodeFrame($text) {
    $b1 = 0x81; // FIN bit + Text Frame opcode (0x1)
    $length = strlen($text);
    
    if ($length <= 125) {
        $header = pack('CC', $b1, $length);
    } elseif ($length < 65536) {
        $header = pack('CCn', $b1, 126, $length);
    } else {
        $header = pack('CCNN', $b1, 127, 0, $length);
    }
    
    return $header . $text;
}

// Decode masked WebSocket frame (Client -> Server)
function decodeFrame($payload) {
    if (strlen($payload) < 2) return '';
    $length = ord($payload[1]) & 127;
    
    if ($length == 126) {
        if (strlen($payload) < 8) return '';
        $masks = substr($payload, 4, 4);
        $data = substr($payload, 8);
    } elseif ($length == 127) {
        if (strlen($payload) < 14) return '';
        $masks = substr($payload, 10, 4);
        $data = substr($payload, 14);
    } else {
        if (strlen($payload) < 6) return '';
        $masks = substr($payload, 2, 4);
        $data = substr($payload, 6);
    }
    
    $text = '';
    for ($i = 0; $i < strlen($data); ++$i) {
        $text .= $data[$i] ^ $masks[$i % 4];
    }
    return $text;
}

// Check if incoming client frame is a Connection Close frame
function isCloseFrame($payload) {
    if (strlen($payload) < 1) return false;
    $opcode = ord($payload[0]) & 0x0F;
    return $opcode === 0x08; // 0x08 is Close Frame
}

// Main event loop
while (true) {
    $read = $sockets;
    $write = null;
    $except = null;
    
    // Select sockets ready for reading
    if (@stream_select($read, $write, $except, 1) === false) {
        continue;
    }
    
    // 1. Handle new incoming TCP connection on the server port
    if (in_array($server, $read)) {
        $new_socket = @stream_socket_accept($server);
        if ($new_socket) {
            @stream_set_blocking($new_socket, 0);
            $sockets[] = $new_socket;
            echo "New client connected. Sockets count: " . count($sockets) . "\n";
        }
        // Remove server socket from read list
        $key = array_search($server, $read);
        unset($read[$key]);
    }
    
    // 2. Read incoming data from existing clients
    foreach ($read as $client) {
        $client_id = (int)$client;
        $data = @fread($client, 4096);
        
        if ($data === false || ($data === '' && feof($client))) {
            // Client closed connection abruptly
            echo "Client #$client_id disconnected.\n";
            unset($socket_metadata[$client_id]);
            $key = array_search($client, $sockets);
            if ($key !== false) unset($sockets[$key]);
            @fclose($client);
            continue;
        }
        
        if ($data === '') {
            continue;
        }
        
        // ── Case A: Client has NOT completed handshake yet ───────────────────
        if (!isset($socket_metadata[$client_id])) {
            
            // Check if it's a local System Event (JSON notification from PHP API)
            if (strpos($data, '{"system_event":true') === 0) {
                echo "System event received.\n";
                $payload = json_decode($data, true);
                
                if (json_last_error() === JSON_ERROR_NONE && 
                    isset($payload['secret']) && 
                    $payload['secret'] === 'first_demo_system_websocket_secret_key_2026') {
                    
                    $event = $payload['event'] ?? '';
                    $eventData = $payload['data'] ?? [];
                    
                    if ($event === 'NEW_ORDER') {
                        $hotelId = (int)($eventData['hotel_id'] ?? 0);
                        echo "Broadcasting NEW_ORDER for hotel #$hotelId\n";
                        
                        // Find and notify only the vendor mapped to this hotel
                        foreach ($socket_metadata as $sid => $meta) {
                            if ($meta['role'] === 'vendor' && in_array($hotelId, $meta['hotels'])) {
                                $vendor_socket = $sockets[array_search($sid, array_map('intval', $sockets))];
                                if ($vendor_socket) {
                                    $msg = json_encode(['event' => 'NEW_ORDER', 'data' => $eventData]);
                                    @fwrite($vendor_socket, encodeFrame($msg));
                                    echo "Pushed NEW_ORDER to vendor socket #$sid\n";
                                }
                            }
                        }
                    } 
                    elseif ($event === 'ORDER_STATUS_UPDATED') {
                        $orderId = (int)($eventData['order_id'] ?? 0);
                        $customerId = (int)($eventData['customer_id'] ?? 0);
                        $hotelId = (int)($eventData['hotel_id'] ?? 0);
                        $status = $eventData['status'] ?? '';
                        echo "Broadcasting status change for order #$orderId (Status: $status)\n";
                        
                        // Push to Customer
                        foreach ($socket_metadata as $sid => $meta) {
                            if ($meta['role'] === 'customer' && $meta['id'] === $customerId) {
                                $cust_socket = $sockets[array_search($sid, array_map('intval', $sockets))];
                                if ($cust_socket) {
                                    $msg = json_encode(['event' => 'ORDER_STATUS_UPDATED', 'data' => $eventData]);
                                    @fwrite($cust_socket, encodeFrame($msg));
                                }
                            }
                        }
                        
                        // Push to Vendor
                        foreach ($socket_metadata as $sid => $meta) {
                            if ($meta['role'] === 'vendor' && in_array($hotelId, $meta['hotels'])) {
                                $vendor_socket = $sockets[array_search($sid, array_map('intval', $sockets))];
                                if ($vendor_socket) {
                                    $msg = json_encode(['event' => 'ORDER_STATUS_UPDATED', 'data' => $eventData]);
                                    @fwrite($vendor_socket, encodeFrame($msg));
                                }
                            }
                        }
                    }
                }
                
                // Immediately close connection with local system client
                $key = array_search($client, $sockets);
                if ($key !== false) unset($sockets[$key]);
                @fclose($client);
                continue;
            }
            
            // Otherwise, treat as regular WebSocket handshake
            if (performHandshake($data, $client)) {
                echo "WebSocket handshake completed for client #$client_id.\n";
                
                // Initialize default unauthenticated metadata
                $socket_metadata[$client_id] = [
                    'authenticated' => false,
                    'role' => 'anonymous',
                    'id' => null,
                    'hotels' => []
                ];
                
                // Parse JWT token from query parameters: GET /?token=XYZ HTTP/1.1
                if (preg_match("/GET (.*) HTTP/", $data, $reqMatches)) {
                    $path = $reqMatches[1];
                    $urlParts = parse_url($path);
                    if (isset($urlParts['query'])) {
                        parse_str($urlParts['query'], $queryParts);
                        $token = $queryParts['token'] ?? null;
                        
                        if ($token) {
                            $payload = JWT::verify($token);
                            if ($payload) {
                                $role = $payload['role'] ?? 'customer';
                                $sub = (int)($payload['sub'] ?? 0);
                                
                                $socket_metadata[$client_id]['authenticated'] = true;
                                $socket_metadata[$client_id]['role'] = $role;
                                $socket_metadata[$client_id]['id'] = $sub;
                                
                                echo "Client authenticated as role: $role, User ID: $sub\n";
                                
                                if ($role === 'vendor') {
                                    // Fetch the hotels owned by this vendor
                                    $db = getWSDBConnection();
                                    if ($db) {
                                        $stmt = $db->prepare("SELECT id FROM hotels WHERE vendor_id = ?");
                                        $stmt->execute([$sub]);
                                        $hotels = $stmt->fetchAll(PDO::FETCH_COLUMN);
                                        $socket_metadata[$client_id]['hotels'] = array_map('intval', $hotels);
                                        echo "Vendor manages hotels: " . implode(',', $socket_metadata[$client_id]['hotels']) . "\n";
                                    }
                                }
                            } else {
                                echo "Auth token verification failed.\n";
                            }
                        }
                    }
                }
            } else {
                // Not a valid handshake, reject and close
                $key = array_search($client, $sockets);
                if ($key !== false) unset($sockets[$key]);
                @fclose($client);
            }
        } 
        
        // ── Case B: Client is already connected (Authenticated WebSocket) ────
        else {
            if (isCloseFrame($data)) {
                echo "Client #$client_id sent close frame.\n";
                unset($socket_metadata[$client_id]);
                $key = array_search($client, $sockets);
                if ($key !== false) unset($sockets[$key]);
                @fclose($client);
                continue;
            }
            
            $text = decodeFrame($data);
            if ($text === '') continue;
            
            $msg = json_decode($text, true);
            if (json_last_error() === JSON_ERROR_NONE) {
                // Heartbeat ping-pong
                if (isset($msg['type']) && $msg['type'] === 'ping') {
                    @fwrite($client, encodeFrame(json_encode(['type' => 'pong'])));
                }
            }
        }
    }
}
