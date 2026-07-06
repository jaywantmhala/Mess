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
        debugPrint('WebSocket (Driver): No token found. Skipping connection.');
        _isConnecting = false;
        return;
      }

      // Convert http://10.196.36.233:8000 to ws://10.196.36.233:8081
      final wsUrlBase = kBaseUrl.replaceFirst('http://', 'ws://').replaceFirst(':8000', ':8081');
      final uri = Uri.parse('$wsUrlBase?token=$token');
      debugPrint('WebSocket (Driver): Connecting to $uri');
      
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
          debugPrint('WebSocket (Driver) Error: $error');
          _handleDisconnect();
        },
        onDone: () {
          debugPrint('WebSocket (Driver) connection closed.');
          _handleDisconnect();
        },
      );
    } catch (e) {
      debugPrint('WebSocket (Driver): Connection failed: $e');
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
        debugPrint('WebSocket (Driver): Received Pong');
        return;
      }

      // Play alert sound when vendor assigns an order to THIS driver
      final event = data['event'] as String?;
      if (event == 'ORDER_ASSIGNED') {
        debugPrint('WebSocket (Driver): ORDER_ASSIGNED received! Playing alert...');
        _playAlertSound();
      }

      _messageController.add(data);
    } catch (e) {
      debugPrint('WebSocket (Driver): Error parsing message: $e');
    }
  }

  /// Play the looping alert sound to notify driver of new assignment
  Future<void> _playAlertSound() async {
    try {
      debugPrint('WebSocket (Driver): Playing assignment alert sound...');
      await _audioPlayer.setAudioContext(AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.alarm,
          audioFocus: AndroidAudioFocus.gainTransient,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
      ));
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.stop();
      await _audioPlayer.setSource(AssetSource('sounds/success.mp3'));
      await _audioPlayer.resume();
      debugPrint('WebSocket (Driver): Alert sound playing.');
    } catch (e, stack) {
      debugPrint('WebSocket (Driver): Failed to play alert sound: $e\n$stack');
    }
  }

  /// Stop the alert sound (called when driver acknowledges the assignment)
  Future<void> stopAlertSound() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.release);
      await _audioPlayer.stop();
      debugPrint('WebSocket (Driver): Stopped alert sound.');
    } catch (e) {
      debugPrint('WebSocket (Driver): Failed to stop alert sound: $e');
    }
  }

  /// Handle disconnection and schedule reconnect
  void _handleDisconnect() {
    _cleanupChannel();
    if (_shouldReconnect) {
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(const Duration(seconds: 4), () {
        debugPrint('WebSocket (Driver): Attempting to reconnect...');
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
          debugPrint('WebSocket (Driver): Sending Ping');
          _channel!.sink.add(jsonEncode({'type': 'ping'}));
        } catch (e) {
          debugPrint('WebSocket (Driver): Ping failed: $e');
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
    debugPrint('WebSocket (Driver): Manually disconnected.');
  }
}
