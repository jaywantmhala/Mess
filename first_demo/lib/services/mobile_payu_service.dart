// lib/services/mobile_payu_service.dart
import 'package:flutter/material.dart';
import 'payment_service.dart';
import 'payu_service.dart';
import 'payu_checkout_screen.dart';
import '../main.dart';

class MobilePayUService implements PaymentService {
  @override
  void init() {
    debugPrint('📱 [MobilePayUService] Initializing Mobile PayU Service...');
  }

  @override
  void dispose() {
    debugPrint('🧹 [MobilePayUService] Clearing Mobile PayU Service.');
  }

  @override
  Future<PayUOrderResult> createOrder(int planId, {double? amount}) async {
    return await PayUService.instance.createOrder(planId, amount: amount);
  }

  @override
  Future<void> openCheckout({
    required Map<String, dynamic> options,
    required Function(PayUVerifyResult result) onSuccess,
    required Function(String errorMsg) onError,
    required Function() onCancelled,
  }) async {
    debugPrint('🚀 [MobilePayUService] Opening PayU Checkout UI...');
    try {
      final context = _getNavigatorContext();
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
        // Fallback simulation if BuildContext is unavailable
        final txnid = options['txnid']?.toString() ?? options['order_id']?.toString() ?? '';
        final planId = options['plan_id'] as int? ?? 1;
        final res = await PayUService.instance.verifyPayment(
          orderId: txnid,
          razorpayPaymentId: 'payu_$txnid',
          razorpaySignature: options['hash']?.toString() ?? '',
          planId: planId,
        );
        if (res.success) {
          onSuccess(res);
        } else {
          onError(res.message ?? 'Payment failed');
        }
      }
    } catch (e) {
      debugPrint('💥 [MobilePayUService] Exception opening PayU Checkout: $e');
      onError('Unable to open PayU Checkout: $e');
    }
  }

  BuildContext? _getNavigatorContext() {
    return navigatorKey.currentContext ?? WidgetsBinding.instance.focusManager.primaryFocus?.context;
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

typedef MobileRazorpayService = MobilePayUService;
