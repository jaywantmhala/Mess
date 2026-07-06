// lib/models/order.dart

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
  final List<VendorOrderItem> items;

  VendorOrder({
    required this.orderId,
    required this.customerId,
    required this.hotelId,
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
    required this.items,
  });

  factory VendorOrder.fromJson(Map<String, dynamic> json) {
    return VendorOrder(
      orderId: json['order_id'] ?? 0,
      customerId: json['customer_id'] ?? 0,
      hotelId: json['hotel_id'] ?? 0,
      subtotal: double.parse((json['subtotal'] ?? 0).toString()),
      deliveryFee: double.parse((json['delivery_fee'] ?? 0).toString()),
      taxAmount: double.parse((json['tax_amount'] ?? 0).toString()),
      grandTotal: double.parse((json['grand_total'] ?? 0).toString()),
      walletDeducted: double.parse((json['wallet_deducted'] ?? 0).toString()),
      paymentMethod: json['payment_method'] ?? 'COD',
      deliveryAddress: json['delivery_address'] ?? '',
      status: json['status'] ?? 'created_order',
      createdAt: json['created_at'] ?? '',
      customerName: json['customer_name'] ?? 'Customer',
      customerEmail: json['customer_email'] ?? '',
      hotelName: json['hotel_name'] ?? 'Hotel',
      items: (json['items'] as List? ?? [])
          .map((i) => VendorOrderItem.fromJson(Map<String, dynamic>.from(i as Map)))
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

  VendorOrderItem({
    required this.orderItemId,
    required this.menuItemId,
    required this.quantity,
    required this.price,
    required this.foodName,
  });

  factory VendorOrderItem.fromJson(Map<String, dynamic> json) {
    return VendorOrderItem(
      orderItemId: json['order_item_id'] ?? 0,
      menuItemId: json['menu_item_id'] ?? 0,
      quantity: json['quantity'] ?? 0,
      price: double.parse((json['price'] ?? 0).toString()),
      foodName: json['food_name'] ?? 'Item',
    );
  }
}
