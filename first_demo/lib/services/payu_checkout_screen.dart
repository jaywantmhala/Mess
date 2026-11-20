// lib/services/payu_checkout_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'payu_service.dart';

class PayUCheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> options;
  final Function(PayUVerifyResult result) onSuccess;
  final Function(String errorMsg) onError;
  final Function() onCancelled;

  const PayUCheckoutScreen({
    super.key,
    required this.options,
    required this.onSuccess,
    required this.onError,
    required this.onCancelled,
  });

  @override
  State<PayUCheckoutScreen> createState() => _PayUCheckoutScreenState();
}

class _PayUCheckoutScreenState extends State<PayUCheckoutScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _isVerifying = false;
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initWebView();
    }
  }

  Future<void> _launchUpiApp(String rawUrl) async {
    debugPrint('📱 [PayU Checkout] Launching UPI App for URL: $rawUrl');
    try {
      String launchableUrl = rawUrl;

      // Convert intent:// scheme to standard upi:// scheme if needed
      if (rawUrl.startsWith('intent://')) {
        if (rawUrl.contains('data=upi')) {
          final dataMatch = RegExp(r'data=(upi[^;&]+)').firstMatch(rawUrl);
          if (dataMatch != null && dataMatch.group(1) != null) {
            launchableUrl = Uri.decodeComponent(dataMatch.group(1)!);
          }
        } else {
          final intentMatch = RegExp(r'intent://(.*?)#Intent;').firstMatch(rawUrl);
          if (intentMatch != null && intentMatch.group(1) != null) {
            launchableUrl = 'upi://${intentMatch.group(1)}';
          } else {
            launchableUrl = rawUrl.replaceFirst('intent://', 'upi://').split('#Intent;')[0];
          }
        }
      }

      final uri = Uri.parse(launchableUrl);
      debugPrint('🚀 [PayU Checkout] Launching URI: $uri');

      bool launched = false;
      try {
        if (await canLaunchUrl(uri)) {
          launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        debugPrint('⚠️ canLaunchUrl failed: $e');
      }

      if (!launched) {
        // Fallback launch attempt with force external app mode
        try {
          final rawUri = Uri.parse(rawUrl);
          await launchUrl(rawUri, mode: LaunchMode.externalApplication);
        } catch (e2) {
          debugPrint('❌ Fallback launch failed: $e2');
        }
      }
    } catch (e) {
      debugPrint('❌ [PayU Checkout] Error launching UPI app: $e');
    }
  }

  void _initWebView() {
    final key = widget.options['key_id']?.toString() ?? widget.options['key']?.toString() ?? PayUService.payuMerchantKey;
    final orderId = widget.options['order_id']?.toString() ?? widget.options['txnid']?.toString() ?? '';
    final amountPaise = widget.options['amount_paise']?.toString() ??
        ((double.tryParse(widget.options['amount']?.toString() ?? '199.0') ?? 199.0) * 100).toInt().toString();
    final description = widget.options['description']?.toString() ?? widget.options['productinfo']?.toString() ?? 'Hungrily Order';
    final customerName = widget.options['customer_name']?.toString() ?? widget.options['firstname']?.toString() ?? 'Customer';
    final customerEmail = widget.options['email']?.toString() ?? 'customer@hungrilyfoods.com';
    final customerPhone = widget.options['phone']?.toString() ?? '9876543210';

    final htmlContent = '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
      <title>Razorpay Checkout</title>
      <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; text-align: center; padding-top: 50px; background: #fafafa; }
        .spinner { border: 4px solid #f3f3f3; border-top: 4px solid #F58220; border-radius: 50%; width: 44px; height: 44px; animation: spin 1s linear infinite; margin: 20px auto; }
        @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
      </style>
      <script src="https://checkout.razorpay.com/v1/checkout.js"></script>
    </head>
    <body>
      <h2>Opening Razorpay Gateway...</h2>
      <div class="spinner"></div>
      <script>
        function openCheckout() {
          var options = {
            "key": "$key",
            "amount": "$amountPaise",
            "currency": "INR",
            "name": "Hungrily Foods",
            "description": "$description",
            "order_id": "$orderId",
            "method": {
              "netbanking": true,
              "card": true,
              "wallet": true,
              "upi": true
            },
            "config": {
              "display": {
                "blocks": {
                  "upi": {
                    "name": "Pay via UPI (GPay, PhonePe, Paytm)",
                    "instruments": [
                      {
                        "method": "upi"
                      }
                    ]
                  }
                },
                "sequence": ["block.upi", "block.other"],
                "preferences": {
                  "show_default_blocks": true
                }
              }
            },
            "handler": function (response) {
              var pid = response.razorpay_payment_id || '';
              var oid = response.razorpay_order_id || '$orderId';
              var sig = response.razorpay_signature || '';
              window.location.href = "hungrily://payment_success?razorpay_payment_id=" + encodeURIComponent(pid) + "&razorpay_order_id=" + encodeURIComponent(oid) + "&razorpay_signature=" + encodeURIComponent(sig);
            },
            "prefill": {
              "name": "$customerName",
              "email": "$customerEmail",
              "contact": "$customerPhone"
            },
            "theme": {
              "color": "#F58220"
            },
            "modal": {
              "ondismiss": function() {
                window.location.href = "hungrily://payment_cancelled";
              }
            }
          };
          try {
            var rzp = new Razorpay(options);
            rzp.on('payment.failed', function (resp) {
              var errMsg = (resp && resp.error && resp.error.description) ? resp.error.description : 'Payment Failed';
              window.location.href = "hungrily://payment_failure?error=" + encodeURIComponent(errMsg);
            });
            rzp.open();
          } catch (e) {
            window.location.href = "hungrily://payment_failure?error=" + encodeURIComponent(e.message || 'Razorpay checkout error');
          }
        }
        window.onload = function() {
          openCheckout();
        };
      </script>
    </body>
    </html>
    ''';

    _controller = WebViewController()
      ..setUserAgent("Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36")
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            _checkUrl(url);
          },
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoading = false);
            _checkUrl(url);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('PayU WebView Error: ${error.description}');
            final errUrl = error.url?.toLowerCase() ?? '';
            if (errUrl.startsWith('hungrily://') || errUrl.contains('payu') || errUrl.contains('payubiz') || errUrl.contains('mihpayid=')) {
              _checkUrl(error.url!);
            } else if (error.description.contains('ERR_CLEARTEXT_NOT_PERMITTED')) {
              _checkUrl('hungrily://payment_success');
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            debugPrint('🧭 [PayU WebView] Navigation Request: $url');

            final lowerUrl = url.toLowerCase();

            if (lowerUrl.startsWith('hungrily://') ||
                lowerUrl.contains('payu/success') ||
                lowerUrl.contains('status=success') ||
                lowerUrl.contains('payu/failure') ||
                lowerUrl.contains('status=failure') ||
                lowerUrl.contains('txncdn.payubiz.in') ||
                lowerUrl.contains('newresponse') ||
                lowerUrl.contains('mihpayid=')) {
              _checkUrl(url);
              return NavigationDecision.prevent;
            }

            if (lowerUrl.startsWith('upi://') ||
                lowerUrl.startsWith('intent://') ||
                lowerUrl.startsWith('phonepe://') ||
                lowerUrl.startsWith('paytmmp://') ||
                lowerUrl.startsWith('gpay://') ||
                lowerUrl.startsWith('tez://') ||
                lowerUrl.startsWith('bhim://') ||
                lowerUrl.startsWith('cred://') ||
                lowerUrl.startsWith('amazonpay://') ||
                lowerUrl.startsWith('whatsapp://') ||
                (!lowerUrl.startsWith('http://') && !lowerUrl.startsWith('https://') && !lowerUrl.startsWith('about:'))) {
              _launchUpiApp(url);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(htmlContent, baseUrl: 'https://hungrilyfoods.com');
  }

  bool _checkUrl(String url) {
    final lowerUrl = url.toLowerCase();

    if (lowerUrl.contains('hungrily://payment_success') ||
        lowerUrl.contains('razorpay_payment_id=')) {
      if (!_handled) {
        _handled = true;
        if (mounted) {
          setState(() {
            _isVerifying = true;
            _isLoading = false;
          });
        }
        _handleSuccess(url);
      }
      return true;
    } else if (lowerUrl.contains('hungrily://payment_cancelled')) {
      _handleCancel();
      return true;
    } else if (lowerUrl.contains('hungrily://payment_failure') ||
        lowerUrl.contains('status=failure')) {
      if (!_handled) {
        _handled = true;
        if (mounted) {
          setState(() {
            _isVerifying = true;
            _isLoading = false;
          });
        }
        final uri = Uri.tryParse(url);
        final errMsg = uri?.queryParameters['error'] ?? 'Payment failed or cancelled.';
        _handleFailure(errMsg);
      }
      return true;
    }
    return false;
  }

  Future<void> _handleSuccess(String url) async {
    final uri = Uri.tryParse(url);
    final paymentId = uri?.queryParameters['razorpay_payment_id'] ??
        widget.options['razorpay_payment_id']?.toString() ??
        'pay_${DateTime.now().millisecondsSinceEpoch}';
    final orderId = uri?.queryParameters['razorpay_order_id'] ??
        widget.options['order_id']?.toString() ??
        widget.options['txnid']?.toString() ??
        '';
    final signature = uri?.queryParameters['razorpay_signature'] ??
        widget.options['razorpay_signature']?.toString() ??
        '';
    final planId = widget.options['plan_id'] as int? ?? 1;

    final verifyRes = await PayUService.instance.verifyPayment(
      orderId: orderId,
      razorpayPaymentId: paymentId,
      razorpaySignature: signature,
      planId: planId,
    );

    if (!mounted) return;
    Navigator.of(context).pop();

    if (verifyRes.success) {
      widget.onSuccess(verifyRes);
    } else {
      widget.onError(verifyRes.message ?? 'Server verification failed.');
    }
  }

  void _handleFailure(String msg) {
    if (!mounted) return;
    Navigator.of(context).pop();
    widget.onError(msg);
  }

  void _submitWebForm() {
    debugPrint('Web submission form initiated.');
  }

  void _handleCancel() {
    if (_handled) return;
    _handled = true;
    Navigator.of(context).pop();
    widget.onCancelled();
  }

  @override
  Widget build(BuildContext context) {
    final amountStr = widget.options['amount']?.toString() ?? '199.00';
    final planName = widget.options['productinfo']?.toString() ?? 'Subscription Plan';
    final txnid = widget.options['txnid']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Razorpay Checkout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0C2340),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _handleCancel,
        ),
      ),
      body: Stack(
        children: [
          if (!_isVerifying && _controller != null) WebViewWidget(controller: _controller!),
          if (_isVerifying)
            Container(
              color: Colors.white,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: Color(0xFFECFDF5),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF10B981),
                            strokeWidth: 3.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Verifying Payment...',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please do not close the app or press back.\nConfirming transaction with server...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF0C2340)),
            ),
          // Fallback UI overlay for testing or Web mode
          if (kIsWeb)
            Center(
              child: Card(
                elevation: 8,
                margin: const EdgeInsets.all(24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.payment, size: 64, color: Color(0xFF0C2340)),
                      const SizedBox(height: 16),
                      Text(
                        'Razorpay Payment Gateway',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('Plan: $planName'),
                      Text('Amount: ₹$amountStr'),
                      Text('Txn ID: $txnid', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 24),
                      Column(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _submitWebForm,
                            icon: const Icon(Icons.open_in_browser),
                            label: const Text('Proceed to Official Razorpay Gateway'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0C2340),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 44),
                            ),
                          ),
                          Center(
                            child: OutlinedButton(
                              onPressed: _handleCancel,
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Cancel Payment'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
