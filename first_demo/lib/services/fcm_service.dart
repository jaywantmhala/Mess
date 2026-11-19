import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../utils/app_config.dart';
import 'auth_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print("FCM Background message: ${message.messageId}");
  }

  // If message already has a system notification payload, Android system handles display
  if (message.notification != null) return;

  final data = message.data;
  final title = data['title'] as String? ?? 'Hungrily Notification';
  final body = data['body'] as String? ?? 'You have a new update.';

  final plugin = FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
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
      ?? data['image'] as String?;
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

  await plugin.show(
    notifId,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        importance: Importance.max,
        priority: Priority.high,
        tag: orderId != null ? 'hungrily_order_$orderId' : null,
        color: const Color(0xFFFF6B35),
        styleInformation: styleInformation,
      ),
    ),
    payload: jsonEncode(data),
  );
}

class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  FirebaseMessaging? _fcm;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static const MethodChannel _platformChannel = MethodChannel('com.zenqube.hungrilyfoods/notifications');

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
      
      // Set background messaging handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Request permission
      await _requestPermission();

      // Initialize Local Notifications for foreground
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
      
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final payload = response.payload;
          if (payload != null) {
            try {
              final Map<String, dynamic> data = jsonDecode(payload);
              _handleNotificationTap(data);
            } catch (e) {
              debugPrint('Error parsing notification tap payload: $e');
            }
          }
        },
      );

      _platformChannel.setMethodCallHandler((call) async {
        if (call.method == 'onNotificationTap') {
          final orderId = call.arguments as String?;
          if (orderId != null) {
            _handleNotificationTap({'order_id': orderId});
          }
        }
      });

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        final title = message.data['title'] as String?
            ?? message.notification?.title;
        final body = message.data['body'] as String?
            ?? message.notification?.body;
        if (title != null || body != null) {
          if (kDebugMode) {
            print("FCM Foreground message: $title - $body");
          }
          
          final status = message.data['status'] as String?;
          final progress = _getProgressFromStatus(status ?? '');
          final showProgress = progress > 0 && progress < 100;
          final orderIdStr = message.data['order_id'];

          String? otp = message.data['otp'] as String?;
          if (otp == null || otp.isEmpty) {
            final match = RegExp(r'\b\d{4}\b').firstMatch(body ?? '');
            if (match != null) {
              otp = match.group(0);
            }
          }

          final isOrderNotification = status != null || orderIdStr != null;

          if (isOrderNotification && !kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
            try {
              await _platformChannel.invokeMethod('showCustomNotification', {
                'orderId': orderIdStr ?? '0',
                'title': _getStatusTitle(status ?? ''),
                'body': body ?? '',
                'otp': otp,
              });
              return; // Shown successfully via custom native layout
            } catch (e) {
              debugPrint('Error showing custom native notification: $e');
            }
          }

          // Fallback if platform channel fails, or if it's a broadcast notification
          final int notificationId = orderIdStr != null
              ? (int.tryParse(orderIdStr.toString()) ?? (title ?? '').hashCode)
              : (title ?? '').hashCode;
          final statusTitle = isOrderNotification ? _getStatusTitle(status ?? '') : (title ?? 'Hungrily Notification');

          final imageUrl = message.data['image_url'] as String?
              ?? message.data['image'] as String?
              ?? message.notification?.android?.imageUrl;
          StyleInformation styleInfo = BigTextStyleInformation(
            body ?? '',
            contentTitle: statusTitle,
            htmlFormatBigText: false,
          );

          if (imageUrl != null && imageUrl.isNotEmpty && (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'))) {
            try {
              final response = await http.get(Uri.parse(imageUrl)).timeout(const Duration(seconds: 8));
              if (response.statusCode == 200 && response.bodyBytes.lengthInBytes < (5 * 1024 * 1024)) {
                final bigPicture = ByteArrayAndroidBitmap(response.bodyBytes);
                styleInfo = BigPictureStyleInformation(
                  bigPicture,
                  contentTitle: statusTitle,
                  summaryText: body,
                  hideExpandedLargeIcon: true,
                );
              }
            } catch (_) {}
          }

          _localNotifications.show(
            notificationId,
            statusTitle,
            body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                _channel.id,
                _channel.name,
                channelDescription: _channel.description,
                icon: '@mipmap/ic_launcher',
                largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
                importance: Importance.max,
                priority: Priority.high,
                tag: orderIdStr != null ? 'hungrily_order_$orderIdStr' : null,
                showProgress: showProgress,
                maxProgress: 100,
                progress: progress,
                indeterminate: false,
                color: const Color(0xFFFF6B35),
                styleInformation: styleInfo,
                subText: 'Hungrily · Meals on Wheels',
                ticker: statusTitle,
                onlyAlertOnce: false,
              ),
            ),
            payload: jsonEncode(message.data),
          );
        }
      });

      // Handle notification clicks when app is in background but still in memory
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) {
          print("FCM Notification clicked: ${message.data}");
        }
        _handleNotificationTap(message.data);
      });

      // Handle notification clicks that opened app from fully terminated state
      final initialMessage = await _fcm!.getInitialMessage();
      if (initialMessage != null) {
        if (kDebugMode) {
          print("FCM App opened from terminated: ${initialMessage.data}");
        }
        _handleNotificationTap(initialMessage.data);
      }

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        try {
          final String? initialOrderId = await _platformChannel.invokeMethod<String>('checkInitialNotification');
          if (initialOrderId != null && initialOrderId.isNotEmpty) {
            Future.delayed(const Duration(milliseconds: 600), () {
              _handleNotificationTap({'order_id': initialOrderId});
            });
          }
        } catch (e) {
          debugPrint('Error checking initial custom notification: $e');
        }
      }

      // Automatically register token when generated/refreshed
      _fcm!.onTokenRefresh.listen((String token) {
        registerToken(token);
      });
      
      // Initial registration check
      final token = await _fcm!.getToken();
      if (token != null) {
        registerToken(token);
      }
    } catch (e) {
      if (kDebugMode) {
        print("FCM Initialization error: $e");
      }
    }
  }

  int _getProgressFromStatus(String status) {
    switch (status) {
      case 'created_order':
        return 15;
      case 'accepted':
        return 35;
      case 'preparing':
        return 60;
      case 'ready':
        return 85;
      case 'completed':
        return 100;
      default:
        return 0;
    }
  }

  String _getStatusTitle(String status) {
    switch (status) {
      case 'created_order':
        return '🎉 Order Placed!';
      case 'accepted':
        return '✅ Order Accepted!';
      case 'preparing':
        return '👨\u200d🍳 Chef is Cooking!';
      case 'ready':
        return '🛵 Out for Delivery!';
      case 'completed':
        return '🎊 Order Delivered!';
      default:
        return '📦 Order Updated!';
    }
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    if (kDebugMode) {
      print('FCM: Notification tapped, app opened cleanly: $data');
    }
  }

  Future<void> _requestPermission() async {
    if (_fcm == null) return;
    NotificationSettings settings = await _fcm!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (kDebugMode) {
      print('FCM User granted permission: ${settings.authorizationStatus}');
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final androidPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        final granted = await androidPlugin?.requestNotificationsPermission();
        if (kDebugMode) {
          print('FCM: Android local notifications permission granted: $granted');
        }
      } catch (e) {
        if (kDebugMode) {
          print('FCM: Error requesting Android notifications permission: $e');
        }
      }
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

  Future<void> registerToken([String? token]) async {
    if (kIsWeb) return;
    try {
      final fcmToken = token ?? await getToken();
      if (fcmToken == null || fcmToken.isEmpty) return;

      String? userToken = await AuthService.instance.getSavedToken();
      if (userToken == null || userToken.isEmpty) {
        if (kDebugMode) {
          print("FCM: No active session. Registration deferred.");
        }
        return;
      }

      final url = Uri.parse('$kBaseUrl/api/auth/update_fcm_token');
      var response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
        body: jsonEncode({'fcm_token': fcmToken}),
      );

      // If token expired (401), refresh token and retry
      if (response.statusCode == 401) {
        final refreshed = await AuthService.instance.refreshAccessToken();
        if (refreshed != null && refreshed.isNotEmpty) {
          userToken = refreshed;
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
        print("FCM register response: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      if (kDebugMode) {
        print("FCM register error: $e");
      }
    }
  }
}
