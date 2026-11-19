// lib/services/auth_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vendor.dart';
import 'fcm_service.dart';
import 'razorpay_service.dart';
import '../utils/app_config.dart';
import '../utils/api_client.dart';

final String _baseUrl = kBaseUrl;
const Duration _timeout = Duration(seconds: 15);

// SharedPreferences keys
const _kToken = 'vendor_token';
const _kRefreshToken = 'vendor_refresh_token';
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

class OtpVerifyResult {
  final bool success;
  final bool isNewUser;
  final String message;
  final String? token;
  final Vendor? vendor;

  const OtpVerifyResult({
    required this.success,
    required this.isNewUser,
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
    required String phoneNumber,
    required String password,
    required String confirmPassword,
    String? country,
    String? state,
    String? district,
    String? taluka,
  }) async {
    try {
      final Map<String, dynamic> payload = {
        'full_name': fullName.trim(),
        'email': email.trim().toLowerCase(),
        'phone_number': phoneNumber.trim(),
        'phone': phoneNumber.trim(),
        'password': password,
        'confirm_password': confirmPassword,
      };
      if (country != null) payload['country'] = country;
      if (state != null) payload['state'] = state;
      if (district != null) payload['district'] = district;
      if (taluka != null) payload['taluka'] = taluka;

      // Create Razorpay Contact using vendor's name, email, contact
      try {
        final rzpContact = await RazorpayService.createContact(
          name: fullName.trim(),
          email: email.trim().toLowerCase(),
          contact: phoneNumber.trim(),
          type: 'vendor',
          notes: {
            'notes_key_1': 'Tea, Earl Grey, Hot',
            'notes_key_2': 'Tea, Earl Grey… decaf.',
          },
        );
        if (rzpContact != null && rzpContact['id'] != null) {
          payload['razorpay_contact_id'] = rzpContact['id'];
        }
      } catch (e) {
        // Log error and allow registration to proceed
        print('Razorpay createContact on signup error: $e');
      }

      final response = await http
          .post(
            Uri.parse('$_baseUrl/signup'),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode(payload),
          )
          .timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final bool ok = body['success'] == true;

      if (ok) {
        final data = body['data'] as Map<String, dynamic>;
        final token = data['token'] as String;
        final refreshToken = data['refresh_token'] as String?;
        final vendor = Vendor.fromJson(data['vendor'] as Map<String, dynamic>);
        await _persist(token, vendor, refreshToken: refreshToken);
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
        final refreshToken = data['refresh_token'] as String?;
        final vendor = Vendor.fromJson(data['vendor'] as Map<String, dynamic>);
        await _persist(token, vendor, refreshToken: refreshToken);
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
    await prefs.remove(_kRefreshToken);
    await prefs.remove(_kVendor);
    await prefs.remove('active_role');
  }

  Future<void> _persist(String token, Vendor vendor, {String? refreshToken}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await prefs.setString(_kRefreshToken, refreshToken);
    }
    await prefs.setString(_kVendor, jsonEncode(vendor.toJson()));
    await prefs.setString('active_role', 'vendor');
    // Register FCM token for Vendor
    FcmService.instance.registerToken('vendor');
  }

  Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kToken);
  }

  Future<String?> getSavedRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kRefreshToken);
  }

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
          final data = body['data'] as Map<String, dynamic>;
          final newToken = data['token'] as String;
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

  // ── WhatsApp OTP Authentication (Phone Login & Signup) ─────────────────────

  /// Send 6-digit verification code to the vendor's WhatsApp number.
  Future<AuthResult> sendWhatsAppOtp({
    required String phone,
    String role = 'vendor',
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

  /// Verify WhatsApp OTP. If existing vendor, logs in automatically.
  /// If new vendor, creates account if profile details are provided, or indicates profile completion needed.
  Future<OtpVerifyResult> verifyWhatsAppOtp({
    required String phone,
    required String otp,
    String role = 'vendor',
    String? fullName,
    String? email,
    String? country,
    String? state,
    String? district,
    String? taluka,
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
      if (fullName != null && fullName.trim().isNotEmpty) {
        payload['full_name'] = fullName.trim();
      }
      if (email != null && email.trim().isNotEmpty) {
        payload['email'] = email.trim().toLowerCase();
      }
      if (country != null && country.trim().isNotEmpty) {
        payload['country'] = country.trim();
      }
      if (state != null && state.trim().isNotEmpty) {
        payload['state'] = state.trim();
      }
      if (district != null && district.trim().isNotEmpty) {
        payload['district'] = district.trim();
      }
      if (taluka != null && taluka.trim().isNotEmpty) {
        payload['taluka'] = taluka.trim();
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
          final vendorMap = (data['vendor'] as Map<String, dynamic>?) ?? data;
          final vendor = Vendor.fromJson(vendorMap);
          final refreshToken = data['refresh_token'] as String?;
          if (token.isNotEmpty) {
            await _persist(token, vendor, refreshToken: refreshToken);
          }
          return OtpVerifyResult(
            success: true,
            isNewUser: false,
            message: (body['message'] as String?) ?? 'Verification successful.',
            token: token,
            vendor: vendor,
          );
        } else {
          return OtpVerifyResult(
            success: true,
            isNewUser: true,
            message: (body['message'] as String?) ?? 'OTP verified. Please complete your profile.',
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

  Future<AuthResult> updateProfile({
    required String fullName,
    required String email,
    String? phoneNumber,
    required String country,
    required String state,
    required String district,
    required String taluka,
  }) async {
    try {
      final savedVendor = await getSavedVendor();
      if (savedVendor == null) {
        return const AuthResult(success: false, message: 'Vendor profile not found.');
      }

      final draftVendor = savedVendor.copyWith(
        fullName: fullName.trim(),
        email: email.trim(),
        phoneNumber: phoneNumber?.trim() ?? savedVendor.phoneNumber,
        country: country,
        state: state,
        district: district,
        taluka: taluka,
      );

      final token = await getSavedToken();

      final response = await ApiClient.instance.post(
        Uri.parse('$_baseUrl/update_profile'),
        body: jsonEncode(draftVendor.toJson()),
      ).timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final success = body['success'] == true;
      final message = body['message'] as String? ?? (success ? 'Profile updated successfully!' : 'Failed to update profile.');

      if (success) {
        final data = body['data'] as Map<String, dynamic>?;
        final serverVendor = (data != null && data['vendor'] != null)
            ? Vendor.fromJson(data['vendor'] as Map<String, dynamic>)
            : draftVendor;

        if (token != null) {
          await _persist(token, serverVendor);
        }

        return AuthResult(
          success: true,
          message: message,
          vendor: serverVendor,
        );
      } else {
        return AuthResult(
          success: false,
          message: message,
        );
      }
    } catch (e) {
      return AuthResult(success: false, message: 'Failed to update profile: $e');
    }
  }
}
