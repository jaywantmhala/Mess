// lib/services/ably_service.dart
// Real-time service using official Ably SDK (ably_flutter) exclusively.
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:ably_flutter/ably_flutter.dart' as ably;
import 'package:audioplayers/audioplayers.dart';
import '../utils/app_config.dart';

class AblyService {
  AblyService._();
  static final AblyService instance = AblyService._();

  static String get _ablyApiKey => kAblyApiKey;
  String get _channelName => kAblyChannelName;

  ably.Realtime? _realtime;
  Completer<ably.Realtime?>? _connectCompleter;
  final Map<String, StreamSubscription<ably.Message>> _ablySubscriptions = {};
  
  bool _isConnecting = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Set<String> _subscribedChannelNames = {};

  // Broadcast stream of parsed incoming Ably messages
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  bool get isConnected =>
      _realtime != null &&
      _realtime!.connection.state == ably.ConnectionState.connected;

  // ── Connection Management ──────────────────────────────────────────────────

  Future<ably.Realtime?> getRealtimeClient() async {
    if (_realtime != null) return _realtime;
    if (_connectCompleter != null) return _connectCompleter!.future;

    _connectCompleter = Completer<ably.Realtime?>();
    try {
      await connect();
      _connectCompleter!.complete(_realtime);
    } catch (e) {
      _connectCompleter!.complete(null);
    } finally {
      _connectCompleter = null;
    }
    return _realtime;
  }

  Future<void> connect() async {
    if (_realtime != null || _isConnecting) return;
    if (kIsWeb) return;
    _isConnecting = true;

    try {
      debugPrint('AblyService: Initializing official Ably Realtime Client...');
      final clientOptions = ably.ClientOptions(key: _ablyApiKey)
        ..autoConnect = true;

      _realtime = ably.Realtime(options: clientOptions);

      _realtime!.connection.on().listen((stateChange) {
        debugPrint('AblyService: Connection State Changed → ${stateChange.current}');
        if (stateChange.current == ably.ConnectionState.connected) {
          _resubscribeAllChannels();
        }
      });

      _isConnecting = false;
      debugPrint('AblyService: Connected via official Ably SDK ✓');

      // Auto subscribe to the global events channel as default
      subscribeToChannel(_channelName);
    } catch (e) {
      _isConnecting = false;
      debugPrint('AblyService: SDK Init Exception ($e)');
    }
  }

  Future<void> _waitForConnection() async {
    if (_realtime == null) return;
    if (_realtime!.connection.state == ably.ConnectionState.connected) {
      return;
    }

    final completer = Completer<void>();
    late StreamSubscription sub;
    Timer? timer;

    timer = Timer(const Duration(seconds: 5), () {
      sub.cancel();
      if (!completer.isCompleted) completer.complete();
    });

    sub = _realtime!.connection.on().listen((stateChange) {
      if (stateChange.current == ably.ConnectionState.connected) {
        timer?.cancel();
        sub.cancel();
        if (!completer.isCompleted) completer.complete();
      }
    });

    await completer.future;
  }

  void _resubscribeAllChannels() {
    debugPrint('AblyService: Re-attaching all channels: $_subscribedChannelNames');
    for (final chName in List<String>.from(_subscribedChannelNames)) {
      _attachAndListenChannel(chName, forceReattach: true);
    }
  }

  // ── Subscriptions ──────────────────────────────────────────────────────────

  Future<void> subscribeToChannel(String chName) async {
    _subscribedChannelNames.add(chName);
    await getRealtimeClient();
    await _waitForConnection();
    await _attachAndListenChannel(chName);
  }

  Future<void> _attachAndListenChannel(String chName, {bool forceReattach = false}) async {
    if (_realtime == null) return;
    
    if (_ablySubscriptions.containsKey(chName)) {
      if (!forceReattach) return;
      try {
        _ablySubscriptions[chName]?.cancel();
      } catch (_) {}
      _ablySubscriptions.remove(chName);
    }

    try {
      debugPrint('AblyService: Attaching & subscribing SDK to channel "$chName"');
      final channel = _realtime!.channels.get(chName);
      await channel.attach();

      final sub = channel.subscribe().listen((ably.Message message) {
        _handleAblySdkMessage(message);
      }, onError: (error) {
        debugPrint('AblyService: Stream Error on channel "$chName" — $error');
      });

      _ablySubscriptions[chName] = sub;
      debugPrint('AblyService: Successfully subscribed to channel "$chName" ✓');
    } catch (e) {
      debugPrint('AblyService: Failed subscribing to channel "$chName": $e');
    }
  }

  void unsubscribeFromChannel(String chName) {
    _subscribedChannelNames.remove(chName);
    final sub = _ablySubscriptions.remove(chName);
    sub?.cancel();
    if (_realtime != null) {
      try {
        _realtime!.channels.get(chName).detach();
      } catch (_) {}
    }
    debugPrint('AblyService: Unsubscribed from channel "$chName"');
  }

  Stream<Map<String, dynamic>> subscribe([String? channelName]) {
    if (channelName != null) {
      subscribeToChannel(channelName);
    } else {
      connect();
    }
    return messages;
  }

  void subscribeToOrder(int orderId) {
    if (orderId <= 0) return;
    final ch1 = kOrderChannel(orderId);
    final ch2 = "order_$orderId";
    debugPrint('ABLY SUBSCRIBE $ch1');
    subscribeToChannel(ch1);
    subscribeToChannel(ch2);
  }

  // ── SDK Event Processing ───────────────────────────────────────────────────

  void _handleAblySdkMessage(ably.Message msg) {
    try {
      final messageName = msg.name;
      dynamic dataPayload = msg.data;

      if (dataPayload is String) {
        try {
          dataPayload = jsonDecode(dataPayload);
        } catch (_) {}
      }

      String? event = messageName;
      dynamic eventData = dataPayload;

      if (dataPayload is Map) {
        final map = _deepConvertMap(dataPayload);
        event = (map['event'] ?? messageName) as String?;
        eventData = map['data'] ?? map;
      } else if (dataPayload is List) {
        eventData = dataPayload
            .map((e) => e is Map ? _deepConvertMap(e) : e)
            .toList();
      }

      debugPrint('AblyService: SDK Event [$event] → $eventData');

      if (event == 'order_updated' ||
          event == 'ORDER_STATUS_UPDATED' ||
          event == 'ORDER_ACCEPTED' ||
          event == 'DRIVER_ACCEPTED') {
        stopAlertSound();
      }

      final msgEvent = {
        'event': event,
        'type': (event == 'order_updated' || event == 'ORDER_STATUS_UPDATED') ? 'order_status_update' : event,
        'data': eventData,
      };
      debugPrint('AblyService: Adding event to _messageController stream: $msgEvent');
      _messageController.add(msgEvent);
    } catch (e, stack) {
      debugPrint('AblyService: SDK Event processing error — $e\n$stack');
    }
  }

  Map<String, dynamic> _deepConvertMap(Map map) {
    return map.map((k, v) {
      if (v is Map) return MapEntry(k.toString(), _deepConvertMap(v));
      if (v is List) {
        return MapEntry(
          k.toString(),
          v.map((e) => e is Map ? _deepConvertMap(e) : e).toList(),
        );
      }
      return MapEntry(k.toString(), v);
    });
  }

  // ── Alert Sound ───────────────────────────────────────────────────────────

  bool _isPlayingAlertSound = false;

  Future<void> playAlertSound() async {
    try {
      _isPlayingAlertSound = true;
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
      if (!_isPlayingAlertSound) return;
      await _audioPlayer.play(AssetSource('sounds/danger_alert.mp3'));
      debugPrint('AblyService: Playing alert sound');
    } catch (e) {
      debugPrint('AblyService: Failed to play alert sound — $e');
    }
  }

  Future<void> stopAlertSound() async {
    try {
      _isPlayingAlertSound = false;
      await _audioPlayer.setReleaseMode(ReleaseMode.release);
      await _audioPlayer.stop();
      debugPrint('AblyService: Alert sound stopped');
    } catch (e) {
      debugPrint('AblyService: Failed to stop alert sound — $e');
    }
  }

  // ── Disconnect ─────────────────────────────────────────────────────────────

  void disconnect() {
    for (final sub in _ablySubscriptions.values) {
      try {
        sub.cancel();
      } catch (_) {}
    }
    _ablySubscriptions.clear();
    _subscribedChannelNames.clear();
    try {
      _realtime?.close();
    } catch (_) {}
    _realtime = null;
    _isConnecting = false;
    debugPrint('AblyService: Disconnected');
  }
}
