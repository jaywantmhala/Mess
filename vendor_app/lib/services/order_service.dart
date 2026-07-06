// lib/services/order_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/order.dart';
import '../utils/app_config.dart';

class OrderService {
  OrderService._();
  static final OrderService instance = OrderService._();

  final Duration _timeout = const Duration(seconds: 15);

  /// Fetch orders placed for hotels owned by this vendor
  Future<List<VendorOrder>> getOrders() async {
    try {
      final token = await AuthService.instance.getSavedToken();
      if (token == null) return [];

      final response = await http
          .get(
            Uri.parse('$kBaseUrl/orders'),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] == true) {
        final list = body['data'] as List;
        return list
            .map((item) => VendorOrder.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting vendor orders: $e');
      return [];
    }
  }

  /// Update order status
  Future<bool> updateOrderStatus(int orderId, String status) async {
    try {
      final token = await AuthService.instance.getSavedToken();
      if (token == null) return false;

      final response = await http
          .post(
            Uri.parse('$kBaseUrl/orders/status'),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'order_id': orderId,
              'status': status,
            }),
          )
          .timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['success'] == true;
    } catch (e) {
      print('Error updating order status: $e');
      return false;
    }
  }
}
