// lib/services/auth_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/customer.dart';
import '../utils/app_config.dart';

/// Base URL of your PHP backend.
/// ┌─────────────────────────────────────────────────────────────────┐
/// │  Real Android device on same WiFi → http://10.196.36.233:8000  │
/// │  Android Emulator                 → http://10.0.2.2:8000       │
/// │  Windows desktop / Chrome         → http://localhost:8000       │
/// └─────────────────────────────────────────────────────────────────┘
final String _baseUrl = '$kBaseUrl/api/auth';
const Duration _timeout = Duration(seconds: 15);

// SharedPreferences keys
const _kToken = 'auth_token';
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
            }),
          )
          .timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final bool ok = body['success'] == true;

      if (ok) {
        final data = body['data'] as Map<String, dynamic>;
        final token = data['token'] as String;
        final customer = Customer.fromJson(
          data['customer'] as Map<String, dynamic>,
        );
        await _persist(token, customer);
        return AuthResult(
          success: true,
          message: body['message'] as String,
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
      final response = await http
          .post(
            Uri.parse('$_baseUrl/login'),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode({
              'email': email.trim().toLowerCase(),
              'password': password,
            }),
          )
          .timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final bool ok = body['success'] == true;

      if (ok) {
        final data = body['data'] as Map<String, dynamic>;
        final token = data['token'] as String;
        final customer = Customer.fromJson(
          data['customer'] as Map<String, dynamic>,
        );
        await _persist(token, customer);
        return AuthResult(
          success: true,
          message: body['message'] as String,
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kCustomer);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Save token + customer to local storage.
  Future<void> _persist(String token, Customer customer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token);
    await prefs.setString(_kCustomer, jsonEncode(customer.toJson()));
  }

  /// Read saved JWT token (null if not logged in).
  Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kToken);
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
