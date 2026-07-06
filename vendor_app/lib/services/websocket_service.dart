// lib/services/websocket_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:audioplayers/audioplayers.dart';
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

  final AudioPlayer _audioPlayer = AudioPlayer();

  // Stream controller to broadcast parsed incoming messages to UI listeners
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
        debugPrint('WebSocket: No token found. Skipping connection.');
        _isConnecting = false;
        return;
      }

      final uri = Uri.parse('$kWebSocketUrl?token=$token');
      debugPrint('WebSocket: Connecting to $uri');
      
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
          debugPrint('WebSocket Error: $error');
          _handleDisconnect();
        },
        onDone: () {
          debugPrint('WebSocket connection closed.');
          _handleDisconnect();
        },
      );
    } catch (e) {
      debugPrint('WebSocket: Connection failed: $e');
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
        debugPrint('WebSocket: Received Pong');
        return;
      }

      // Handle custom events
      final event = data['event'] as String?;
      if (event == 'NEW_ORDER') {
        // Automatically play the danger notification sound!
        _playAlertSound();
      }

      _messageController.add(data);
    } catch (e) {
      debugPrint('WebSocket: Error parsing message: $e');
    }
  }

  /// Play the notification alert sound
  Future<void> _playAlertSound() async {
    try {
      debugPrint('WebSocket: Attempting to play alert sound...');
      // Set audio context to force speaker/out loud
      await _audioPlayer.setAudioContext(AudioContext(
        android: const AudioContextAndroid(),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {
            AVAudioSessionOptions.mixWithOthers,
          },
        ),
      ));
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.stop();
      // Using sound/danger_alert.mp3 since it matches assets/sound/danger_alert.mp3
      await _audioPlayer.setSource(AssetSource('sound/danger_alert.mp3'));
      await _audioPlayer.resume();
      debugPrint('WebSocket: Played alert sound successfully.');
    } catch (e, stack) {
      debugPrint('WebSocket: Failed to play alert sound: $e\n$stack');
    }
  }

  /// Handle disconnection and schedule reconnect
  void _handleDisconnect() {
    _cleanupChannel();
    if (_shouldReconnect) {
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(const Duration(seconds: 4), () {
        debugPrint('WebSocket: Attempting to reconnect...');
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
          debugPrint('WebSocket: Sending Ping');
          _channel!.sink.add(jsonEncode({'type': 'ping'}));
        } catch (e) {
          debugPrint('WebSocket: Ping failed: $e');
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
    debugPrint('WebSocket: Manually disconnected.');
  }
}
