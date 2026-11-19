// lib/services/address_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/address_data.dart';
import 'auth_service.dart';
import '../utils/app_config.dart';

final String _addressUrl = '$kBaseUrl/api/auth/address';
const Duration _timeout = Duration(seconds: 15);
const String _kAddress = 'customer_address';
const String _kAddressesList = 'customer_addresses_list';

class SaveAddressResult {
  final bool success;
  final String message;
  final AddressData? address;

  SaveAddressResult({
    required this.success,
    required this.message,
    this.address,
  });
}

class AddressService {
  AddressService._();
  static final AddressService instance = AddressService._();

  // ── Save/Update address to backend + local cache ──────────────────────────
  Future<SaveAddressResult> saveAddress(AddressData address) async {
    try {
      final token = await AuthService.instance.getSavedToken();
      if (token == null) {
        return SaveAddressResult(success: false, message: 'Session expired. Please log in.');
      }

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
      final isSuccess = body['success'] == true;
      final msg = body['message']?.toString() ?? (isSuccess ? 'Address saved successfully.' : 'Failed to save address.');

      if (isSuccess && body['data'] != null && body['data']['address'] != null) {
        final savedAddr = AddressData.fromJson(body['data']['address'] as Map<String, dynamic>);
        await _cacheAddress(savedAddr);
        return SaveAddressResult(success: true, message: msg, address: savedAddr);
      }

      return SaveAddressResult(success: false, message: msg);
    } on SocketException {
      await _cacheAddress(address);
      return SaveAddressResult(success: true, message: 'Saved locally.', address: address);
    } catch (e) {
      return SaveAddressResult(success: false, message: e.toString());
    }
  }

  // ── Get all saved addresses for logged-in customer ────────────────────────
  Future<List<AddressData>> getAddresses() async {
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
        if (body['success'] == true && body['data'] != null) {
          final rawList = body['data']['addresses'] as List<dynamic>?;
          if (rawList != null) {
            final list = rawList.map((e) => AddressData.fromJson(e as Map<String, dynamic>)).toList();
            await _cacheAddressesList(list);
            return list;
          }
        }
      }
    } catch (_) {}

    return _readCachedAddressesList();
  }

  // ── Get active address (default/first) ────────────────────────────────────
  Future<AddressData?> getAddress() async {
    final list = await getAddresses();
    if (list.isNotEmpty) {
      final def = list.firstWhere((a) => a.isDefault, orElse: () => list.first);
      await _cacheAddress(def);
      return def;
    }
    return _readCachedAddress();
  }

  // ── Delete Address ────────────────────────────────────────────────────────
  Future<bool> deleteAddress(int id) async {
    try {
      final token = await AuthService.instance.getSavedToken();
      if (token == null) return false;

      final response = await http
          .post(
            Uri.parse('$_addressUrl/delete'),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'id': id, 'address_id': id, 'action': 'delete'}),
          )
          .timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final ok = body['success'] == true;
      if (ok) {
        // Immediately remove deleted address from local cached list
        final cachedList = await _readCachedAddressesList();
        cachedList.removeWhere((a) => a.id == id);
        await _cacheAddressesList(cachedList);

        // If the deleted address was the active cached address, update or clear single cache
        final currentSingle = await _readCachedAddress();
        if (currentSingle != null && currentSingle.id == id) {
          if (cachedList.isNotEmpty) {
            await _cacheAddress(cachedList.first);
          } else {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove(_kAddress);
          }
        }
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  // ── Set Default Address ───────────────────────────────────────────────────
  Future<bool> setDefaultAddress(int id) async {
    try {
      final token = await AuthService.instance.getSavedToken();
      if (token == null) return false;

      final response = await http
          .post(
            Uri.parse('$_addressUrl/select'),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'id': id, 'action': 'select'}),
          )
          .timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final ok = body['success'] == true;
      if (ok) {
        await getAddresses();
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<void> cacheSelectedAddress(AddressData address) async {
    await _cacheAddress(address);
  }

  // ── Clear saved address ───────────────────────────────────────────────────
  Future<void> clearAddress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAddress);
    await prefs.remove(_kAddressesList);
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

  Future<void> _cacheAddressesList(List<AddressData> list) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = list.map((a) => a.toJson()).toList();
    await prefs.setString(_kAddressesList, jsonEncode(jsonList));
  }

  Future<List<AddressData>> _readCachedAddressesList() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kAddressesList);
    if (raw == null) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(raw);
      return jsonList.map((e) => AddressData.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}
