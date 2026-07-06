// lib/models/driver.dart
class Driver {
  final int id;
  final String fullName;
  final String email;
  final String vehicleNumber;
  final String phoneNumber;
  final bool isOnline;

  const Driver({
    required this.id,
    required this.fullName,
    required this.email,
    required this.vehicleNumber,
    required this.phoneNumber,
    required this.isOnline,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: int.tryParse(json['id'].toString()) ?? 0,
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      vehicleNumber: json['vehicle_number'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
      isOnline: (json['is_online'] == true || json['is_online'].toString() == '1' || json['is_online'] == 1),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'email': email,
        'vehicle_number': vehicleNumber,
        'phone_number': phoneNumber,
        'is_online': isOnline ? 1 : 0,
      };
}
