// lib/models/subscription_plan.dart
class SubscriptionPlan {
  final int id;
  final int subAreaId;
  final String planName;
  final String? description;
  final double price;
  final int duration;
  final int totalDeliveries;
  final int mealsPerDay;
  final String mealType;
  final String deliveryTimeSlot;
  final double discount;
  final double deliveryCharge;
  final double tiffinCharge;
  final double originalTiffinCharge;
  final double discountPercentage;
  final bool isActive;
  /// Distance in km from the customer's address to this plan's sub-area.
  /// Null means distance is unknown (e.g. fallback plans with no GPS data).
  final double? distanceKm;

  bool get hasDiscount => originalTiffinCharge > tiffinCharge && originalTiffinCharge > 0;

  const SubscriptionPlan({
    required this.id,
    required this.subAreaId,
    required this.planName,
    this.description,
    required this.price,
    required this.duration,
    required this.totalDeliveries,
    required this.mealsPerDay,
    required this.mealType,
    required this.deliveryTimeSlot,
    required this.discount,
    required this.deliveryCharge,
    this.tiffinCharge = 50.0,
    this.originalTiffinCharge = 0.0,
    this.discountPercentage = 0.0,
    required this.isActive,
    this.distanceKm,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: int.tryParse(json['id'].toString()) ?? 0,
      subAreaId: int.tryParse(json['sub_area_id'].toString()) ?? 0,
      planName: json['plan_name'] as String? ?? '',
      description: json['description'] as String?,
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      duration: int.tryParse(json['duration'].toString()) ?? 0,
      totalDeliveries: int.tryParse(json['total_deliveries'].toString()) ?? 0,
      mealsPerDay: int.tryParse(json['meals_per_day'].toString()) ?? 1,
      mealType: json['meal_type'] as String? ?? 'VEG',
      deliveryTimeSlot: json['delivery_time_slot'] as String? ?? '',
      discount: double.tryParse(json['discount'].toString()) ?? 0.0,
      deliveryCharge: double.tryParse(json['delivery_charge'].toString()) ?? 0.0,
      tiffinCharge: double.tryParse((json['tiffin_charge'] ?? 50.0).toString()) ?? 50.0,
      originalTiffinCharge: double.tryParse((json['original_tiffin_charge'] ?? 0.0).toString()) ?? 0.0,
      discountPercentage: double.tryParse((json['discount_percentage'] ?? 0.0).toString()) ?? 0.0,
      isActive: int.tryParse(json['is_active'].toString()) == 1 || json['is_active'] == true,
      distanceKm: json['distance_km'] != null ? double.tryParse(json['distance_km'].toString()) : null,
    );
  }
}
