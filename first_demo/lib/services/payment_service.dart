// lib/services/payment_service.dart
import 'package:flutter/foundation.dart';
import 'payu_service.dart';
import 'web_payu_service_stub.dart'
    if (dart.library.js_util) 'web_payu_service.dart';
import 'mobile_payu_service.dart';

abstract class PaymentService {
  static PaymentService? _instance;

  static PaymentService get instance {
    if (_instance == null) {
      if (kIsWeb) {
        _instance = WebPayUService();
      } else {
        _instance = MobilePayUService();
      }
    }
    return _instance!;
  }

  /// Initialize any required listeners or instances
  void init();

  /// Dispose/clear instances
  void dispose();

  /// Create PayU Order on PHP Backend API
  Future<PayUOrderResult> createOrder(int planId);

  /// Open PayU Checkout Window/Popup
  Future<void> openCheckout({
    required Map<String, dynamic> options,
    required Function(PayUVerifyResult result) onSuccess,
    required Function(String errorMsg) onError,
    required Function() onCancelled,
  });

  /// Verify Payment on PHP Backend API
  Future<PayUVerifyResult> verifyPayment({
    required String orderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required int planId,
    String? internalTransactionId,
  });
}
