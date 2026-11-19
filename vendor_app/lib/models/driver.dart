// lib/models/driver.dart
class Driver {
  final int id;
  final String fullName;
  final String email;
  final String vehicleNumber;
  final String phoneNumber;
  final bool isOnline;
  final int totalDeliveries;
  final String completionRate;
  final double rating;
  final String yearsOnPlatform;

  const Driver({
    required this.id,
    required this.fullName,
    required this.email,
    required this.vehicleNumber,
    required this.phoneNumber,
    required this.isOnline,
    this.totalDeliveries = 120,
    this.completionRate = '98%',
    this.rating = 4.8,
    this.yearsOnPlatform = '2 Yrs',
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: int.tryParse(json['id'].toString()) ?? 0,
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      vehicleNumber: json['vehicle_number'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
      isOnline: (json['is_online'] == true || json['is_online'].toString() == '1' || json['is_online'] == 1),
      totalDeliveries: int.tryParse(json['total_deliveries']?.toString() ?? json['deliveries_count']?.toString() ?? '') ?? 120,
      completionRate: json['completion_rate'] as String? ?? '98%',
      rating: double.tryParse(json['rating']?.toString() ?? json['average_rating']?.toString() ?? '') ?? 4.8,
      yearsOnPlatform: json['years_on_platform'] as String? ?? json['on_platform'] as String? ?? '2 Yrs',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'email': email,
        'vehicle_number': vehicleNumber,
        'phone_number': phoneNumber,
        'is_online': isOnline ? 1 : 0,
        'total_deliveries': totalDeliveries,
        'completion_rate': completionRate,
        'rating': rating,
        'years_on_platform': yearsOnPlatform,
      };
}
