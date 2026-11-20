// lib/services/web_payu_service_stub.dart
import 'payment_service.dart';
import 'payu_service.dart';

class WebPayUService implements PaymentService {
  @override
  void init() {}

  @override
  void dispose() {}

  @override
  Future<PayUOrderResult> createOrder(int planId, {double? amount}) async {
    return PayUOrderResult(
      success: false,
      message: 'Web PayU is not supported on native mobile platform.',
    );
  }

  @override
  Future<void> openCheckout({
    required Map<String, dynamic> options,
    required Function(PayUVerifyResult result) onSuccess,
    required Function(String errorMsg) onError,
    required Function() onCancelled,
  }) async {
    onError('Web PayU is not supported on native mobile platform.');
  }

  @override
  Future<PayUVerifyResult> verifyPayment({
    required String orderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required int planId,
    String? internalTransactionId,
  }) async {
    return PayUVerifyResult(
      success: false,
      message: 'Web PayU is not supported on native mobile platform.',
    );
  }
}

typedef WebRazorpayService = WebPayUService;
