import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/app_config.dart';
import 'auth_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print("FCM Background message: ${message.messageId}");
  }
}

class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  FirebaseMessaging? _fcm;

  Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      await Firebase.initializeApp();
      _fcm = FirebaseMessaging.instance;
      
      // Set background messaging handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Request permission
      await _requestPermission();

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print("FCM Foreground message: ${message.notification?.title} - ${message.notification?.body}");
        }
        // Foreground UI alert could be triggered here if desired
      });

      // Handle notification clicks when app is in background but still in memory
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) {
          print("FCM Notification clicked: ${message.data}");
        }
      });

      // Handle notification clicks that opened app from fully terminated state
      final initialMessage = await _fcm!.getInitialMessage();
      if (initialMessage != null) {
        if (kDebugMode) {
          print("FCM App opened from terminated: ${initialMessage.data}");
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
  }

  Future<void> registerToken([String? token]) async {
    if (kIsWeb || _fcm == null) return;
    try {
      final fcmToken = token ?? await _fcm!.getToken();
      if (fcmToken == null) return;

      final userToken = await AuthService.instance.getSavedToken();
      if (userToken == null) {
        if (kDebugMode) {
          print("FCM: No active session. Registration deferred.");
        }
        return;
      }

      final url = Uri.parse('$kBaseUrl/api/auth/update_fcm_token');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
        body: jsonEncode({'fcm_token': fcmToken}),
      );

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
