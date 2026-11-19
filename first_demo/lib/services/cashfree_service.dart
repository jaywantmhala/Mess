// lib/services/cashfree_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfdropcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentcomponents/cfpaymentcomponent.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/api/cftheme/cftheme.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../utils/app_config.dart';

class CashfreeOrderResult {
  final bool success;
  final String? orderId;
  final String? paymentSessionId;
  final String? environment;
  final String? message;

  CashfreeOrderResult({
    required this.success,
    this.orderId,
    this.paymentSessionId,
    this.environment,
    this.message,
  });
}

class CashfreeVerifyResult {
  final bool success;
  final String? message;
  final Map<String, dynamic>? data;

  CashfreeVerifyResult({
    required this.success,
    this.message,
    this.data,
  });
}

class CashfreeService {
  CashfreeService._();
  static final CashfreeService instance = CashfreeService._();

  final CFPaymentGatewayService _cfPaymentGatewayService = CFPaymentGatewayService();

  /// Step 1: Create Cashfree Order on Backend
  Future<CashfreeOrderResult> createOrder(int planId) async {
    try {
      final token = await AuthService.instance.getSavedToken();
      if (token == null) {
        return CashfreeOrderResult(success: false, message: 'Session expired. Please log in.');
      }

      final uri = Uri.parse('$kBaseUrl/api/customer/cashfree/create_order');
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'plan_id': planId}),
          )
          .timeout(const Duration(seconds: 20));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] == true && body['data'] != null) {
        final data = body['data'] as Map<String, dynamic>;
        return CashfreeOrderResult(
          success: true,
          orderId: data['order_id']?.toString(),
          paymentSessionId: data['payment_session_id']?.toString(),
          environment: data['environment']?.toString() ?? (kUseLocalUrl ? 'TEST' : 'PRODUCTION'),
          message: body['message']?.toString(),
        );
      }
      return CashfreeOrderResult(
        success: false,
        message: body['message']?.toString() ?? 'Failed to create Cashfree payment order.',
      );
    } catch (e) {
      debugPrint('Error creating Cashfree order: $e');
      return CashfreeOrderResult(success: false, message: e.toString());
    }
  }

  /// Step 2: Verify Cashfree Payment status on Backend
  Future<CashfreeVerifyResult> verifyPayment({
    required String orderId,
    required int planId,
  }) async {
    try {
      final token = await AuthService.instance.getSavedToken();
      if (token == null) {
        return CashfreeVerifyResult(success: false, message: 'Session expired. Please log in.');
      }

      final uri = Uri.parse('$kBaseUrl/api/customer/cashfree/verify_payment');
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'order_id': orderId,
              'plan_id': planId,
            }),
          )
          .timeout(const Duration(seconds: 20));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] == true) {
        return CashfreeVerifyResult(
          success: true,
          message: body['message']?.toString(),
          data: body['data'] as Map<String, dynamic>?,
        );
      }
      return CashfreeVerifyResult(
        success: false,
        message: body['message']?.toString() ?? 'Payment verification failed.',
      );
    } catch (e) {
      debugPrint('Error verifying Cashfree payment: $e');
      return CashfreeVerifyResult(success: false, message: e.toString());
    }
  }

  /// Step 3: Trigger Cashfree PG SDK Drop Checkout
  void startPayment({
    required String orderId,
    required String paymentSessionId,
    required String environment,
    required Function(String orderId) onVerify,
    required Function(CFErrorResponse error, String orderId) onError,
  }) {
    try {
      // Register callbacks
      _cfPaymentGatewayService.setCallback(onVerify, onError);

      // Environment setup
      final cfEnv = (environment.toUpperCase() == 'PRODUCTION')
          ? CFEnvironment.PRODUCTION
          : CFEnvironment.SANDBOX;

      final session = CFSessionBuilder()
          .setEnvironment(cfEnv)
          .setOrderId(orderId)
          .setPaymentSessionId(paymentSessionId)
          .build();

      // Theme customization matching app brand colors (Orange: #F58220)
      final theme = CFThemeBuilder()
          .setNavigationBarBackgroundColorColor("#F58220")
          .setNavigationBarTextColor("#FFFFFF")
          .setButtonBackgroundColor("#F58220")
          .setButtonTextColor("#FFFFFF")
          .setPrimaryTextColor("#1A1A2E")
          .setSecondaryTextColor("#6B7280")
          .build();

      final paymentComponent = CFPaymentComponentBuilder()
          .setComponents([
            CFPaymentModes.CARD,
            CFPaymentModes.UPI,
            CFPaymentModes.NETBANKING,
            CFPaymentModes.WALLET,
            CFPaymentModes.PAYLATER,
          ])
          .build();

      final dropCheckoutPayment = CFDropCheckoutPaymentBuilder()
          .setSession(session)
          .setTheme(theme)
          .setPaymentComponent(paymentComponent)
          .build();

      _cfPaymentGatewayService.doPayment(dropCheckoutPayment);
    } catch (e) {
      debugPrint('Error launching Cashfree PG SDK: $e');
      onError(
        CFErrorResponse("SDK_ERROR", e.toString(), "SDK_INIT_FAILED", "PAYMENT_FAILED"),
        orderId,
      );
    }
  }
}
