// lib/services/order_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/order.dart';
import '../utils/app_config.dart';
import '../utils/api_client.dart';

class GetOrdersResult {
  final bool isOnline;
  final List<VendorOrder> orders;
  GetOrdersResult({required this.isOnline, required this.orders});
}

class OrderService {
  OrderService._();
  static final OrderService instance = OrderService._();

  final Duration _timeout = const Duration(seconds: 15);

  /// Fetch orders placed for hotels owned by this vendor
  Future<GetOrdersResult> getOrders({String? date}) async {
    try {
      String url = '$kBaseUrl/orders';
      if (date != null && date.isNotEmpty) {
        url += '?date=$date';
      }
      final response = await ApiClient.instance
          .get(Uri.parse(url))
          .timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>;
        final isOnline = data['is_online'] == true || data['is_online'] == 1;
        final list = data['orders'] as List? ?? [];
        final orders = list
            .map((item) => VendorOrder.fromJson(item as Map<String, dynamic>))
            .toList();
        return GetOrdersResult(isOnline: isOnline, orders: orders);
      }
      return GetOrdersResult(isOnline: true, orders: []);
    } catch (e) {
      print('Error getting vendor orders: $e');
      return GetOrdersResult(isOnline: true, orders: []);
    }
  }

  /// Fetch a single order by ID (helper wrapping getOrders)
  Future<VendorOrder?> getOrderById(int orderId) async {
    try {
      final result = await getOrders();
      for (final order in result.orders) {
        if (order.orderId == orderId) {
          return order;
        }
      }
      return null;
    } catch (e) {
      print('Error getting order by ID: $e');
      return null;
    }
  }

  /// Fetch live order tracking details (driver location, customer destination, eta, etc.)
  Future<Map<String, dynamic>?> trackOrder(int orderId) async {
    try {
      final url = '$kBaseUrl/orders/track?order_id=$orderId';
      final response = await ApiClient.instance
          .get(Uri.parse(url))
          .timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] == true && body['data'] != null) {
        return body['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error tracking order #$orderId: $e');
      return null;
    }
  }

  /// Update vendor status
  Future<bool> updateVendorStatus(bool isOnline) async {
    try {
      final token = await AuthService.instance.getSavedToken();
      if (token == null) return false;

      final response = await http
          .post(
            Uri.parse('$kBaseUrl/status'),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'is_online': isOnline ? 1 : 0,
            }),
          )
          .timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['success'] == true;
    } catch (e) {
      print('Error updating vendor status: $e');
      return false;
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

  /// Add a new driver associated with this vendor
  /// Dispatches onboarding credentials (with original unencrypted password)
  /// directly via Click2Api WhatsApp API on backend.
  Future<Map<String, dynamic>> addDriver({
    required String fullName,
    required String email,
    required String password,
    required String vehicleNumber,
    required String phoneNumber,
  }) async {
    try {
      final token = await AuthService.instance.getSavedToken();
      if (token == null) {
        return {'success': false, 'message': 'Vendor token expired. Please log in again.'};
      }

      final response = await http
          .post(
            Uri.parse('$kBaseUrl/drivers/add'),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'full_name': fullName,
              'email': email,
              'password': password,
              'vehicle_number': vehicleNumber,
              'phone_number': phoneNumber,
            }),
          )
          .timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = (body['data'] as Map<String, dynamic>?) ?? {};
      return {
        'success': body['success'] == true,
        'message': body['message'] ?? (body['success'] == true ? 'Driver created successfully!' : 'Failed to add driver.'),
        'whatsapp_sent': data['whatsapp_sent'] == true,
        'whatsapp_message': data['whatsapp_message']?.toString() ?? '',
        'data': data,
      };
    } catch (e) {
      print('Error adding driver: $e');
      return {'success': false, 'message': 'Network error. Please try again.'};
    }
  }

  /// Send a dynamic WhatsApp message to a driver using the backend Click2Api Meta WhatsApp API
  Future<Map<String, dynamic>> sendDriverWhatsAppApi({
    int? driverId,
    required String phoneNumber,
    required String message,
    String? driverName,
  }) async {
    try {
      final token = await AuthService.instance.getSavedToken();
      if (token == null) {
        return {'success': false, 'message': 'Vendor token expired. Please log in again.'};
      }

      final response = await http
          .post(
            Uri.parse('$kBaseUrl/drivers/whatsapp'),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              if (driverId != null && driverId > 0) 'driver_id': driverId,
              'phone': phoneNumber,
              'message': message,
              if (driverName != null) 'driver_name': driverName,
            }),
          )
          .timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'success': body['success'] == true,
        'message': body['message'] ?? (body['success'] == true ? 'WhatsApp message dispatched!' : 'Failed to send WhatsApp message.'),
      };
    } catch (e) {
      print('Error sending driver WhatsApp: $e');
      return {'success': false, 'message': 'Network error while calling WhatsApp API.'};
    }
  }

  /// Fetch all drivers associated with this vendor
  Future<List<VendorDriver>> getVendorDrivers() async {
    try {
      final token = await AuthService.instance.getSavedToken();
      if (token == null) return [];

      final response = await http
          .get(
            Uri.parse('$kBaseUrl/drivers/list'),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] == true) {
        final list = body['data']['drivers'] as List? ?? [];
        return list
            .map((item) => VendorDriver.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting vendor drivers: $e');
      return [];
    }
  }
}

class VendorDriver {
  final int id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String vehicleNumber;
  final bool isOnline;
  final int maxCapacity;
  final int activeOrderCount;
  final String createdAt;

  VendorDriver({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.vehicleNumber,
    required this.isOnline,
    required this.maxCapacity,
    required this.activeOrderCount,
    required this.createdAt,
  });

  factory VendorDriver.fromJson(Map<String, dynamic> json) {
    return VendorDriver(
      id: int.tryParse(json['id'].toString()) ?? 0,
      fullName: json['full_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
      vehicleNumber: json['vehicle_number']?.toString() ?? '',
      isOnline: json['is_online'] == true || json['is_online'] == 1,
      maxCapacity: int.tryParse(json['max_capacity'].toString()) ?? 5,
      activeOrderCount: int.tryParse(json['active_order_count'].toString()) ?? 0,
      createdAt: json['created_at']?.toString() ?? '',
    );
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
