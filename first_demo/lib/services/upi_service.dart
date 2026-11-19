// lib/services/upi_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../utils/app_config.dart';

class UpiPayResult {
  final bool success;
  final String? message;
  final Map<String, dynamic>? data;

  UpiPayResult({
    required this.success,
    this.message,
    this.data,
  });
}

class UpiService {
  UpiService._();
  static final UpiService instance = UpiService._();

  static const String upiId = 'kamble.prafull08-3@okicici';
  static const String payeeName = 'Hungrily Foods';

  /// Verify UPI Payment via UTR and activate subscription plan
  Future<UpiPayResult> verifyUpiPayment({
    required int planId,
    required String utrNumber,
  }) async {
    try {
      final token = await AuthService.instance.getSavedToken();
      if (token == null) {
        return UpiPayResult(success: false, message: 'Session expired. Please log in again.');
      }

      final uri = Uri.parse('$kBaseUrl/api/customer/upi_pay');
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'plan_id': planId,
              'utr_number': utrNumber,
            }),
          )
          .timeout(const Duration(seconds: 20));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] == true) {
        return UpiPayResult(
          success: true,
          message: body['message']?.toString(),
          data: body['data'] as Map<String, dynamic>?,
        );
      }
      return UpiPayResult(
        success: false,
        message: body['message']?.toString() ?? 'UPI payment verification failed.',
      );
    } catch (e) {
      debugPrint('Error verifying UPI payment: $e');
      return UpiPayResult(success: false, message: e.toString());
    }
  }
}
