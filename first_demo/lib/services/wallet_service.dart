// lib/services/wallet_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/app_config.dart';
import '../models/wallet.dart';
import 'auth_service.dart';

const Duration _kTimeout = Duration(seconds: 15);

class WalletService {
  WalletService._();
  static final WalletService instance = WalletService._();

  // ValueNotifier to notify listeners of wallet updates.
  final ValueNotifier<double?> balanceNotifier = ValueNotifier<double?>(null);

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.instance.getSavedToken();
    return {
      'Content-Type': 'application/json; charset=utf-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Get Balance ─────────────────────────────────────────────────────────────

  /// Fetches (and auto-creates) the wallet for the logged-in customer.
  Future<WalletBalance> getBalance() async {
    final headers = await _authHeaders();
    try {
      final response = await http
          .get(
            Uri.parse('$kBaseUrl/api/wallet/balance'),
            headers: headers,
          )
          .timeout(_kTimeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] == true && body['data'] != null) {
        final walletBalance = WalletBalance.fromJson(body['data'] as Map<String, dynamic>);
        balanceNotifier.value = walletBalance.balance;
        return walletBalance;
      }
      throw Exception(body['message'] ?? 'Failed to fetch wallet balance');
    } on SocketException {
      throw Exception('No internet connection');
    } catch (e) {
      rethrow;
    }
  }

  // ── Recharge ────────────────────────────────────────────────────────────────

  /// Adds [amount] to the wallet. Returns the updated [WalletBalance].
  Future<WalletBalance> recharge(double amount) async {
    final headers = await _authHeaders();
    try {
      final response = await http
          .post(
            Uri.parse('$kBaseUrl/api/wallet/recharge'),
            headers: headers,
            body: jsonEncode({'amount': amount}),
          )
          .timeout(_kTimeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] == true && body['data'] != null) {
        final data = body['data'] as Map<String, dynamic>;
        final newBal = double.parse(data['new_balance'].toString());
        balanceNotifier.value = newBal;
        // Re-fetch full balance object (new_balance returned)
        return WalletBalance(
          walletId: 0,
          customerId: 0,
          balance: newBal,
        );
      }
      throw Exception(body['message'] ?? 'Recharge failed');
    } on SocketException {
      throw Exception('No internet connection');
    } catch (e) {
      rethrow;
    }
  }

  // ── Transaction History ──────────────────────────────────────────────────────

  Future<List<WalletTransaction>> getTransactions({
    int page = 1,
    int limit = 20,
  }) async {
    final headers = await _authHeaders();
    try {
      final response = await http
          .get(
            Uri.parse(
                '$kBaseUrl/api/wallet/transactions?page=$page&limit=$limit'),
            headers: headers,
          )
          .timeout(_kTimeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] == true && body['data'] != null) {
        final list = body['data'] as List;
        return list
            .map((t) =>
                WalletTransaction.fromJson(t as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
