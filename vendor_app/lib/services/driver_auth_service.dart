// lib/services/driver_auth_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/driver.dart';
import 'fcm_service.dart';
import '../utils/app_config.dart';

final String _baseUrl = '$kApiHost/driver';
const Duration _timeout = Duration(seconds: 15);

// SharedPreferences keys
const _kToken = 'driver_token';
const _kDriver = 'driver_profile';

class DriverAuthResult {
  final bool success;
  final String message;
  final String? token;
  final Driver? driver;

  const DriverAuthResult({
    required this.success,
    required this.message,
    this.token,
    this.driver,
  });
}

class DriverAuthService {
  DriverAuthService._();
  static final DriverAuthService instance = DriverAuthService._();

  Future<DriverAuthResult> signUp({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
    required String vehicleNumber,
    required String phoneNumber,
  }) async {
    try {
      final fcmToken = await FcmService.instance.getToken();
      final Map<String, dynamic> reqBody = {
        'full_name': fullName.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'confirm_password': confirmPassword,
        'vehicle_number': vehicleNumber.trim(),
        'phone_number': phoneNumber.trim(),
      };
      if (fcmToken != null && fcmToken.isNotEmpty) {
        reqBody['fcm_token'] = fcmToken;
      }

      final response = await http
          .post(
            Uri.parse('$_baseUrl/signup'),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode(reqBody),
          )
          .timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final bool ok = body['success'] == true;

      if (ok) {
        final data = body['data'] as Map<String, dynamic>;
        final token = data['token'] as String;
        final driver = Driver.fromJson(data['driver'] as Map<String, dynamic>);
        await _persist(token, driver);
        return DriverAuthResult(
          success: true,
          message: body['message'] as String,
          token: token,
          driver: driver,
        );
      }

      return DriverAuthResult(
        success: false,
        message: body['message'] as String? ?? 'Sign up failed.',
      );
    } on SocketException {
      return const DriverAuthResult(
        success: false,
        message: 'Cannot connect to server. Is the PHP server running?',
      );
    } catch (e) {
      return DriverAuthResult(success: false, message: 'Error: $e');
    }
  }

  Future<DriverAuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final fcmToken = await FcmService.instance.getToken();
      final Map<String, dynamic> reqBody = {
        'email': email.trim().toLowerCase(),
        'password': password,
      };
      if (fcmToken != null && fcmToken.isNotEmpty) {
        reqBody['fcm_token'] = fcmToken;
      }

      final response = await http
          .post(
            Uri.parse('$_baseUrl/login'),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode(reqBody),
          )
          .timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final bool ok = body['success'] == true;

      if (ok) {
        final data = body['data'] as Map<String, dynamic>;
        final token = data['token'] as String;
        final driver = Driver.fromJson(data['driver'] as Map<String, dynamic>);
        await _persist(token, driver);
        return DriverAuthResult(
          success: true,
          message: body['message'] as String,
          token: token,
          driver: driver,
        );
      }

      return DriverAuthResult(
        success: false,
        message: body['message'] as String? ?? 'Login failed.',
      );
    } on SocketException {
      return const DriverAuthResult(
        success: false,
        message: 'Cannot connect to server. Is the PHP server running?',
      );
    } catch (e) {
      return DriverAuthResult(success: false, message: 'Error: $e');
    }
  }

  Future<bool> updateStatus({required bool isOnline, double? latitude, double? longitude}) async {
    try {
      final token = await getSavedToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$_baseUrl/status'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'is_online': isOnline ? 1 : 0,
          ...?latitude != null ? {'latitude': latitude} : null,
          ...?longitude != null ? {'longitude': longitude} : null,
        }),
      ).timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final success = body['success'] == true;

      if (success) {
        final saved = await getSavedDriver();
        if (saved != null) {
          final updated = Driver(
            id: saved.id,
            fullName: saved.fullName,
            email: saved.email,
            vehicleNumber: saved.vehicleNumber,
            phoneNumber: saved.phoneNumber,
            isOnline: isOnline,
          );
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_kDriver, jsonEncode(updated.toJson()));
        }
      }
      return success;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kDriver);
    await prefs.remove('active_role');
  }

  Future<void> _persist(String token, Driver driver) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token);
    await prefs.setString(_kDriver, jsonEncode(driver.toJson()));
    await prefs.setString('active_role', 'driver');
    // Register FCM token for Driver
    FcmService.instance.registerToken('driver');
  }

  Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kToken);
  }

  Future<Driver?> getSavedDriver() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kDriver);
    if (raw == null) return null;
    return Driver.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<bool> isLoggedIn() async {
    final token = await getSavedToken();
    return token != null && token.isNotEmpty;
  }
}
