// lib/services/web_payu_service.dart
import 'package:flutter/material.dart';
import 'payment_service.dart';
import 'payu_service.dart';
import 'payu_checkout_screen.dart';

class WebPayUService implements PaymentService {
  @override
  void init() {
    debugPrint('🌐 [WebPayUService] Initializing Web PayU Service...');
  }

  @override
  void dispose() {
    debugPrint('🧹 [WebPayUService] Clearing Web PayU Service.');
  }

  @override
  Future<PayUOrderResult> createOrder(int planId) async {
    return await PayUService.instance.createOrder(planId);
  }

  @override
  Future<void> openCheckout({
    required Map<String, dynamic> options,
    required Function(PayUVerifyResult result) onSuccess,
    required Function(String errorMsg) onError,
    required Function() onCancelled,
  }) async {
    debugPrint('🚀 [WebPayUService] Launching PayU Web Checkout...');
    try {
      final context = WidgetsBinding.instance.focusManager.primaryFocus?.context;
      if (context != null) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => PayUCheckoutScreen(
              options: options,
              onSuccess: onSuccess,
              onError: onError,
              onCancelled: onCancelled,
            ),
          ),
        );
      } else {
        // Direct test verification fallback if context is not attached
        final txnid = options['txnid']?.toString() ?? options['order_id']?.toString() ?? '';
        final planId = options['plan_id'] as int? ?? 1;
        final verifyResult = await PayUService.instance.verifyPayment(
          orderId: txnid,
          razorpayPaymentId: 'payu_$txnid',
          razorpaySignature: options['hash']?.toString() ?? '',
          planId: planId,
        );

        if (verifyResult.success) {
          onSuccess(verifyResult);
        } else {
          onError(verifyResult.message ?? 'Payment failed');
        }
      }
    } catch (e) {
      debugPrint('💥 [WebPayUService] Exception calling Web Checkout: $e');
      onError('Unable to launch PayU Web Checkout: $e');
    }
  }

  @override
  Future<PayUVerifyResult> verifyPayment({
    required String orderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required int planId,
    String? internalTransactionId,
  }) async {
    return await PayUService.instance.verifyPayment(
      orderId: orderId,
      razorpayPaymentId: razorpayPaymentId,
      razorpaySignature: razorpaySignature,
      planId: planId,
      internalTransactionId: internalTransactionId,
    );
  }
}

typedef WebRazorpayService = WebPayUService;
