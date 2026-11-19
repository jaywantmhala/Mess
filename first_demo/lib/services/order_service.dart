// lib/services/order_service.dart
import 'dart:convert';
import 'dart:io';
import '../utils/app_config.dart';
import '../models/order.dart';
import '../utils/api_client.dart';

const Duration _kOrderTimeout = Duration(seconds: 20);

class OrderService {
  OrderService._();
  static final OrderService instance = OrderService._();

  /// Places an order.
  Future<OrderResult> placeOrder({
    required String paymentMethod,
    required String deliveryAddress,
  }) async {
    try {
      final response = await ApiClient.instance
          .post(
            Uri.parse('$kBaseUrl/api/orders/place'),
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
    try {
      final response = await ApiClient.instance
          .get(
            Uri.parse(
                '$kBaseUrl/api/orders/history?page=$page&limit=$limit'),
          )
          .timeout(_kOrderTimeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] == true && body['data'] != null) {
        final dataMap = body['data'] as Map<String, dynamic>;
        final list = dataMap['orders'] as List? ?? [];
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

  /// Returns detailed information for a single order.
  Future<OrderDetails> getDetails({required int orderId}) async {
    try {
      final response = await ApiClient.instance
          .get(
            Uri.parse('$kBaseUrl/api/orders/details?order_id=$orderId'),
          )
          .timeout(_kOrderTimeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] == true && body['data'] != null) {
        return OrderDetails.fromJson(body['data'] as Map<String, dynamic>);
      }
      throw Exception(body['message'] ?? 'Failed to get order details');
    } catch (e) {
      throw Exception('Failed to load order details: $e');
    }
  }
}
