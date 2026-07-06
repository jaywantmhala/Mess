// lib/services/order_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/app_config.dart';
import '../models/order.dart';
import 'auth_service.dart';

const Duration _kOrderTimeout = Duration(seconds: 20);

class OrderService {
  OrderService._();
  static final OrderService instance = OrderService._();

  Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.instance.getSavedToken();
    return {
      'Content-Type': 'application/json; charset=utf-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Places an order. The backend will:
  /// 1. Deduct available wallet balance
  /// 2. Create the order + order_items
  /// 3. Record the wallet transaction
  /// 4. Clear the cart
  /// Returns an [OrderResult] with full payment breakdown.
  Future<OrderResult> placeOrder({
    required String paymentMethod,
    required String deliveryAddress,
  }) async {
    final headers = await _authHeaders();
    try {
      final response = await http
          .post(
            Uri.parse('$kBaseUrl/api/orders/place'),
            headers: headers,
            body: jsonEncode({
              'payment_method': paymentMethod,
              'delivery_address': deliveryAddress,
            }),
          )
          .timeout(_kOrderTimeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] == true && body['data'] != null) {
        return OrderResult.fromJson(body['data'] as Map<String, dynamic>);
      }
      throw Exception(body['message'] ?? 'Failed to place order');
    } on SocketException {
      throw Exception('No internet connection. Please try again.');
    } catch (e) {
      rethrow;
    }
  }

  /// Returns order history (most recent first).
  Future<List<OrderHistoryItem>> getHistory({
    int page = 1,
    int limit = 10,
  }) async {
    final headers = await _authHeaders();
    try {
      final response = await http
          .get(
            Uri.parse(
                '$kBaseUrl/api/orders/history?page=$page&limit=$limit'),
            headers: headers,
          )
          .timeout(_kOrderTimeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] == true && body['data'] != null) {
        final list = body['data'] as List;
        return list
            .map((o) =>
                OrderHistoryItem.fromJson(o as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
