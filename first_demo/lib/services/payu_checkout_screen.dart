// lib/services/payu_checkout_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'payu_service.dart';

import '../utils/app_config.dart';

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
        final intentMatch = RegExp(r'intent://(.*?)#Intent;').firstMatch(rawUrl);
        if (intentMatch != null && intentMatch.group(1) != null) {
          launchableUrl = 'upi://${intentMatch.group(1)}';
        } else {
          launchableUrl = rawUrl.replaceFirst('intent://', 'upi://').split('#Intent;')[0];
        }
      }

      final uri = Uri.parse(launchableUrl);
      debugPrint('🚀 [PayU Checkout] Launching URI: $uri');

      bool launched = false;
      if (await canLaunchUrl(uri)) {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      if (!launched) {
        // Fallback launch attempt with force external app mode
        final rawUri = Uri.parse(rawUrl);
        await launchUrl(rawUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('❌ [PayU Checkout] Error launching UPI app: $e');
    }
  }

  void _initWebView() {
    final action = widget.options['action']?.toString() ??
        (kUseLocalUrl ? 'https://test.payu.in/_payment' : 'https://secure.payu.in/_payment');
    final key = widget.options['key']?.toString() ?? PayUService.payuMerchantKey;
    final txnid = widget.options['txnid']?.toString() ?? widget.options['order_id']?.toString() ?? '';
    final amount = widget.options['amount']?.toString() ?? '199.00';
    final productinfo = widget.options['productinfo']?.toString() ?? 'Subscription Plan';
    final firstname = widget.options['firstname']?.toString() ?? 'Customer';
    final email = widget.options['email']?.toString() ?? 'customer@hungrilyfoods.com';
    final phone = widget.options['phone']?.toString() ?? '9876543210';
    final hash = widget.options['hash']?.toString() ?? '';
    final surl = widget.options['surl']?.toString() ?? '$kBaseUrl/api/customer/payu/success';
    final furl = widget.options['furl']?.toString() ?? '$kBaseUrl/api/customer/payu/failure';
    final udf1 = widget.options['udf1']?.toString() ?? '';
    final udf2 = widget.options['udf2']?.toString() ?? '';

    final htmlContent = '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>PayU Payment</title>
      <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; text-align: center; padding-top: 50px; background: #fafafa; }
        .spinner { border: 4px solid #f3f3f3; border-top: 4px solid #F58220; border-radius: 50%; width: 40px; height: 40px; animation: spin 1s linear infinite; margin: 20px auto; }
        @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
      </style>
    </head>
    <body onload="document.forms['payuForm'].submit();">
      <h2>Redirecting to PayU Gateway...</h2>
      <div class="spinner"></div>
      <form name="payuForm" method="post" action="$action">
        <input type="hidden" name="key" value="$key" />
        <input type="hidden" name="txnid" value="$txnid" />
        <input type="hidden" name="amount" value="$amount" />
        <input type="hidden" name="productinfo" value="$productinfo" />
        <input type="hidden" name="firstname" value="$firstname" />
        <input type="hidden" name="email" value="$email" />
        <input type="hidden" name="phone" value="$phone" />
        <input type="hidden" name="surl" value="$surl" />
        <input type="hidden" name="furl" value="$furl" />
        <input type="hidden" name="udf1" value="$udf1" />
        <input type="hidden" name="udf2" value="$udf2" />
        <input type="hidden" name="hash" value="$hash" />
      </form>
    </body>
    </html>
    ''';

    _controller = WebViewController()
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
                (!lowerUrl.startsWith('http://') && !lowerUrl.startsWith('https://') && !lowerUrl.startsWith('about:'))) {
              _launchUpiApp(url);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(htmlContent);
  }

  bool _checkUrl(String url) {
    final lowerUrl = url.toLowerCase();

    if (lowerUrl.contains('hungrily://payment_success') ||
        lowerUrl.contains('payu/success') ||
        lowerUrl.contains('status=success') ||
        lowerUrl.contains('txncdn.payubiz.in') ||
        lowerUrl.contains('newresponse') ||
        lowerUrl.contains('mihpayid=')) {
      if (!_handled) {
        _handled = true;
        if (mounted) {
          setState(() {
            _isVerifying = true;
            _isLoading = false;
          });
        }
        _handleSuccess();
      }
      return true;
    } else if (lowerUrl.contains('hungrily://payment_failure') ||
        lowerUrl.contains('payu/failure') ||
        lowerUrl.contains('status=failure')) {
      if (!_handled) {
        _handled = true;
        if (mounted) {
          setState(() {
            _isVerifying = true;
            _isLoading = false;
          });
        }
        _handleFailure('Payment failed or cancelled on PayU gateway.');
      }
      return true;
    }
    return false;
  }

  Future<void> _handleSuccess() async {
    final txnid = widget.options['txnid']?.toString() ?? widget.options['order_id']?.toString() ?? '';
    final planId = widget.options['plan_id'] as int? ?? 1;

    final verifyRes = await PayUService.instance.verifyPayment(
      orderId: txnid,
      razorpayPaymentId: 'payu_$txnid',
      razorpaySignature: widget.options['hash']?.toString() ?? '',
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
        title: const Text('PayU Checkout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF58220),
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
              child: CircularProgressIndicator(color: Color(0xFFF58220)),
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
                      const Icon(Icons.payment, size: 64, color: Color(0xFFF58220)),
                      const SizedBox(height: 16),
                      Text(
                        'PayU Payment Gateway',
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
                            label: const Text('Proceed to Official PayU Gateway Page'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF58220),
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
