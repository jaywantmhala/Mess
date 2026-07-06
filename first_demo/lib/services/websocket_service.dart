// lib/services/websocket_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'auth_service.dart';
import '../utils/app_config.dart';

class WebSocketService {
  WebSocketService._();
  static final WebSocketService instance = WebSocketService._();

  WebSocketChannel? _channel;
  bool _isConnecting = false;
  bool _shouldReconnect = true;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  // Stream controller to broadcast parsed incoming messages (e.g. order status updates)
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  bool get isConnected => _channel != null;

  /// Start connection to WebSocket server
  Future<void> connect() async {
    if (_channel != null || _isConnecting) return;
    _isConnecting = true;
    _shouldReconnect = true;

    try {
      final token = await AuthService.instance.getSavedToken();
      if (token == null) {
        debugPrint('WebSocket (Customer): No token found. Skipping connection.');
        _isConnecting = false;
        return;
      }

      // Convert http://10.196.36.233:8000 to ws://10.196.36.233:8081
      final wsUrlBase = kBaseUrl.replaceFirst('http://', 'ws://').replaceFirst(':8000', ':8081');
      final uri = Uri.parse('$wsUrlBase?token=$token');
      debugPrint('WebSocket (Customer): Connecting to $uri');
      
      _channel = WebSocketChannel.connect(uri);
      _isConnecting = false;

      // Start pinging to keep connection alive
      _startHeartbeat();

      // Listen for incoming messages
      _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
          debugPrint('WebSocket (Customer) Error: $error');
          _handleDisconnect();
        },
        onDone: () {
          debugPrint('WebSocket (Customer) connection closed.');
          _handleDisconnect();
        },
      );
    } catch (e) {
      debugPrint('WebSocket (Customer): Connection failed: $e');
      _isConnecting = false;
      _handleDisconnect();
    }
  }

  /// Handle incoming message string
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message.toString()) as Map<String, dynamic>;
      
      // Handle pong message
      if (data['type'] == 'pong') {
        debugPrint('WebSocket (Customer): Received Pong');
        return;
      }

      _messageController.add(data);
    } catch (e) {
      debugPrint('WebSocket (Customer): Error parsing message: $e');
    }
  }

  /// Handle disconnection and schedule reconnect
  void _handleDisconnect() {
    _cleanupChannel();
    if (_shouldReconnect) {
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(const Duration(seconds: 4), () {
        debugPrint('WebSocket (Customer): Attempting to reconnect...');
        connect();
      });
    }
  }

  /// Start heartbeat timer
  void _startHeartbeat() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_channel != null) {
        try {
          debugPrint('WebSocket (Customer): Sending Ping');
          _channel!.sink.add(jsonEncode({'type': 'ping'}));
        } catch (e) {
          debugPrint('WebSocket (Customer): Ping failed: $e');
          _handleDisconnect();
        }
      }
    });
  }

  /// Clean up variables
  void _cleanupChannel() {
    _pingTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
  }

  /// Explicitly disconnect from WebSocket
  void disconnect() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _cleanupChannel();
    debugPrint('WebSocket (Customer): Manually disconnected.');
  }
}
