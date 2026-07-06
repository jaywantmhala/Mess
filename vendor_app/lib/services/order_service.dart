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

  /// Get online available drivers
  Future<List<DriverOnline>> getOnlineDrivers() async {
    try {
      final token = await AuthService.instance.getSavedToken();
      print('[OrderService] getOnlineDrivers: token is ${token != null ? "not null" : "null"}');
      if (token == null) return [];

      final url = '$kBaseUrl/drivers/online';
      print('[OrderService] getOnlineDrivers: GET $url');
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_timeout);

      print('[OrderService] getOnlineDrivers: Status Code: ${response.statusCode}');
      print('[OrderService] getOnlineDrivers: Response Body: ${response.body}');

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] == true) {
        final list = body['data']['drivers'] as List? ?? [];
        return list
            .map((item) => DriverOnline.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('[OrderService] Error getting online drivers: $e');
      return [];
    }
  }

  /// Assign driver to an order
  Future<bool> assignDriver(int orderId, int driverId) async {
    try {
      final token = await AuthService.instance.getSavedToken();
      if (token == null) return false;

      final response = await http
          .post(
            Uri.parse('$kBaseUrl/orders/assign'),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'order_id': orderId,
              'driver_id': driverId,
            }),
          )
          .timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['success'] == true;
    } catch (e) {
      print('Error assigning driver: $e');
      return false;
    }
  }
}

class DriverOnline {
  final int id;
  final String fullName;
  final String vehicleNumber;
  final String phoneNumber;
  final int activeOrderCount;
  final int maxCapacity;

  DriverOnline({
    required this.id,
    required this.fullName,
    required this.vehicleNumber,
    required this.phoneNumber,
    required this.activeOrderCount,
    required this.maxCapacity,
  });

  factory DriverOnline.fromJson(Map<String, dynamic> json) {
    return DriverOnline(
      id: int.tryParse(json['id'].toString()) ?? 0,
      fullName: json['full_name'] as String? ?? '',
      vehicleNumber: json['vehicle_number'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
      activeOrderCount: int.tryParse(json['active_order_count'].toString()) ?? 0,
      maxCapacity: int.tryParse(json['max_capacity'].toString()) ?? 3,
    );
  }
}
