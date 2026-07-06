// lib/services/address_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/address_data.dart';
import 'auth_service.dart';
import '../utils/app_config.dart';

// Uses the same base URL pattern as auth_service.dart
final String _addressUrl = '$kBaseUrl/api/auth/address';
const Duration _timeout = Duration(seconds: 15);
const String _kAddress = 'customer_address';

class AddressService {
  AddressService._();
  static final AddressService instance = AddressService._();

  // ── Save address to backend + local cache ─────────────────────────────────
  Future<bool> saveAddress(AddressData address) async {
    try {
      final token = await AuthService.instance.getSavedToken();
      if (token == null) return false;

      final response = await http
          .post(
            Uri.parse(_addressUrl),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(address.toJson()),
          )
          .timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] == true) {
        // Also cache locally for instant access
        await _cacheAddress(address);
        return true;
      }
      // Even if backend fails, cache locally
      await _cacheAddress(address);
      return false;
    } on SocketException {
      // No network — save locally anyway so it persists
      await _cacheAddress(address);
      return false;
    } catch (_) {
      await _cacheAddress(address);
      return false;
    }
  }

  // ── Get address: backend first, then local cache ──────────────────────────
  Future<AddressData?> getAddress() async {
    try {
      final token = await AuthService.instance.getSavedToken();
      if (token != null) {
        final response = await http
            .get(
              Uri.parse(_addressUrl),
              headers: {
                'Content-Type': 'application/json; charset=utf-8',
                'Authorization': 'Bearer $token',
              },
            )
            .timeout(_timeout);

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          final data = body['data'] as Map<String, dynamic>?;
          final addressJson = data?['address'] as Map<String, dynamic>?;
          if (addressJson != null) {
            final addr = AddressData.fromJson(addressJson);
            await _cacheAddress(addr); // refresh cache
            return addr;
          }
        }
      }
    } catch (_) {
      // fall through to local cache
    }

    // Fallback: read from local SharedPreferences cache
    return _readCachedAddress();
  }

  // ── Clear saved address ───────────────────────────────────────────────────
  Future<void> clearAddress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAddress);
  }

  // ── Private helpers ───────────────────────────────────────────────────────
  Future<void> _cacheAddress(AddressData address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAddress, jsonEncode(address.toJson()));
  }

  Future<AddressData?> _readCachedAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kAddress);
    if (raw == null) return null;
    try {
      return AddressData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
