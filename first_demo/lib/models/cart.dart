// lib/models/cart.dart

class CartItem {
  final int cartItemId;
  final int menuItemId;
  final String name;
  final double price;
  final int quantity;
  final double subtotal;
  final String? imageUrl;
  final String foodType; // 'VEG' or 'NON-VEG'

  const CartItem({
    required this.cartItemId,
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.subtotal,
    this.imageUrl,
    required this.foodType,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        cartItemId: int.parse(json['cart_item_id'].toString()),
        menuItemId: int.parse(json['menu_item_id'].toString()),
        name: json['name'] as String? ?? 'Item',
        price: double.parse(json['price'].toString()),
        quantity: int.parse(json['quantity'].toString()),
        subtotal: double.parse(json['subtotal'].toString()),
        imageUrl: json['image_url'] as String?,
        foodType: json['food_type'] as String? ?? 'VEG',
      );

  bool get isVeg => foodType.toUpperCase() == 'VEG';
}

class CartHotel {
  final int id;
  final String name;

  const CartHotel({required this.id, required this.name});

  factory CartHotel.fromJson(Map<String, dynamic> json) => CartHotel(
        id: int.parse(json['id'].toString()),
        name: json['name'] as String? ?? 'Hotel',
      );
}

class CartSummary {
  final List<CartItem> items;
  final CartHotel? hotel;
  final int totalQuantity;
  final double subtotal;
  final double deliveryFee;
  final double taxAmount;
  final double grandTotal;

  const CartSummary({
    required this.items,
    this.hotel,
    required this.totalQuantity,
    required this.subtotal,
    required this.deliveryFee,
    required this.taxAmount,
    required this.grandTotal,
  });

  bool get isEmpty => items.isEmpty;

  factory CartSummary.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List? ?? [])
        .map((i) => CartItem.fromJson(i as Map<String, dynamic>))
        .toList();
    return CartSummary(
      items: itemsList,
      hotel: json['hotel'] != null
          ? CartHotel.fromJson(json['hotel'] as Map<String, dynamic>)
          : null,
      totalQuantity: int.parse((json['total_quantity'] ?? 0).toString()),
      subtotal: double.parse((json['subtotal'] ?? 0).toString()),
      deliveryFee: double.parse((json['delivery_fee'] ?? 0).toString()),
      taxAmount: double.parse((json['tax_amount'] ?? 0).toString()),
      grandTotal: double.parse((json['grand_total'] ?? 0).toString()),
    );
  }

  static CartSummary empty() => const CartSummary(
        items: [],
        totalQuantity: 0,
        subtotal: 0,
        deliveryFee: 0,
        taxAmount: 0,
        grandTotal: 0,
      );
}
