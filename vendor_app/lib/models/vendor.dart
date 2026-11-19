// lib/models/vendor.dart
class Vendor {
  final int id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String country;
  final String state;
  final String district;
  final String taluka;
  final int isActive;
  final String? razorpayContactId;
  final String createdAt;

  const Vendor({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber = '',
    this.country = 'India',
    this.state = '',
    this.district = '',
    this.taluka = '',
    required this.isActive,
    this.razorpayContactId,
    required this.createdAt,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: int.tryParse((json['id'] ?? json['vendor_id'] ?? 0).toString()) ?? 0,
      fullName: json['full_name'] as String? ?? json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? json['phoneNumber'] as String? ?? json['phone'] as String? ?? '',
      country: json['country'] as String? ?? 'India',
      state: json['state'] as String? ?? '',
      district: json['district'] as String? ?? '',
      taluka: json['taluka'] as String? ?? '',
      isActive: int.tryParse((json['is_active'] ?? 1).toString()) ?? 1,
      razorpayContactId: json['razorpay_contact_id'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'email': email,
        'phone_number': phoneNumber,
        'phone': phoneNumber,
        'country': country,
        'state': state,
        'district': district,
        'taluka': taluka,
        'is_active': isActive,
        'razorpay_contact_id': razorpayContactId,
        'created_at': createdAt,
      };

  Vendor copyWith({
    int? id,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? country,
    String? state,
    String? district,
    String? taluka,
    int? isActive,
    String? razorpayContactId,
    String? createdAt,
  }) {
    return Vendor(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      country: country ?? this.country,
      state: state ?? this.state,
      district: district ?? this.district,
      taluka: taluka ?? this.taluka,
      isActive: isActive ?? this.isActive,
      razorpayContactId: razorpayContactId ?? this.razorpayContactId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
