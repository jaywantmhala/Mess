// lib/services/websocket_service.dart
// Real-time service using official Ably SDK (ably_flutter) exclusively.
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:ably_flutter/ably_flutter.dart' as ably;
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'driver_auth_service.dart';
import '../utils/app_config.dart';
import '../utils/api_client.dart';

class WebSocketService {
  WebSocketService._();
  static final WebSocketService instance = WebSocketService._();

  static String get _ablyApiKey => kAblyApiKey;
  String get _channelName => kAblyChannelName;

  ably.Realtime? _realtime;
  Completer<ably.Realtime?>? _connectCompleter;
  final Map<String, StreamSubscription<ably.Message>> _ablySubscriptions = {};
  
  bool _isConnecting = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  /// Cached vendor ID — set before connect() is called from HomeShell
  int cachedVendorId = 0;
  int cachedDriverId = 0;
  String? currentRole;
  Timer? _pollingTimer;

  /// Vendor's active hotel IDs
  List<int> activeHotelIds = [];

  /// Active channel subscriptions set
  final Set<String> _subscribedChannelNames = {};

  /// Order deduplication cache (order_id -> timestamp)
  final Map<int, DateTime> _recentlyProcessedOrders = {};

  /// Check if order has been processed recently (prevents duplicate popups)
  bool isOrderAlreadyProcessed(int orderId) {
    if (orderId <= 0) return false;
    final lastTime = _recentlyProcessedOrders[orderId];
    if (lastTime != null) {
      if (DateTime.now().difference(lastTime) < const Duration(seconds: 60)) {
        return true;
      }
    }
    return false;
  }

  /// Mark order as processed to avoid duplicates between Ably & FCM
  void markOrderProcessed(int orderId) {
    if (orderId <= 0) return;
    _recentlyProcessedOrders[orderId] = DateTime.now();
    
    // Cleanup entries older than 2 minutes
    _recentlyProcessedOrders.removeWhere((id, time) => 
      DateTime.now().difference(time) > const Duration(minutes: 2));
  }

  // Stream controller to broadcast parsed incoming messages to UI listeners
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

  Future<void> connect({String? role}) async {
    if (role != null) {
      currentRole = role;
    }
    if (_realtime != null || _isConnecting) return;
    _isConnecting = true;

    if (kIsWeb) {
      debugPrint('🌐 [Ably Service] Flutter Web detected — ably_flutter native SDK is Android/iOS only. Activating HTTP Real-time Poller...');
      _isConnecting = false;
      _startFallbackPolling();
      return;
    }

    try {
      debugPrint('Ably Service: Initializing official Ably Realtime Client...');
      final clientOptions = ably.ClientOptions(key: _ablyApiKey)
        ..autoConnect = true;

      _realtime = ably.Realtime(options: clientOptions);

      _realtime!.connection.on().listen((stateChange) {
        debugPrint('Ably Service: Connection State Changed → ${stateChange.current}');
        if (stateChange.current == ably.ConnectionState.connected) {
          _resubscribeAllChannels();
        }
      });

      _isConnecting = false;
      debugPrint('Ably Service: Connected via official Ably SDK ✓');

      // Auto subscribe to the global events channel as default if no subscriptions exist
      subscribeToChannel(_channelName);
      if (currentRole == 'driver') {
        DriverAuthService.instance.getSavedDriver().then((d) {
          if (d != null && d.id > 0) {
            subscribeToDriver(d.id);
          }
        });
      }
    } catch (e) {
      _isConnecting = false;
      debugPrint('Ably Service: SDK Init Exception ($e)');
      _startFallbackPolling();
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
    debugPrint('Ably Service: Re-attaching all channels: $_subscribedChannelNames');
    for (final chName in List<String>.from(_subscribedChannelNames)) {
      _attachAndListenChannel(chName, forceReattach: true);
    }
  }

  // ── Subscriptions ──────────────────────────────────────────────────────────

  Future<void> subscribeToVendor(int vendorId) async {
    if (vendorId <= 0) return;
    cachedVendorId = vendorId;
    final ch1 = kVendorChannel(vendorId);
    final ch2 = "vendor_$vendorId";
    debugPrint('ABLY SUBSCRIBE $ch1');
    await subscribeToChannel(ch1);
    await subscribeToChannel(ch2);
  }

  Future<void> subscribeToDriver(int driverId) async {
    if (driverId <= 0) return;
    cachedDriverId = driverId;
    currentRole = 'driver';
    final ch1 = kDriverChannel(driverId);
    final ch2 = "driver_$driverId";
    debugPrint('ABLY SUBSCRIBE $ch1');
    await subscribeToChannel(ch1);
    await subscribeToChannel(ch2);
  }

  Future<void> subscribeToHotels(List<int> hotelIds) async {
    activeHotelIds = List.from(hotelIds);
    for (final hotelId in hotelIds) {
      final chName = kHotelOrdersChannel(hotelId);
      await subscribeToChannel(chName);
    }
  }

  Future<void> subscribeToChannel(String chName) async {
    _subscribedChannelNames.add(chName);
    if (kIsWeb) {
      _startFallbackPolling();
      return;
    }
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
      debugPrint('Ably Service: Attaching & subscribing SDK to channel "$chName"');
      final channel = _realtime!.channels.get(chName);
      await channel.attach();

      final sub = channel.subscribe().listen((ably.Message message) {
        _handleAblySdkMessage(message);
      }, onError: (error) {
        debugPrint('Ably Service: Stream Error on channel "$chName" — $error');
      });

      _ablySubscriptions[chName] = sub;
      debugPrint('Ably Service: Successfully subscribed to channel "$chName" ✓');
    } catch (e) {
      debugPrint('Ably Service: Failed subscribing to channel "$chName": $e');
      if (e.toString().contains('MissingPluginException') || kIsWeb) {
        _startFallbackPolling();
      }
    }
  }

  void _startFallbackPolling() {
    if (_pollingTimer != null && _pollingTimer!.isActive) return;
    debugPrint('⚡ [Ably Service] Instant Real-time Poller Activated (1s interval)...');

    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      try {
        if (currentRole == 'driver') {
          if (cachedDriverId <= 0) return;
          final token = await DriverAuthService.instance.getSavedToken();
          if (token == null || token.isEmpty) return;

          // kApiHost already ends with /api, so path is /driver/orders
          final url = Uri.parse('$kApiHost/driver/orders');
          final response = await http.get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'Connection': 'close',
            },
          ).timeout(const Duration(seconds: 2));

          debugPrint('⚡ [Poller] Driver GET $url → ${response.statusCode}');

          if (response.statusCode == 200) {
            final body = jsonDecode(response.body);
            if (body['success'] == true && body['data'] != null) {
              dynamic data = body['data'];
              List orders = [];
              if (data is List) {
                orders = data;
              } else if (data is Map && data['orders'] is List) {
                orders = data['orders'] as List;
              }

              for (final o in orders) {
                if (o is Map) {
                  final status = o['status']?.toString();
                  final orderId = int.tryParse((o['order_id'] ?? o['id'] ?? '').toString()) ?? 0;

                  // Driver checks for status == 'assigned'
                  if (status == 'assigned' && orderId > 0 && !isOrderAlreadyProcessed(orderId)) {
                    debugPrint('🔔 [Poller] Driver order #$orderId assigned! Triggering popup...');
                    markOrderProcessed(orderId);
                    
                    final payload = {
                      'order_id': orderId,
                      'driver_id': cachedDriverId,
                      'hotel_name': o['hotel_name'] ?? 'Restaurant',
                      'pickup_address': o['hotel_address'] ?? o['pickup_address'] ?? 'Hotel Pickup Location',
                      'drop_address': o['delivery_address'] ?? o['drop_address'] ?? 'Customer Delivery Address',
                      'pickup_distance': o['pickup_distance'] ?? 1.85,
                      'drop_distance': o['drop_distance'] ?? 4.25,
                    };
                    
                    _messageController.add({
                      'event': 'order_assigned',
                      'type': 'order_assigned',
                      'data': payload,
                    });
                    _checkAndPlayDriverAlert(payload);
                  }
                }
              }
            }
          }
        } else {
          // Vendor polling
          if (cachedVendorId <= 0) return;
          final token = await AuthService.instance.getSavedToken();
          if (token == null || token.isEmpty) return;

          // kApiHost already ends with /api, so path is /vendor/orders
          final url = Uri.parse('$kApiHost/vendor/orders');
          final response = await ApiClient.instance.get(url).timeout(const Duration(seconds: 10));

          debugPrint('⚡ [Poller] Vendor GET $url → ${response.statusCode}');

          if (response.statusCode == 200) {
            final body = jsonDecode(response.body);
            if (body['success'] == true && body['data'] != null) {
              dynamic data = body['data'];
              List orders = [];
              if (data is List) {
                orders = data;
              } else if (data is Map && data['orders'] is List) {
                orders = data['orders'] as List;
              }

              for (final o in orders) {
                if (o is Map) {
                  final status = o['status']?.toString();
                  final orderId = int.tryParse((o['order_id'] ?? o['id'] ?? '').toString()) ?? 0;

                  if (status == 'created_order' && orderId > 0 && !isOrderAlreadyProcessed(orderId)) {
                    debugPrint('🔔 [Poller] NEW ORDER #$orderId detected! Triggering popup + alarm...');
                    markOrderProcessed(orderId);
                    _messageController.add({
                      'event': 'new_order',
                      'type': 'new_order',
                      'data': o,
                    });
                    _checkAndPlayVendorAlert(o);
                  }
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Fallback Poller error: $e');
      }
    });
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
    debugPrint('Ably Service: Unsubscribed from channel "$chName"');
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
        eventData = dataPayload.map((e) => e is Map ? _deepConvertMap(e) : e).toList();
      }

      // Deduplicate identical events received within 2 seconds
      final orderIdStr = eventData is Map ? (eventData['order_id'] ?? eventData['id'] ?? '') : '';
      final orderId = int.tryParse(orderIdStr.toString()) ?? 0;
      if (orderId > 0 && isOrderAlreadyProcessed(orderId)) {
        debugPrint('⛔ [Ably Service] Suppressing duplicate SDK event for order #$orderId');
        return;
      }

      debugPrint('ABLY EVENT $event -> ORDER $orderId RECEIVED');
      debugPrint('⚡ [Ably Service] SDK Real-Time Event Received [$event] -> $eventData');

      if (event == 'new_order' || event == 'NEW_ORDER') {
        _checkAndPlayVendorAlert(eventData);
      } else if (event == 'order_assigned' || event == 'ORDER_ASSIGNED') {
        _checkAndPlayDriverAlert(eventData);
      } else if (event == 'order_updated' || event == 'ORDER_STATUS_UPDATED') {
        final status = eventData is Map ? eventData['status']?.toString() : null;
        if (status != 'assigned') {
          stopAlertSound();
        }
      } else if (event == 'ORDER_ACCEPTED' || event == 'DRIVER_ACCEPTED') {
        stopAlertSound();
      }

      _messageController.add({
        'event': event,
        'type': event,
        'data': eventData
      });
    } catch (e, stack) {
      debugPrint('Ably Service: SDK Error processing event: $e\n$stack');
    }
  }

  Map<String, dynamic> _deepConvertMap(Map map) {
    return map.map((k, v) {
      if (v is Map) {
        return MapEntry(k.toString(), _deepConvertMap(v));
      } else if (v is List) {
        return MapEntry(k.toString(), v.map((e) => e is Map ? _deepConvertMap(e) : e).toList());
      }
      return MapEntry(k.toString(), v);
    });
  }

  int extractVendorId(dynamic payload) {
    if (payload is! Map) return 0;
    final direct = payload['vendor_id'] ?? payload['vendorId'] ?? payload['v_id'];
    if (direct != null) {
      final parsed = int.tryParse(direct.toString());
      if (parsed != null && parsed > 0) return parsed;
    }
    if (payload['data'] is Map) {
      final nested = extractVendorId(payload['data']);
      if (nested > 0) return nested;
    }
    if (payload['order'] is Map) {
      final nested = extractVendorId(payload['order']);
      if (nested > 0) return nested;
    }
    return 0;
  }

  int extractHotelId(dynamic payload) {
    if (payload is! Map) return 0;
    final direct = payload['hotel_id'] ?? payload['hotelId'] ?? payload['h_id'];
    if (direct != null) {
      final parsed = int.tryParse(direct.toString());
      if (parsed != null && parsed > 0) return parsed;
    }
    if (payload['data'] is Map) {
      final nested = extractHotelId(payload['data']);
      if (nested > 0) return nested;
    }
    if (payload['order'] is Map) {
      final nested = extractHotelId(payload['order']);
      if (nested > 0) return nested;
    }
    return 0;
  }

  /// Play the notification alert sound
  Future<void> playAlertSound() async {
    try {
      debugPrint('Ably Service: Playing danger alert sound...');
      try {
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
      } catch (e) {
        debugPrint('Ably Service: AudioContext setting info: $e');
      }

      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.stop();
      
      try {
        await _audioPlayer.play(AssetSource('sound/danger_alert.mp3'));
      } catch (_) {
        await _audioPlayer.play(AssetSource('sounds/danger_alert.mp3'));
      }
      debugPrint('Ably Service: Played danger_alert.mp3 sound successfully.');
    } catch (e, stack) {
      debugPrint('Ably Service: Failed to play alert sound: $e\n$stack');
    }
  }

  Future<void> _checkAndPlayVendorAlert(dynamic eventData) async {
    try {
      final targetVendorId = extractVendorId(eventData);
      final targetHotelId  = extractHotelId(eventData);

      int myVendorId = cachedVendorId;
      if (myVendorId == 0) {
        final v = await AuthService.instance.getSavedVendor();
        myVendorId = v?.id ?? 0;
        cachedVendorId = myVendorId;
      }

      debugPrint('🔔 [Ably Service] Alert check: targetVendorId=$targetVendorId, myVendorId=$myVendorId, targetHotelId=$targetHotelId, activeHotelIds=$activeHotelIds');

      final bool isVendorMismatch = (myVendorId > 0 && targetVendorId > 0 && targetVendorId != myVendorId);
      final bool isHotelMismatch  = (targetHotelId > 0 && activeHotelIds.isNotEmpty && !activeHotelIds.contains(targetHotelId));

      if (!isVendorMismatch && !isHotelMismatch) {
        debugPrint('🔊 [Ably Service] Vendor & Hotel matched! Playing alert sound...');
        playAlertSound();
      } else {
        debugPrint('⛔ [Ably Service] Skipping alert sound: mismatch targetVendorId #$targetVendorId / hotel #$targetHotelId with vendor #$myVendorId / hotels $activeHotelIds');
      }
    } catch (e, stack) {
      debugPrint('Error checking vendor ID for alert sound: $e\n$stack');
    }
  }

  Future<void> _checkAndPlayDriverAlert(dynamic eventData) async {
    try {
      if (eventData is Map) {
        final assignedDriverId = int.tryParse(eventData['driver_id']?.toString() ?? '') ?? 0;
        final currentDriver = await DriverAuthService.instance.getSavedDriver();
        final currentDriverId = currentDriver?.id ?? 0;
        final bool isDriverMismatch = (currentDriverId > 0 && assignedDriverId > 0 && assignedDriverId != currentDriverId);

        if (!isDriverMismatch) {
          debugPrint('🔊 [Ably Service] Driver matched! Playing alert sound...');
          playAlertSound();
        } else {
          debugPrint('Skipping alert sound: ORDER_ASSIGNED target driver #$assignedDriverId != current driver #$currentDriverId');
        }
      }
    } catch (e) {
      debugPrint('Error checking driver ID for alert sound: $e');
    }
  }

  /// Stop the notification alert sound
  Future<void> stopAlertSound() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.release);
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('Ably Service: Failed to stop alert sound: $e');
    }
  }

  /// Transmit driver location
  Future<void> sendLocationUpdate(double lat, double lng) async {
    try {
      final token = await DriverAuthService.instance.getSavedToken();
      if (token == null || token.isEmpty) return;

      final url = Uri.parse('$kBaseUrl/../driver/location');
      await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'latitude': lat,
          'longitude': lng,
        }),
      );
    } catch (e) {
      debugPrint('Ably Service: Failed to transmit driver coordinates: $e');
    }
  }

  /// Stop and clean up all subscriptions
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
    debugPrint('Ably Service: Disconnected');
  }
}
