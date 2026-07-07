import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'driver_auth_service.dart';

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
  
  // Base URL of the API server (use 10.0.2.2 for emulator, 127.0.0.1 or actual IP for desktop)
  static const String _apiBase = 'http://127.0.0.1:8000';

  Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      await Firebase.initializeApp();
      _fcm = FirebaseMessaging.instance;
      
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      await _requestPermission();

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print("FCM Foreground message: ${message.notification?.title} - ${message.notification?.body}");
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) {
          print("FCM Notification clicked: ${message.data}");
        }
      });

      _fcm!.onTokenRefresh.listen((String token) {
        _registerForActiveRole(token);
      });
      
      final token = await _fcm!.getToken();
      if (token != null) {
        _registerForActiveRole(token);
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

  Future<void> _registerForActiveRole(String token) async {
    final isVendor = await AuthService.instance.isLoggedIn();
    if (isVendor) {
      await registerToken('vendor', token);
      return;
    }
    
    final isDriver = await DriverAuthService.instance.isLoggedIn();
    if (isDriver) {
      await registerToken('driver', token);
    }
  }

  Future<void> registerToken(String role, [String? token]) async {
    if (kIsWeb || _fcm == null) return;
    try {
      final fcmToken = token ?? await _fcm!.getToken();
      if (fcmToken == null) return;

      String? userToken;
      String endpointPath = '';

      if (role == 'vendor') {
        userToken = await AuthService.instance.getSavedToken();
        endpointPath = '/api/vendor/update_fcm_token';
      } else if (role == 'driver') {
        userToken = await DriverAuthService.instance.getSavedToken();
        endpointPath = '/api/driver/update_fcm_token';
      }

      if (userToken == null) {
        if (kDebugMode) {
          print("FCM: No active session for role $role. Registration deferred.");
        }
        return;
      }

      final url = Uri.parse('$_apiBase$endpointPath');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
        body: jsonEncode({'fcm_token': fcmToken}),
      );

      if (kDebugMode) {
        print("FCM register ($role) response: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      if (kDebugMode) {
        print("FCM register ($role) error: $e");
      }
    }
  }
}
