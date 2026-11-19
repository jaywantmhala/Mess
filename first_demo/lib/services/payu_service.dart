// lib/services/payu_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../utils/app_config.dart';

class PayUOrderResult {
  final bool success;
  final String? orderId;
  final String? keyId;
  final String? txnid;
  final String? internalTransactionId;
  final int? amountPaise;
  final double? amount;
  final String? planName;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? hash;
  final String? action;
  final String? surl;
  final String? furl;
  final String? udf1;
  final String? udf2;
  final String? message;

  PayUOrderResult({
    required this.success,
    this.orderId,
    this.keyId,
    this.txnid,
    this.internalTransactionId,
    this.amountPaise,
    this.amount,
    this.planName,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.hash,
    this.action,
    this.surl,
    this.furl,
    this.udf1,
    this.udf2,
    this.message,
  });
}

typedef RazorpayOrderResult = PayUOrderResult;

class PayUVerifyResult {
  final bool success;
  final String? message;
  final Map<String, dynamic>? data;

  PayUVerifyResult({
    required this.success,
    this.message,
    this.data,
  });
}

typedef RazorpayVerifyResult = PayUVerifyResult;

class PayUService {
  PayUService._();
  static final PayUService instance = PayUService._();

  static const String payuMerchantKey = 'ddhaRc';

  /// Step 1: Create PayU Order on Backend API (/api/customer/payu/create_order)
  Future<PayUOrderResult> createOrder(int planId) async {
    debugPrint('➡️ [PayUService] Initiating createOrder() for Plan ID: $planId');
    try {
      final token = await AuthService.instance.getSavedToken();
      if (token == null) {
        debugPrint('❌ [PayUService] Error: Authorization token is null (session expired).');
        return PayUOrderResult(success: false, message: 'Session expired. Please log in.');
      }

      final uri = Uri.parse('$kBaseUrl/api/customer/payu/create_order');
      final payload = jsonEncode({'plan_id': planId});

      debugPrint('🌐 [PayUService] Sending POST request to: $uri');
      debugPrint('📤 [PayUService] Request Payload: $payload');

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Authorization': 'Bearer $token',
            },
            body: payload,
          )
          .timeout(const Duration(seconds: 20));

      debugPrint('📥 [PayUService] Response Code: ${response.statusCode}');
      debugPrint('📥 [PayUService] Response Body: ${response.body}');

      Map<String, dynamic> body;
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (jsonErr) {
        debugPrint('💥 [PayUService] JSON Parsing Error: $jsonErr');
        return PayUOrderResult(success: false, message: 'Invalid JSON response from server.');
      }

      if (body['success'] == true && body['data'] != null) {
        final data = body['data'] as Map<String, dynamic>;
        final orderId = data['order_id']?.toString() ?? data['txnid']?.toString();
        final keyId = data['key_id']?.toString() ?? data['key']?.toString() ?? payuMerchantKey;
        final amountPaise = data['amount_paise'] as int?;
        final amount = (data['amount'] as num?)?.toDouble();

        debugPrint('✅ [PayUService] Order Created Successfully!');
        debugPrint('   - PayU Txn ID: $orderId');
        debugPrint('   - Key: $keyId');
        debugPrint('   - Hash: ${data['hash']}');

        return PayUOrderResult(
          success: true,
          orderId: orderId,
          keyId: keyId,
          txnid: data['txnid']?.toString() ?? orderId,
          internalTransactionId: data['internal_transaction_id']?.toString(),
          amountPaise: amountPaise,
          amount: amount,
          planName: data['plan_name']?.toString() ?? data['productinfo']?.toString(),
          customerName: data['customer_name']?.toString() ?? data['firstname']?.toString(),
          customerEmail: data['customer_email']?.toString(),
          customerPhone: data['customer_phone']?.toString(),
          hash: data['hash']?.toString(),
          action: data['action']?.toString(),
          surl: data['surl']?.toString(),
          furl: data['furl']?.toString(),
          udf1: data['udf1']?.toString(),
          udf2: data['udf2']?.toString(),
          message: body['message']?.toString(),
        );
      }

      final errMsg = body['message']?.toString() ?? 'Failed to create PayU payment order.';
      debugPrint('❌ [PayUService] PHP API Error: $errMsg');
      return PayUOrderResult(success: false, message: errMsg);

    } catch (e, stackTrace) {
      debugPrint('💥 [PayUService] Exception in createOrder(): $e');
      debugPrint('   - StackTrace: $stackTrace');
      return PayUOrderResult(success: false, message: e.toString());
    }
  }

  /// Step 2: Verify PayU Payment Signature & Server Status (/api/customer/payu/verify_payment)
  Future<PayUVerifyResult> verifyPayment({
    required String orderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required int planId,
    String? internalTransactionId,
  }) async {
    debugPrint('➡️ [PayUService] Initiating verifyPayment()');
    debugPrint('   - Txn/Order ID: $orderId');
    debugPrint('   - PayU ID: $razorpayPaymentId');
    debugPrint('   - Plan ID: $planId');

    try {
      final token = await AuthService.instance.getSavedToken();
      if (token == null) {
        debugPrint('❌ [PayUService] Error: Authorization token is null.');
        return PayUVerifyResult(success: false, message: 'Session expired. Please log in.');
      }

      final uri = Uri.parse('$kBaseUrl/api/customer/payu/verify_payment');
      final payload = jsonEncode({
        'txnid': orderId,
        'order_id': orderId,
        'mihpayid': razorpayPaymentId,
        'payu_payment_id': razorpayPaymentId,
        'hash': razorpaySignature,
        'razorpay_signature': razorpaySignature,
        'status': 'success',
        'plan_id': planId,
        'internal_transaction_id': internalTransactionId,
      });

      debugPrint('🌐 [PayUService] Sending POST request to: $uri');
      debugPrint('📤 [PayUService] Verification Payload: $payload');

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Authorization': 'Bearer $token',
            },
            body: payload,
          )
          .timeout(const Duration(seconds: 20));

      debugPrint('📥 [PayUService] Verification Response Code: ${response.statusCode}');
      debugPrint('📥 [PayUService] Verification Response Body: ${response.body}');

      Map<String, dynamic> body;
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (jsonErr) {
        debugPrint('💥 [PayUService] JSON Parsing Error in verifyPayment(): $jsonErr');
        return PayUVerifyResult(success: false, message: 'Invalid server response structure.');
      }

      if (body['success'] == true) {
        debugPrint('🎉 [PayUService] Payment Verification Successful on Server!');
        return PayUVerifyResult(
          success: true,
          message: body['message']?.toString(),
          data: body['data'] as Map<String, dynamic>?,
        );
      }

      final errMsg = body['message']?.toString() ?? 'Payment verification failed.';
      debugPrint('❌ [PayUService] Server Verification Rejected: $errMsg');
      return PayUVerifyResult(success: false, message: errMsg);

    } catch (e, stackTrace) {
      debugPrint('💥 [PayUService] Exception in verifyPayment(): $e');
      debugPrint('   - StackTrace: $stackTrace');
      return PayUVerifyResult(success: false, message: e.toString());
    }
  }

  /// Helper to build PayU Checkout options map
  Map<String, dynamic> buildCheckoutOptions({
    required String orderId,
    required String keyId,
    required int amountPaise,
    required String planName,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? hash,
    String? action,
    String? surl,
    String? furl,
    String? udf1,
    String? udf2,
  }) {
    final key = keyId.isNotEmpty ? keyId : payuMerchantKey;
    final amountDouble = amountPaise / 100.0;
    debugPrint('⚙️ [PayUService] Building PayU Checkout Options Map:');
    debugPrint('   - key: $key');
    debugPrint('   - amount: $amountDouble');
    debugPrint('   - txnid: $orderId');

    return {
      'key': key,
      'txnid': orderId,
      'amount': amountDouble.toStringAsFixed(2),
      'amount_paise': amountPaise,
      'productinfo': planName,
      'firstname': (customerName != null && customerName.isNotEmpty) ? customerName.split(' ')[0] : 'Customer',
      'email': (customerEmail != null && customerEmail.isNotEmpty) ? customerEmail : 'customer@hungrilyfoods.com',
      'phone': (customerPhone != null && customerPhone.isNotEmpty) ? customerPhone : '9876543210',
      'hash': hash ?? '',
      'action': action ?? (kUseLocalUrl ? 'https://test.payu.in/_payment' : 'https://secure.payu.in/_payment'),
      'surl': surl ?? '$kBaseUrl/api/customer/payu/success',
      'furl': furl ?? '$kBaseUrl/api/customer/payu/failure',
      'udf1': udf1 ?? '',
      'udf2': udf2 ?? '',
      'order_id': orderId,
    };
  }
}

typedef RazorpayService = PayUService;
