import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'driver_auth_service.dart';
import 'websocket_service.dart';
import 'vendor_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_config.dart';

// ─── Background handler (top-level, outside any class) ─────────────────────
// Runs when the app is terminated or in background.
// Must show the notification manually since no Flutter UI exists.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final data = message.data;
  final title = data['title'] as String?
      ?? message.notification?.title
      ?? 'Hungrily Notification';
  final body = data['body'] as String?
      ?? message.notification?.body
      ?? 'You have a new update.';

  final plugin = FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings('ic_notification');
  await plugin.initialize(const InitializationSettings(android: androidSettings));

  const channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
  );
  await plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  final orderId = data['order_id'] as String?;
  final notifId = (orderId != null ? int.tryParse(orderId) : null)
      ?? ((message.messageId?.hashCode ?? title.hashCode) & 0x7FFFFFFF);

  final imageUrl = data['image_url'] as String?
      ?? data['image'] as String?
      ?? message.notification?.android?.imageUrl;
  StyleInformation styleInformation = BigTextStyleInformation(body);

  if (imageUrl != null && imageUrl.isNotEmpty && (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'))) {
    try {
      final response = await http.get(Uri.parse(imageUrl)).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200 && response.bodyBytes.lengthInBytes < (5 * 1024 * 1024)) {
        final bigPicture = ByteArrayAndroidBitmap(response.bodyBytes);
        styleInformation = BigPictureStyleInformation(
          bigPicture,
          contentTitle: title,
          summaryText: body,
          hideExpandedLargeIcon: true,
        );
      }
    } catch (_) {}
  }

  List<AndroidNotificationAction>? actions;
  final actionButtonsRaw = data['action_buttons'];
  if (actionButtonsRaw != null && actionButtonsRaw.toString().isNotEmpty) {
    try {
      final decoded = jsonDecode(actionButtonsRaw.toString());
      if (decoded is List) {
        actions = [];
        for (int i = 0; i < decoded.length; i++) {
          final btn = decoded[i];
          if (btn is Map && btn['title'] != null) {
            final actionKey = btn['action']?.toString() ?? 'OPEN_APP';
            actions.add(
              AndroidNotificationAction(
                'action_${actionKey}_$i',
                btn['title'].toString(),
                showsUserInterface: true,
                cancelNotification: true,
              ),
            );
          }
        }
      }
    } catch (_) {}
  }

  await plugin.show(
    notifId,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        icon: 'ic_notification',
        importance: Importance.max,
        priority: Priority.high,
        tag: orderId != null ? 'vendor_order_$orderId' : null,
        color: const Color(0xFFFF6B35),
        styleInformation: styleInformation,
        actions: actions,
      ),
    ),
    payload: jsonEncode(data),
  );
}

class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  FirebaseMessaging? _fcm;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
  );

  Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      await Firebase.initializeApp();
      _fcm = FirebaseMessaging.instance;

      // Register background handler FIRST before anything else
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      await _requestPermission();

      // Tell FCM to deliver data-only messages even when the app is in background
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Initialize local notifications for foreground display
      const androidSettings = AndroidInitializationSettings('ic_notification');
      const initSettings = InitializationSettings(android: androidSettings);

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final payload = response.payload;
          if (payload != null) {
            try {
              final data = jsonDecode(payload) as Map<String, dynamic>;
              _handleNotificationTap(data, actionId: response.actionId);
            } catch (e) {
              debugPrint('FCM: Error parsing notification tap payload: $e');
            }
          }
        },
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      // ── FOREGROUND: app is open ────────────────────────────────────────────
      // FIX: Backend sends data-only messages. Read from message.data, NOT
      // message.notification (which will always be null for data-only pushes).
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        final data   = message.data;
        // Prefer fields from data payload; fall back to RemoteNotification if present
        final title  = data['title'] as String?
            ?? message.notification?.title
            ?? 'Hungrily Notification';
        final body   = data['body']  as String?
            ?? message.notification?.body
            ?? 'You have a new update.';
        final orderId = data['order_id'] as String?;
        final hotelIdStr = data['hotel_id'] as String?;
        final hotelId = hotelIdStr != null ? int.tryParse(hotelIdStr) : null;
        final activeHotels = WebSocketService.instance.activeHotelIds;

        if (hotelId != null && hotelId > 0 && activeHotels.isNotEmpty && !activeHotels.contains(hotelId)) {
          if (kDebugMode) {
            print('FCM [Foreground]: Suppressing notification for hotel #$hotelId (not in activeHotels $activeHotels)');
          }
          return;
        }

        final parsedOrderId = orderId != null ? int.tryParse(orderId) : null;
        if (parsedOrderId != null && parsedOrderId > 0 && WebSocketService.instance.isOrderAlreadyProcessed(parsedOrderId)) {
          if (kDebugMode) {
            print('FCM [Foreground]: Suppressing duplicate notification for order #$parsedOrderId');
          }
          return;
        }

        if (kDebugMode) {
          print('FCM [Foreground] title=$title body=$body orderId=$orderId hotelId=$hotelId');
        }

        final notifId = (orderId != null ? int.tryParse(orderId) : null)
            ?? ((message.messageId?.hashCode ?? title.hashCode) & 0x7FFFFFFF);

        final imageUrl = data['image_url'] as String?
            ?? data['image'] as String?
            ?? message.notification?.android?.imageUrl;
        StyleInformation styleInformation = BigTextStyleInformation(body);

        if (imageUrl != null && imageUrl.isNotEmpty && (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'))) {
          try {
            final response = await http.get(Uri.parse(imageUrl)).timeout(const Duration(seconds: 8));
            if (response.statusCode == 200 && response.bodyBytes.lengthInBytes < (5 * 1024 * 1024)) {
              final bigPicture = ByteArrayAndroidBitmap(response.bodyBytes);
              styleInformation = BigPictureStyleInformation(
                bigPicture,
                contentTitle: title,
                summaryText: body,
                hideExpandedLargeIcon: true,
              );
            }
          } catch (e) {
            if (kDebugMode) {
              print('FCM [Foreground]: Error fetching banner image: $e');
            }
          }
        }

        List<AndroidNotificationAction>? actions;
        final actionButtonsRaw = data['action_buttons'];
        if (actionButtonsRaw != null && actionButtonsRaw.toString().isNotEmpty) {
          try {
            final decoded = jsonDecode(actionButtonsRaw.toString());
            if (decoded is List) {
              actions = [];
              for (int i = 0; i < decoded.length; i++) {
                final btn = decoded[i];
                if (btn is Map && btn['title'] != null) {
                  final actionKey = btn['action']?.toString() ?? 'OPEN_APP';
                  actions.add(
                    AndroidNotificationAction(
                      'action_${actionKey}_$i',
                      btn['title'].toString(),
                      showsUserInterface: true,
                      cancelNotification: true,
                    ),
                  );
                }
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('FCM [Foreground]: Error parsing action buttons: $e');
            }
          }
        }

        _localNotifications.show(
          notifId,
          title,
          body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: 'ic_notification',
              importance: Importance.max,
              priority: Priority.high,
              tag: orderId != null ? 'vendor_order_$orderId' : null,
              color: const Color(0xFFFF6B35),
              styleInformation: styleInformation,
              actions: actions,
            ),
          ),
          payload: jsonEncode(data),
        );

        VendorNotificationService.instance.refreshUnreadCount();
      });

      // ── BACKGROUND tap: app in background, user taps notification ──────────
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('FCM [Background tap]: ${message.data}');
        }
        _handleNotificationTap(message.data);
      });

      // ── TERMINATED tap: user taps notification that launched the app ───────
      final initialMessage = await _fcm!.getInitialMessage();
      if (initialMessage != null) {
        if (kDebugMode) {
          print('FCM [Terminated tap]: ${initialMessage.data}');
        }
        // Slight delay to allow the widget tree to mount
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleNotificationTap(initialMessage.data);
        });
      }

      // ── Token registration ─────────────────────────────────────────────────
      _fcm!.onTokenRefresh.listen((String token) {
        _registerForActiveRole(token);
      });

      final token = await _fcm!.getToken();
      if (token != null) {
        if (kDebugMode) print('FCM Token: $token');
        _registerForActiveRole(token);
      }
    } catch (e) {
      if (kDebugMode) {
        print('FCM Initialization error: $e');
      }
    }
  }

  void _handleNotificationTap(Map<String, dynamic> data, {String? actionId}) {
    VendorNotificationService.instance.refreshUnreadCount();
    if (kDebugMode) {
      print('FCM: Notification tapped, app opened cleanly: $data (action: $actionId)');
    }
  }

  Future<void> _requestPermission() async {
    if (_fcm == null) return;
    final settings = await _fcm!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (kDebugMode) {
      print('FCM permission: ${settings.authorizationStatus}');
    }

    // Explicitly request notification permission for Android 13+ (API 33+)
    try {
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
    } catch (e) {
      if (kDebugMode) {
        print('Android local notifications permission request error: $e');
      }
    }
  }

  /// Determines the active role (vendor or driver) and registers the FCM token.
  Future<void> _registerForActiveRole([String? token]) async {
    final prefs = await SharedPreferences.getInstance();
    final activeRole = prefs.getString('active_role');

    if (activeRole == 'driver') {
      final isDriver = await DriverAuthService.instance.isLoggedIn();
      if (isDriver) {
        await registerToken('driver', token);
        return;
      }
    } else if (activeRole == 'vendor') {
      final isVendor = await AuthService.instance.isLoggedIn();
      if (isVendor) {
        await registerToken('vendor', token);
        return;
      }
    }

    // Fallback: register whichever role is currently logged in
    final isDriver = await DriverAuthService.instance.isLoggedIn();
    if (isDriver) {
      await registerToken('driver', token);
    }
    final isVendor = await AuthService.instance.isLoggedIn();
    if (isVendor) {
      await registerToken('vendor', token);
    }
  }

  Future<String?> getToken() async {
    if (kIsWeb) return null;
    try {
      if (_fcm != null) {
        return await _fcm!.getToken();
      }
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }

  /// Registers [token] (or fetches current token if null) against the given [role]
  /// endpoint on the backend.
  Future<void> registerToken(String role, [String? token]) async {
    if (kIsWeb) return;
    try {
      final fcmToken = token ?? await getToken();
      if (fcmToken == null || fcmToken.isEmpty) return;

      String? userToken;
      String endpointPath = '';

      if (role == 'vendor') {
        userToken = await AuthService.instance.getSavedToken();
        endpointPath = '/api/vendor/update_fcm_token';
      } else if (role == 'driver') {
        userToken = await DriverAuthService.instance.getSavedToken();
        endpointPath = '/api/driver/update_fcm_token';
      }

      if (userToken == null || userToken.isEmpty) {
        if (kDebugMode) {
          print('FCM: No active session for role=$role. Token registration deferred.');
        }
        return;
      }

      final url = Uri.parse('$kApiHost${endpointPath.replaceFirst('/api', '')}');
      var response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
        body: jsonEncode({'fcm_token': fcmToken}),
      );

      // If token expired (401), try to refresh token and retry (vendor only)
      if (response.statusCode == 401 && role == 'vendor') {
        final refreshedToken = await AuthService.instance.refreshAccessToken();
        if (refreshedToken != null && refreshedToken.isNotEmpty) {
          userToken = refreshedToken;
          response = await http.post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $userToken',
            },
            body: jsonEncode({'fcm_token': fcmToken}),
          );
        }
      }

      if (kDebugMode) {
        print('FCM registerToken ($role): ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('FCM registerToken ($role) error: $e');
      }
    }
  }
}
