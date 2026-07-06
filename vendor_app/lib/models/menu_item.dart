// lib/models/menu_item.dart

class MenuItem {
  final int id;
  final int hotelId;
  final String foodName;
  final String description;
  final String foodType; // 'VEG' or 'NON-VEG'
  final double price;
  final String spiceLevel; // 'NONE', 'LOW', 'MEDIUM', 'HIGH'
  final bool isPopular;
  final bool isAvailable;
  final String? imageUrl;
  final String menuDate; // YYYY-MM-DD

  MenuItem({
    required this.id,
    required this.hotelId,
    required this.foodName,
    required this.description,
    required this.foodType,
    required this.price,
    required this.spiceLevel,
    required this.isPopular,
    required this.isAvailable,
    this.imageUrl,
    required this.menuDate,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      hotelId: json['hotel_id'] is int ? json['hotel_id'] : int.parse(json['hotel_id'].toString()),
      foodName: json['food_name'] ?? '',
      description: json['description'] ?? '',
      foodType: json['food_type'] ?? 'VEG',
      price: json['price'] != null ? double.parse(json['price'].toString()) : 0.0,
      spiceLevel: json['spice_level'] ?? 'NONE',
      isPopular: json['is_popular'] == true || json['is_popular'] == 1 || json['is_popular'] == '1',
      isAvailable: json['is_available'] == true || json['is_available'] == 1 || json['is_available'] == '1' || json['is_available'] == null,
      imageUrl: json['image_url'],
      menuDate: json['menu_date'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hotel_id': hotelId,
      'food_name': foodName,
      'description': description,
      'food_type': foodType,
      'price': price,
      'spice_level': spiceLevel,
      'is_popular': isPopular ? 1 : 0,
      'is_available': isAvailable ? 1 : 0,
      'image_url': imageUrl,
      'menu_date': menuDate,
    };
  }
}
