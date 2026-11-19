// lib/services/auth_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/customer.dart';
import '../utils/app_config.dart';
import 'fcm_service.dart';

/// Base URL of your PHP backend.
/// ┌─────────────────────────────────────────────────────────────────┐
/// │  Real Android device on same WiFi → http://10.44.177.233:8000   │
/// │  Android Emulator                 → http://10.0.2.2:8000       │
/// │  Windows desktop / Chrome         → http://localhost:8000       │
/// └─────────────────────────────────────────────────────────────────┘
final String _baseUrl = '$kBaseUrl/api/auth';
const Duration _timeout = Duration(seconds: 15);

// SharedPreferences keys
const _kToken = 'auth_token';
const _kRefreshToken = 'auth_refresh_token';
const _kCustomer = 'auth_customer';

/// Result wrapper returned by every auth method.
class AuthResult {
  final bool success;
  final String message;
  final String? token;
  final Customer? customer;

  const AuthResult({
    required this.success,
    required this.message,
    this.token,
    this.customer,
  });
}

/// Result wrapper returned by OTP verification.
class OtpVerifyResult {
  final bool success;
  final bool isNewUser;
  final String message;
  final String? token;
  final Customer? customer;

  const OtpVerifyResult({
    required this.success,
    required this.isNewUser,
    required this.message,
    this.token,
    this.customer,
  });
}

class AuthService {
  // ── Singleton ───────────────────────────────────────────────────────────────
  AuthService._();
  static final AuthService instance = AuthService._();

  // ── Sign Up ─────────────────────────────────────────────────────────────────
  Future<AuthResult> signUp({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
    required String phoneNumber,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/signup'),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode({
              'full_name': fullName.trim(),
              'email': email.trim().toLowerCase(),
              'password': password,
              'confirm_password': confirmPassword,
              'phone_number': phoneNumber.trim(),
            }),
          )
          .timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final bool ok = body['success'] == true;

      if (ok) {
        final data = (body['data'] as Map<String, dynamic>?) ?? {};
        final token = (data['token'] as String?) ?? '';
        final customerData = data['customer'] != null ? data['customer'] as Map<String, dynamic> : data;
        final customer = Customer.fromJson(customerData);
        final refreshToken = (data['refresh_token'] as String?);
        if (token.isNotEmpty) {
          await _persist(token, customer, refreshToken: refreshToken);
        }
        return AuthResult(
          success: true,
          message: (body['message'] as String?) ?? 'Signed up successfully.',
          token: token,
          customer: customer,
        );
      }

      return AuthResult(
        success: false,
        message: body['message'] as String? ?? 'Sign up failed.',
      );
    } on SocketException {
      return const AuthResult(
        success: false,
        message: 'No internet connection. Is the server running?',
      );
    } on http.ClientException catch (e) {
      return AuthResult(success: false, message: 'Network error: ${e.message}');
    } catch (e) {
      return AuthResult(success: false, message: 'Unexpected error: $e');
    }
  }

  // ── Login ───────────────────────────────────────────────────────────────────
  Future<AuthResult> login({
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
        final data = (body['data'] as Map<String, dynamic>?) ?? {};
        final token = (data['token'] as String?) ?? '';
        final customerMap = (data['customer'] as Map<String, dynamic>?) ??
            (data['admin'] as Map<String, dynamic>?) ??
            data;
        final customer = Customer.fromJson(customerMap);
        final refreshToken = (data['refresh_token'] as String?);
        if (token.isNotEmpty) {
          await _persist(token, customer, refreshToken: refreshToken);
        }
        return AuthResult(
          success: true,
          message: (body['message'] as String?) ?? 'Logged in successfully.',
          token: token,
          customer: customer,
        );
      }

      return AuthResult(
        success: false,
        message: body['message'] as String? ?? 'Login failed.',
      );
    } on SocketException {
      return const AuthResult(
        success: false,
        message: 'Cannot reach server. Make sure the PHP server is running.',
      );
    } on http.ClientException catch (e) {
      return AuthResult(success: false, message: 'Network error: ${e.message}');
    } catch (e) {
      return AuthResult(success: false, message: 'Unexpected error: $e');
    }
  }

  // ── Logout ──────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await updateOnlineStatus(false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kRefreshToken);
    await prefs.remove(_kCustomer);
  }

  /// Update online status (heartbeat)
  Future<void> updateOnlineStatus(bool isOnline) async {
    try {
      final token = await getSavedToken();
      if (token == null || token.isEmpty) return;

      final url = Uri.parse('$kBaseUrl/api/customer/status');
      await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'is_online': isOnline ? 1 : 0}),
      ).timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  // ── Delete Account ──────────────────────────────────────────────────────────
  Future<AuthResult> deleteAccount() async {
    try {
      final token = await getSavedToken();
      if (token != null && token.isNotEmpty) {
        await http.post(
          Uri.parse('$_baseUrl/delete-account'),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Authorization': 'Bearer $token',
          },
        ).timeout(_timeout);
      }
    } catch (_) {}
    await logout();
    return const AuthResult(
      success: true,
      message: 'Account deleted successfully.',
    );
  }

  // ── Forgot Password Methods ────────────────────────────────────────────────
  Future<AuthResult> checkEmail(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/forgot-password/check-email'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({'email': email.trim().toLowerCase()}),
      ).timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final success = body['success'] == true;
      return AuthResult(
        success: success,
        message: body['message'] as String? ?? (success ? 'Email is valid.' : 'Email is not valid'),
      );
    } catch (e) {
      return AuthResult(success: false, message: 'Connection error: $e');
    }
  }

  Future<AuthResult> sendResetOTP(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/forgot-password/send-otp'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({'email': email.trim().toLowerCase()}),
      ).timeout(const Duration(seconds: 25));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthResult(
        success: body['success'] == true,
        message: body['message'] as String? ?? 'Failed to send OTP.',
      );
    } catch (e) {
      return AuthResult(success: false, message: 'Connection error: $e');
    }
  }

  Future<AuthResult> verifyResetOTP(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/forgot-password/verify-otp'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'otp': otp.trim(),
        }),
      ).timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthResult(
        success: body['success'] == true,
        message: body['message'] as String? ?? 'OTP verification failed.',
      );
    } catch (e) {
      return AuthResult(success: false, message: 'Connection error: $e');
    }
  }

  Future<AuthResult> resetPassword(String email, String otp, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/forgot-password/reset'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'otp': otp.trim(),
          'new_password': newPassword,
        }),
      ).timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthResult(
        success: body['success'] == true,
        message: body['message'] as String? ?? 'Password reset failed.',
      );
    } catch (e) {
      return AuthResult(success: false, message: 'Connection error: $e');
    }
  }

  // ── WhatsApp OTP Authentication ─────────────────────────────────────────────

  /// Send WhatsApp OTP code
  Future<AuthResult> sendWhatsAppOtp({
    required String phone,
    String role = 'customer',
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/send-otp'),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode({
              'phone': phone.trim(),
              'role': role,
            }),
          )
          .timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final bool ok = body['success'] == true;

      return AuthResult(
        success: ok,
        message: (body['message'] as String?) ?? (ok ? 'OTP sent.' : 'Failed to send OTP.'),
      );
    } on SocketException {
      return const AuthResult(
        success: false,
        message: 'No internet connection. Please check network settings.',
      );
    } catch (e) {
      return AuthResult(success: false, message: 'Unexpected error: $e');
    }
  }

  /// Verify WhatsApp OTP code
  Future<OtpVerifyResult> verifyWhatsAppOtp({
    required String phone,
    required String otp,
    String role = 'customer',
    String? fullName,
    String? email,
  }) async {
    try {
      final fcmToken = await FcmService.instance.getToken();
      final payload = <String, dynamic>{
        'phone': phone.trim(),
        'otp': otp.trim(),
        'role': role,
      };
      if (fcmToken != null && fcmToken.isNotEmpty) {
        payload['fcm_token'] = fcmToken;
      }
      if (fullName != null && fullName.isNotEmpty) {
        payload['full_name'] = fullName.trim();
      }
      if (email != null && email.isNotEmpty) {
        payload['email'] = email.trim().toLowerCase();
      }

      final response = await http
          .post(
            Uri.parse('$_baseUrl/verify-otp'),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode(payload),
          )
          .timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final bool ok = body['success'] == true;

      if (ok) {
        final data = (body['data'] as Map<String, dynamic>?) ?? {};
        final bool isNewUser = (data['is_new_user'] == true);

        if (!isNewUser) {
          final token = (data['token'] as String?) ?? '';
          final customerData = data['customer'] != null ? data['customer'] as Map<String, dynamic> : data;
          final customer = Customer.fromJson(customerData);
          final refreshToken = (data['refresh_token'] as String?);
          if (token.isNotEmpty) {
            await _persist(token, customer, refreshToken: refreshToken);
          }
          return OtpVerifyResult(
            success: true,
            isNewUser: false,
            message: (body['message'] as String?) ?? 'Verification successful.',
            token: token,
            customer: customer,
          );
        } else {
          return OtpVerifyResult(
            success: true,
            isNewUser: true,
            message: (body['message'] as String?) ?? 'OTP verified. Please complete profile.',
          );
        }
      }

      return OtpVerifyResult(
        success: false,
        isNewUser: false,
        message: (body['message'] as String?) ?? 'Verification failed.',
      );
    } on SocketException {
      return const OtpVerifyResult(
        success: false,
        isNewUser: false,
        message: 'No internet connection.',
      );
    } catch (e) {
      return OtpVerifyResult(
        success: false,
        isNewUser: false,
        message: 'Unexpected error: $e',
      );
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Save token + customer to local storage.
  Future<void> _persist(String token, Customer customer, {String? refreshToken}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await prefs.setString(_kRefreshToken, refreshToken);
    }
    await prefs.setString(_kCustomer, jsonEncode(customer.toJson()));
    // Register FCM token
    FcmService.instance.registerToken();
    updateOnlineStatus(true);
  }

  /// Read saved JWT token (null if not logged in).
  Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kToken);
  }

  /// Read saved Refresh Token.
  Future<String?> getSavedRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kRefreshToken);
  }

  /// Call backend /api/auth/refresh to get a new access token.
  Future<String?> refreshAccessToken() async {
    final refreshToken = await getSavedRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/refresh'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({'refresh_token': refreshToken}),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          final data = (body['data'] as Map<String, dynamic>?) ?? {};
          final newToken = (data['token'] as String?) ?? '';
          final newRefreshToken = data['refresh_token'] as String?;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_kToken, newToken);
          if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
            await prefs.setString(_kRefreshToken, newRefreshToken);
          }
          return newToken;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Read saved Customer (null if not logged in).
  Future<Customer?> getSavedCustomer() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kCustomer);
    if (raw == null) return null;
    return Customer.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// True if a token is stored locally.
  Future<bool> isLoggedIn() async {
    final token = await getSavedToken();
    return token != null && token.isNotEmpty;
  }
}
