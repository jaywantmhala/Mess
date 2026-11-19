import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/app_config.dart';
import 'auth_service.dart';

const Duration _kTimeout = Duration(seconds: 15);

class VendorDailyEarnings {
  final String date;
  final double dailyTotal;
  final int ordersCount;

  VendorDailyEarnings({
    required this.date,
    required this.dailyTotal,
    required this.ordersCount,
  });

  factory VendorDailyEarnings.fromJson(Map<String, dynamic> json) {
    return VendorDailyEarnings(
      date: (json['date'] ?? '') as String,
      dailyTotal: double.parse((json['daily_total'] ?? 0).toString()),
      ordersCount: int.parse((json['orders_count'] ?? 0).toString()),
    );
  }
}

class VendorWalletInfo {
  final double balance;
  final double todayEarnings;
  final int todayOrdersCount;
  final List<VendorDailyEarnings> dailyBreakdown;
  final double areaTiffinCharge;
  final String areaName;

  VendorWalletInfo({
    required this.balance,
    required this.todayEarnings,
    required this.todayOrdersCount,
    required this.dailyBreakdown,
    this.areaTiffinCharge = 50.0,
    this.areaName = 'Area',
  });

  factory VendorWalletInfo.fromJson(Map<String, dynamic> json) {
    final list = (json['daily_breakdown'] as List? ?? []);
    final double charge = double.tryParse((json['area_tiffin_charge'] ?? json['tiffin_charge'] ?? 50.0).toString()) ?? 50.0;
    final String area = (json['area_name'] ?? 'Area').toString();
    return VendorWalletInfo(
      balance: double.parse((json['balance'] ?? 0).toString()),
      todayEarnings: double.parse((json['today_earnings'] ?? 0).toString()),
      todayOrdersCount: int.parse((json['today_orders_count'] ?? 0).toString()),
      dailyBreakdown: list.map((i) => VendorDailyEarnings.fromJson(i as Map<String, dynamic>)).toList(),
      areaTiffinCharge: charge,
      areaName: area,
    );
  }
}

class VendorWalletTransaction {
  final int id;
  final int vendorId;
  final int? orderId;
  final String type;
  final double amount;
  final double balanceAfter;
  final String description;
  final DateTime createdAt;

  VendorWalletTransaction({
    required this.id,
    required this.vendorId,
    this.orderId,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.description,
    required this.createdAt,
  });

  bool get isCredit => type == 'CREDIT';

  factory VendorWalletTransaction.fromJson(Map<String, dynamic> json) {
    return VendorWalletTransaction(
      id: json['id'] as int,
      vendorId: json['vendor_id'] as int,
      orderId: json['order_id'] != null ? json['order_id'] as int : null,
      type: (json['type'] ?? 'CREDIT') as String,
      amount: double.parse(json['amount'].toString()),
      balanceAfter: double.parse(json['balance_after'].toString()),
      description: (json['description'] ?? '') as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }
}

class VendorPayoutItem {
  final int payoutId;
  final double amount;
  final String status;
  final String paymentType;
  final String initiatedAt;
  final String? completedAt;
  final String bankAccountLast4;
  final String payuReference;
  final String? failureReason;

  VendorPayoutItem({
    required this.payoutId,
    required this.amount,
    required this.status,
    required this.paymentType,
    required this.initiatedAt,
    this.completedAt,
    required this.bankAccountLast4,
    required this.payuReference,
    this.failureReason,
  });

  factory VendorPayoutItem.fromJson(Map<String, dynamic> json) {
    return VendorPayoutItem(
      payoutId: (json['payout_id'] ?? 0) as int,
      amount: double.parse((json['amount'] ?? 0).toString()),
      status: (json['status'] ?? 'PENDING') as String,
      paymentType: (json['payment_type'] ?? 'IMPS') as String,
      initiatedAt: (json['initiated_at'] ?? '') as String,
      completedAt: json['completed_at'] as String?,
      bankAccountLast4: (json['bank_account_last4'] ?? '') as String,
      payuReference: (json['payu_reference'] ?? '') as String,
      failureReason: json['failure_reason'] as String?,
    );
  }
}

class VendorWalletService {
  VendorWalletService._();
  static final VendorWalletService instance = VendorWalletService._();

  final ValueNotifier<double?> balanceNotifier = ValueNotifier<double?>(null);

  Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.instance.getSavedToken();
    return {
      'Content-Type': 'application/json; charset=utf-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<double> getBalance() async {
    final info = await getWalletInfo();
    return info.balance;
  }

  Future<VendorWalletInfo> getWalletInfo() async {
    final headers = await _authHeaders();
    try {
      final response = await http
          .get(
            Uri.parse('$kBaseUrl/wallet/balance'),
            headers: headers,
          )
          .timeout(_kTimeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] == true && body['data'] != null) {
        final info = VendorWalletInfo.fromJson(body['data'] as Map<String, dynamic>);
        balanceNotifier.value = info.balance;
        return info;
      }
      throw Exception(body['message'] ?? 'Failed to fetch vendor wallet balance');
    } on SocketException {
      throw Exception('No internet connection');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<VendorWalletTransaction>> getTransactions({
    int page = 1,
    int limit = 20,
  }) async {
    final headers = await _authHeaders();
    try {
      final response = await http
          .get(
            Uri.parse('$kBaseUrl/wallet/transactions?page=$page&limit=$limit'),
            headers: headers,
          )
          .timeout(_kTimeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] == true && body['data'] != null) {
        final data = body['data'] as Map<String, dynamic>;
        final list = (data['transactions'] as List? ?? []);
        return list
            .map((t) => VendorWalletTransaction.fromJson(t as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<VendorPayoutItem>> getPayoutHistory() async {
    final headers = await _authHeaders();
    try {
      final response = await http
          .get(
            Uri.parse('$kBaseUrl/payouts'),
            headers: headers,
          )
          .timeout(_kTimeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] == true && body['data'] != null) {
        final list = (body['data'] as List? ?? []);
        return list
            .map((p) => VendorPayoutItem.fromJson(p as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
