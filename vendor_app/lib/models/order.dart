// lib/models/order.dart
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

class VendorOrder {
  final int orderId;
  final int customerId;
  final int hotelId;
  final double subtotal;
  final double deliveryFee;
  final double taxAmount;
  final double grandTotal;
  final double walletDeducted;
  final String paymentMethod;
  final String deliveryAddress;
  String status;
  final String createdAt;
  final String customerName;
  final String customerEmail;
  final String hotelName;
  final int? driverId;
  final String? driverName;
  final String? driverPhone;
  final String? vehicleNumber;
  final double? driverLatitude;
  final double? driverLongitude;
  final bool driverIsOnline;
  final double? hotelLatitude;
  final double? hotelLongitude;
  final String? hotelAddress;
  final String? customerPhone;
  final double? customerLatitude;
  final double? customerLongitude;
  final double? distanceKm;
  final String mealType; // 'Lunch' or 'Dinner'
  final List<VendorOrderItem> items;

  bool get isDriverAssigned => (driverId != null && driverId! > 0) || ['assigned', 'accepted_by_driver', 'picked_up', 'arrived_at_customer', 'completed'].contains(status);

  double get dropDistanceKm {
    if (distanceKm != null && distanceKm! > 0) return distanceKm!;
    if (hotelLatitude != null && hotelLatitude != 0 && hotelLongitude != null && hotelLongitude != 0 &&
        customerLatitude != null && customerLatitude != 0 && customerLongitude != null && customerLongitude != 0) {
      return Geolocator.distanceBetween(hotelLatitude!, hotelLongitude!, customerLatitude!, customerLongitude!) / 1000.0;
    }
    return 0.0;
  }

  VendorOrder({
    required this.orderId,
    required this.customerId,
    required this.hotelId,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.vehicleNumber,
    this.driverLatitude,
    this.driverLongitude,
    this.driverIsOnline = false,
    this.hotelLatitude,
    this.hotelLongitude,
    this.hotelAddress,
    this.customerPhone,
    this.customerLatitude,
    this.customerLongitude,
    this.distanceKm,
    required this.subtotal,
    required this.deliveryFee,
    required this.taxAmount,
    required this.grandTotal,
    required this.walletDeducted,
    required this.paymentMethod,
    required this.deliveryAddress,
    required this.status,
    required this.createdAt,
    required this.customerName,
    required this.customerEmail,
    required this.hotelName,
    this.mealType = 'Lunch',
    required this.items,
  });

  factory VendorOrder.fromJson(Map<String, dynamic> json) {
    return VendorOrder(
      orderId: int.tryParse((json['order_id'] ?? 0).toString()) ?? 0,
      customerId: int.tryParse((json['customer_id'] ?? 0).toString()) ?? 0,
      hotelId: int.tryParse((json['hotel_id'] ?? 0).toString()) ?? 0,
      driverId: json['driver_id'] != null ? int.tryParse(json['driver_id'].toString()) : null,
      driverName: json['driver_name']?.toString(),
      driverPhone: json['driver_phone']?.toString(),
      vehicleNumber: json['vehicle_number']?.toString(),
      driverLatitude: json['driver_latitude'] != null ? double.tryParse(json['driver_latitude'].toString()) : null,
      driverLongitude: json['driver_longitude'] != null ? double.tryParse(json['driver_longitude'].toString()) : null,
      driverIsOnline: json['driver_is_online'] == true || json['driver_is_online'] == 1 || json['driver_is_online'] == '1',
      hotelLatitude: json['hotel_latitude'] != null ? double.tryParse(json['hotel_latitude'].toString()) : null,
      hotelLongitude: json['hotel_longitude'] != null ? double.tryParse(json['hotel_longitude'].toString()) : null,
      hotelAddress: json['hotel_address']?.toString(),
      customerPhone: json['customer_phone']?.toString(),
      customerLatitude: json['customer_latitude'] != null ? double.tryParse(json['customer_latitude'].toString()) : null,
      customerLongitude: json['customer_longitude'] != null ? double.tryParse(json['customer_longitude'].toString()) : null,
      distanceKm: json['drop_distance_km'] != null
          ? double.tryParse(json['drop_distance_km'].toString())
          : (json['distance_km'] != null ? double.tryParse(json['distance_km'].toString()) : null),
      subtotal: double.tryParse((json['subtotal'] ?? 0).toString()) ?? 0.0,
      deliveryFee: double.tryParse((json['delivery_fee'] ?? 0).toString()) ?? 0.0,
      taxAmount: double.tryParse((json['tax_amount'] ?? 0).toString()) ?? 0.0,
      grandTotal: double.tryParse((json['grand_total'] ?? 0).toString()) ?? 0.0,
      walletDeducted: double.tryParse((json['wallet_deducted'] ?? 0).toString()) ?? 0.0,
      paymentMethod: json['payment_method']?.toString() ?? 'COD',
      deliveryAddress: json['delivery_address']?.toString() ?? '',
      status: json['status']?.toString() ?? 'created_order',
      createdAt: json['created_at']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? 'Customer',
      customerEmail: json['customer_email']?.toString() ?? '',
      hotelName: json['hotel_name']?.toString() ?? 'Hotel',
      mealType: (json['meal_type'] ?? 'Lunch').toString(),
      items: (json['items'] as List? ?? [])
          .map((i) => VendorOrderItem.fromJson(Map<String, dynamic>.from(i is Map ? i : {})))
          .toList(),
    );
  }
}

class VendorOrderItem {
  final int orderItemId;
  final int menuItemId;
  final int quantity;
  final double price;
  final String foodName;
  final List<String> mandatoryItems;
  final List<String> selectedOptionalItems;

  VendorOrderItem({
    required this.orderItemId,
    required this.menuItemId,
    required this.quantity,
    required this.price,
    required this.foodName,
    this.mandatoryItems = const [],
    this.selectedOptionalItems = const [],
  });

  factory VendorOrderItem.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic input) {
      if (input == null) return [];
      if (input is List) {
        return input.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
      }
      if (input is Map) {
        final list = <String>[];
        input.forEach((k, v) => list.add(v != null && v.toString().isNotEmpty ? '$k: $v' : '$k'));
        return list;
      }
      if (input is String && input.isNotEmpty) {
        try {
          final decoded = jsonDecode(input);
          return parseStringList(decoded);
        } catch (_) {
          return [input];
        }
      }
      return [];
    }

    return VendorOrderItem(
      orderItemId: int.tryParse((json['order_item_id'] ?? 0).toString()) ?? 0,
      menuItemId: int.tryParse((json['menu_item_id'] ?? 0).toString()) ?? 0,
      quantity: int.tryParse((json['quantity'] ?? 0).toString()) ?? 0,
      price: double.tryParse((json['price'] ?? 0).toString()) ?? 0.0,
      foodName: json['food_name']?.toString() ?? 'Item',
      mandatoryItems: parseStringList(json['mandatory_items']),
      selectedOptionalItems: parseStringList(json['selected_optional_items'] ?? json['customizations']),
    );
  }
}
