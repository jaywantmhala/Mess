// lib/services/razorpay_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class RazorpayService {
  static const String contactsEndpoint = 'https://api.razorpay.com/v1/contacts';
  static const String fundAccountsEndpoint = 'https://api.razorpay.com/v1/fund_accounts';
  static const String keyId = 'rzp_live_TM0oXWEH4xu1NQ';
  static const String keySecret = '2MPBgz7jNk1Spez0pTo2f7WQ';
  static const String authorizationHeader =
      'Basic cnpwX2xpdmVfVE0wb1hXRUg0eHUxTlE6Mk1QQmd6N2pOazFTcGV6MHBUbzJmN1dR';

  // Persistent HTTP client with connection pooling & HTTP keep-alive for millisecond-level latency
  static final http.Client _client = http.Client();

  /// Pre-warm TLS connection to Razorpay API in the background
  static void warmup() {
    try {
      _client.head(
        Uri.parse(contactsEndpoint),
        headers: {'Authorization': authorizationHeader},
      ).catchError((_) => http.Response('', 200));
    } catch (_) {}
  }

  /// Creates a Razorpay contact using POST https://api.razorpay.com/v1/contacts
  /// Used when vendor enters name, email, contact during signup.
  static Future<Map<String, dynamic>?> createContact({
    required String name,
    required String email,
    required String contact,
    String type = 'vendor',
    String? referenceId,
    Map<String, dynamic>? notes,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      // Normalize contact to 10 digits
      String cleanContact = contact.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanContact.length > 10) {
        cleanContact = cleanContact.substring(cleanContact.length - 10);
      }

      final payload = {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'contact': cleanContact,
        'type': type,
        if (referenceId != null && referenceId.isNotEmpty)
          'reference_id': referenceId
        else
          'reference_id': 'vendor_${DateTime.now().millisecondsSinceEpoch}',
        'notes': notes ??
            {
              'notes_key_1': 'Tea, Earl Grey, Hot',
              'notes_key_2': 'Tea, Earl Grey… decaf.',
            },
      };

      debugPrint('➡️ Razorpay createContact Request: ${jsonEncode(payload)}');

      final response = await _client
          .post(
            Uri.parse(contactsEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': authorizationHeader,
              'Connection': 'keep-alive',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      stopwatch.stop();
      debugPrint('⚡ [${stopwatch.elapsedMilliseconds}ms] Razorpay createContact [${response.statusCode}]: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        data['latency_ms'] = stopwatch.elapsedMilliseconds;
        return data;
      } else {
        debugPrint('⚠️ Razorpay contact creation failed (${stopwatch.elapsedMilliseconds}ms): ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stack) {
      stopwatch.stop();
      debugPrint('❌ Error in Razorpay createContact (${stopwatch.elapsedMilliseconds}ms): $e\n$stack');
      return null;
    }
  }

  /// Creates a Razorpay Fund Account using POST https://api.razorpay.com/v1/fund_accounts
  /// Optimized for millisecond execution time using persistent HTTP client and keep-alive.
  static Future<Map<String, dynamic>?> createFundAccount({
    required String contactId,
    required String name,
    required String ifsc,
    required String accountNumber,
    String accountType = 'bank_account',
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final payload = {
        'contact_id': contactId.trim(),
        'account_type': accountType,
        'bank_account': {
          'name': name.trim(),
          'ifsc': ifsc.trim().toUpperCase(),
          'account_number': accountNumber.trim(),
        },
      };

      debugPrint('➡️ [0ms] Razorpay createFundAccount Request: ${jsonEncode(payload)}');

      final response = await _client
          .post(
            Uri.parse(fundAccountsEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': authorizationHeader,
              'Connection': 'keep-alive',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 8));

      stopwatch.stop();
      final ms = stopwatch.elapsedMilliseconds;
      debugPrint('⚡ [${ms}ms] Razorpay createFundAccount Response [${response.statusCode}]: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        data['latency_ms'] = ms;
        return data;
      } else {
        debugPrint('⚠️ Razorpay fund account creation failed (${ms}ms): ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stack) {
      stopwatch.stop();
      debugPrint('❌ Error in Razorpay createFundAccount (${stopwatch.elapsedMilliseconds}ms): $e\n$stack');
      return null;
    }
  }
}
