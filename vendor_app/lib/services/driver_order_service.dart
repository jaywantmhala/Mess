// lib/services/driver_order_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'driver_auth_service.dart';
import '../utils/app_config.dart';

final String _baseUrl = '$kApiHost/driver/orders';
const Duration _timeout = Duration(seconds: 15);

class DriverOrder {
  final int orderId;
  final String status;
  final double grandTotal;
  final String paymentMethod;
  final String deliveryAddress;
  final String createdAt;
  final String hotelName;
  final String hotelAddress;
  final double hotelLat;
  final double hotelLng;
  final double customerLat;
  final double customerLng;
  final String customerName;
  final String customerPhone;

  const DriverOrder({
    required this.orderId,
    required this.status,
    required this.grandTotal,
    required this.paymentMethod,
    required this.deliveryAddress,
    required this.createdAt,
    required this.hotelName,
    required this.hotelAddress,
    required this.hotelLat,
    required this.hotelLng,
    required this.customerLat,
    required this.customerLng,
    required this.customerName,
    required this.customerPhone,
  });

  factory DriverOrder.fromJson(Map<String, dynamic> json) {
    return DriverOrder(
      orderId: int.tryParse(json['order_id'].toString()) ?? 0,
      status: json['status'] as String? ?? '',
      grandTotal: double.tryParse(json['grand_total'].toString()) ?? 0.0,
      paymentMethod: json['payment_method'] as String? ?? 'UPI',
      deliveryAddress: json['delivery_address'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      hotelName: json['hotel_name'] as String? ?? '',
      hotelAddress: json['hotel_address'] as String? ?? '',
      hotelLat: double.tryParse(json['hotel_lat'].toString()) ?? 0.0,
      hotelLng: double.tryParse(json['hotel_lng'].toString()) ?? 0.0,
      customerLat: double.tryParse(json['customer_lat'].toString()) ?? 0.0,
      customerLng: double.tryParse(json['customer_lng'].toString()) ?? 0.0,
      customerName: json['customer_name'] as String? ?? '',
      customerPhone: json['customer_phone'] as String? ?? '',
    );
  }
}

class DriverOrderService {
  DriverOrderService._();
  static final DriverOrderService instance = DriverOrderService._();

  Future<List<DriverOrder>> fetchOrders() async {
    try {
      final token = await DriverAuthService.instance.getSavedToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] == true) {
        final list = (body['data']['orders'] as List? ?? []);
        return list.map((item) => DriverOrder.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> updateOrderStatus({
    required int orderId,
    required String status,
    String? otp,
  }) async {
    try {
      final token = await DriverAuthService.instance.getSavedToken();
      if (token == null) return {'success': false, 'message': 'No token'};

      final response = await http.post(
        Uri.parse('$_baseUrl/status'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'order_id': orderId,
          'status': status,
          if (otp != null) 'otp': otp,
        }),
      ).timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> verifyTiffinOtp({
    required int orderId,
    required String otp,
  }) async {
    try {
      final token = await DriverAuthService.instance.getSavedToken();
      if (token == null) {
        return {'success': false, 'message': 'No driver token found.'};
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/tiffin_verify'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'order_id': orderId,
          'otp': otp,
        }),
      ).timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body;
    } catch (e) {
      return {'success': false, 'message': 'Failed to verify OTP: $e'};
    }
  }

  Future<Map<String, dynamic>> checkPendingTiffin() async {
    try {
      final token = await DriverAuthService.instance.getSavedToken();
      if (token == null) {
        return {'success': false, 'message': 'No driver token found.'};
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/pending_tiffin'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body;
    } catch (e) {
      return {'success': false, 'message': 'Failed to check pending tiffin: $e'};
    }
  }
}
