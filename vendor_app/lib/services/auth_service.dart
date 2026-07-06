// lib/services/auth_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vendor.dart';

// Update this to your local server's IP (e.g., 10.136.13.233, 10.0.2.2 for emulator, or localhost)
const String _baseIp = '127.0.0.1';
const String _baseUrl = 'http://$_baseIp:8000/api/vendor';
const Duration _timeout = Duration(seconds: 15);

// SharedPreferences keys
const _kToken = 'vendor_token';
const _kVendor = 'vendor_profile';

class AuthResult {
  final bool success;
  final String message;
  final String? token;
  final Vendor? vendor;

  const AuthResult({
    required this.success,
    required this.message,
    this.token,
    this.vendor,
  });
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

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
        final vendor = Vendor.fromJson(data['vendor'] as Map<String, dynamic>);
        await _persist(token, vendor);
        return AuthResult(
          success: true,
          message: body['message'] as String,
          token: token,
          vendor: vendor,
        );
      }

      return AuthResult(
        success: false,
        message: body['message'] as String? ?? 'Sign up failed.',
      );
    } on SocketException {
      return const AuthResult(
        success: false,
        message: 'Cannot connect to server. Is the PHP server running?',
      );
    } catch (e) {
      return AuthResult(success: false, message: 'Error: $e');
    }
  }

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
        final vendor = Vendor.fromJson(data['vendor'] as Map<String, dynamic>);
        await _persist(token, vendor);
        return AuthResult(
          success: true,
          message: body['message'] as String,
          token: token,
          vendor: vendor,
        );
      }

      return AuthResult(
        success: false,
        message: body['message'] as String? ?? 'Login failed.',
      );
    } on SocketException {
      return const AuthResult(
        success: false,
        message: 'Cannot connect to server. Is the PHP server running?',
      );
    } catch (e) {
      return AuthResult(success: false, message: 'Error: $e');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kVendor);
  }

  Future<void> _persist(String token, Vendor vendor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token);
    await prefs.setString(_kVendor, jsonEncode(vendor.toJson()));
  }

  Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kToken);
  }

  Future<Vendor?> getSavedVendor() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kVendor);
    if (raw == null) return null;
    return Vendor.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<bool> isLoggedIn() async {
    final token = await getSavedToken();
    return token != null && token.isNotEmpty;
  }
}
