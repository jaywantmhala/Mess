// lib/models/customer.dart
class Customer {
  final int id;
  final String fullName;
  final String email;
  final int isActive;
  final int emailVerified;
  final String? lastLoginAt;
  final String createdAt;

  const Customer({
    required this.id,
    required this.fullName,
    required this.email,
    required this.isActive,
    required this.emailVerified,
    this.lastLoginAt,
    required this.createdAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: int.tryParse(json['id'].toString()) ?? 0,
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      isActive: int.tryParse(json['is_active'].toString()) ?? 1,
      emailVerified: int.tryParse(json['email_verified'].toString()) ?? 0,
      lastLoginAt: json['last_login_at'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'email': email,
        'is_active': isActive,
        'email_verified': emailVerified,
        'last_login_at': lastLoginAt,
        'created_at': createdAt,
      };
}
