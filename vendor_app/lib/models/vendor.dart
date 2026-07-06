// lib/models/vendor.dart
class Vendor {
  final int id;
  final String fullName;
  final String email;
  final int isActive;
  final String createdAt;

  const Vendor({
    required this.id,
    required this.fullName,
    required this.email,
    required this.isActive,
    required this.createdAt,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: int.tryParse(json['id'].toString()) ?? 0,
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      isActive: int.tryParse(json['is_active'].toString()) ?? 1,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'email': email,
        'is_active': isActive,
        'created_at': createdAt,
      };
}
