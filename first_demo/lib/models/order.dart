// lib/models/order.dart

class OrderResult {
  final int orderId;
  final double grandTotal;
  final double walletDeducted;
  final double remainingPayable;
  final double newWalletBalance;
  final String status;

  const OrderResult({
    required this.orderId,
    required this.grandTotal,
    required this.walletDeducted,
    required this.remainingPayable,
    required this.newWalletBalance,
    required this.status,
  });

  factory OrderResult.fromJson(Map<String, dynamic> json) => OrderResult(
        orderId: int.parse(json['order_id'].toString()),
        grandTotal: double.parse(json['grand_total'].toString()),
        walletDeducted: double.parse(json['wallet_deducted'].toString()),
        remainingPayable: double.parse(json['remaining_payable'].toString()),
        newWalletBalance: double.parse(json['new_wallet_balance'].toString()),
        status: json['status'] as String? ?? 'PLACED',
      );
}

class OrderHistoryItem {
  final int orderId;
  final String hotelName;
  final String status;
  final double grandTotal;
  final double walletDeducted;
  final int itemCount;
  final DateTime createdAt;

  const OrderHistoryItem({
    required this.orderId,
    required this.hotelName,
    required this.status,
    required this.grandTotal,
    required this.walletDeducted,
    required this.itemCount,
    required this.createdAt,
  });

  factory OrderHistoryItem.fromJson(Map<String, dynamic> json) =>
      OrderHistoryItem(
        orderId: int.parse(json['order_id'].toString()),
        hotelName: json['hotel_name'] as String? ?? 'Unknown',
        status: json['status'] as String? ?? 'PLACED',
        grandTotal: double.parse(json['grand_total'].toString()),
        walletDeducted: double.parse(json['wallet_deducted'].toString()),
        itemCount: int.parse(json['item_count'].toString()),
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}

class OrderDetailsItem {
  final String foodName;
  final int quantity;
  final double price;

  const OrderDetailsItem({
    required this.foodName,
    required this.quantity,
    required this.price,
  });

  factory OrderDetailsItem.fromJson(Map<String, dynamic> json) =>
      OrderDetailsItem(
        foodName: json['food_name'] as String? ?? '',
        quantity: int.parse(json['quantity'].toString()),
        price: double.parse(json['price'].toString()),
      );
}

class OrderDetailsHotel {
  final int id;
  final String hotelName;
  final String hotelAddress;
  final String rating;
  final String photoUrl;
  final double latitude;
  final double longitude;

  const OrderDetailsHotel({
    required this.id,
    required this.hotelName,
    required this.hotelAddress,
    required this.rating,
    required this.photoUrl,
    required this.latitude,
    required this.longitude,
  });

  factory OrderDetailsHotel.fromJson(Map<String, dynamic> json) =>
      OrderDetailsHotel(
        id: int.parse(json['id'].toString()),
        hotelName: json['hotel_name'] as String? ?? '',
        hotelAddress: json['hotel_address'] as String? ?? '',
        rating: json['rating'] as String? ?? '4.0',
        photoUrl: json['photo_url'] as String? ?? '',
        latitude: double.parse((json['latitude'] ?? 0.0).toString()),
        longitude: double.parse((json['longitude'] ?? 0.0).toString()),
      );
}

class OrderDetailsDeliveryPartner {
  final int id;
  final String name;
  final String rating;
  final String avatarUrl;
  final String phoneNumber;
  final String vehicleNumber;
  double latitude;
  double longitude;

  OrderDetailsDeliveryPartner({
    required this.id,
    required this.name,
    required this.rating,
    required this.avatarUrl,
    required this.phoneNumber,
    required this.vehicleNumber,
    required this.latitude,
    required this.longitude,
  });

  factory OrderDetailsDeliveryPartner.fromJson(Map<String, dynamic> json) =>
      OrderDetailsDeliveryPartner(
        id: int.tryParse(json['id'].toString()) ?? 0,
        name: json['name'] as String? ?? '',
        rating: json['rating'] as String? ?? '4.0',
        avatarUrl: json['avatar_url'] as String? ?? '',
        phoneNumber: json['phone_number'] as String? ?? '',
        vehicleNumber: json['vehicle_number'] as String? ?? '',
        latitude: double.tryParse((json['latitude'] ?? 0.0).toString()) ?? 0.0,
        longitude: double.tryParse((json['longitude'] ?? 0.0).toString()) ?? 0.0,
      );
}

class OrderDetails {
  final int orderId;
  final String status;
  final double subtotal;
  final double deliveryFee;
  final double taxAmount;
  final double grandTotal;
  final double walletDeducted;
  final String paymentMethod;
  final String deliveryAddress;
  final String createdAt;
  final OrderDetailsHotel hotel;
  final List<OrderDetailsItem> items;
  final OrderDetailsDeliveryPartner? deliveryPartner;
  final double customerLatitude;
  final double customerLongitude;

  const OrderDetails({
    required this.orderId,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    required this.taxAmount,
    required this.grandTotal,
    required this.walletDeducted,
    required this.paymentMethod,
    required this.deliveryAddress,
    required this.createdAt,
    required this.hotel,
    required this.items,
    this.deliveryPartner,
    required this.customerLatitude,
    required this.customerLongitude,
  });

  factory OrderDetails.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>?;
    return OrderDetails(
      orderId: int.parse(json['order_id'].toString()),
      status: json['status'] as String? ?? 'created_order',
      subtotal: double.parse(json['subtotal'].toString()),
      deliveryFee: double.parse(json['delivery_fee'].toString()),
      taxAmount: double.parse(json['tax_amount'].toString()),
      grandTotal: double.parse(json['grand_total'].toString()),
      walletDeducted: double.parse(json['wallet_deducted'].toString()),
      paymentMethod: json['payment_method'] as String? ?? 'UPI',
      deliveryAddress: json['delivery_address'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      hotel: OrderDetailsHotel.fromJson(json['hotel'] as Map<String, dynamic>),
      items: (json['items'] as List)
          .map((item) => OrderDetailsItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      deliveryPartner: json['delivery_partner'] != null
          ? OrderDetailsDeliveryPartner.fromJson(json['delivery_partner'] as Map<String, dynamic>)
          : null,
      customerLatitude: double.parse((customer?['latitude'] ?? 18.5204).toString()),
      customerLongitude: double.parse((customer?['longitude'] ?? 73.8567).toString()),
    );
  }
}
