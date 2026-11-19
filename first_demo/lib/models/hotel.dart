// lib/models/hotel.dart
class Hotel {
  final int id;
  final int vendorId;
  final String hotelName;
  final String ownerName;
  final String mobileNumber;
  final String email;
  final String hotelAddress;
  final double latitude;
  final double longitude;
  final String? placeId;
  final String? city;
  final String? area;
  final String? state;
  final String? country;
  final String? pincode;
  final String? landmark;
  final String? photoUrl;
  final double? distance;
  final String createdAt;
  final bool isVendorOnline;
  final String serviceType; // 'DINING', 'DELIVERY', 'BOTH'
  final String foodType; // 'VEG', 'NON_VEG', 'BOTH'

  String get contactNo => mobileNumber;
  String get address => hotelAddress;

  static bool _isPlaceholderAddress(String text) {
    final lower = text.trim().toLowerCase();
    return lower.contains('loading address') ||
        lower.contains('fetching coordinates') ||
        lower.contains('coordinates:');
  }

  String get landmarkAndArea {
    final List<String> parts = [];
    if (landmark != null && landmark!.trim().isNotEmpty && !_isPlaceholderAddress(landmark!)) {
      parts.add(landmark!.trim());
    }
    if (area != null && area!.trim().isNotEmpty && !_isPlaceholderAddress(area!)) {
      final a = area!.trim();
      if (!parts.any((p) => p.toLowerCase() == a.toLowerCase())) {
        parts.add(a);
      }
    }
    if (parts.isNotEmpty) {
      return parts.join(', ');
    }
    if (city != null && city!.trim().isNotEmpty && !_isPlaceholderAddress(city!)) {
      return city!.trim();
    }
    if (hotelAddress.trim().isNotEmpty && !_isPlaceholderAddress(hotelAddress)) {
      return hotelAddress.trim();
    }
    return 'Location unavailable';
  }

  String get formattedAddress {
    final List<String> parts = [];
    if (landmark != null && landmark!.trim().isNotEmpty && !_isPlaceholderAddress(landmark!)) {
      parts.add("Near ${landmark!.trim()}");
    }
    if (area != null && area!.trim().isNotEmpty && !_isPlaceholderAddress(area!)) {
      parts.add(area!.trim());
    }
    if (hotelAddress.trim().isNotEmpty && !_isPlaceholderAddress(hotelAddress)) {
      parts.add(hotelAddress.trim());
    }
    if (city != null && city!.trim().isNotEmpty && !_isPlaceholderAddress(city!)) {
      parts.add(city!.trim());
    }
    if (pincode != null && pincode!.trim().isNotEmpty && !_isPlaceholderAddress(pincode!)) {
      parts.add(pincode!.trim());
    }

    final uniqueParts = <String>[];
    for (var part in parts) {
      if (!uniqueParts.any((existing) => existing.toLowerCase() == part.toLowerCase())) {
        uniqueParts.add(part);
      }
    }

    if (uniqueParts.isEmpty) {
      return 'Address details unavailable';
    }
    return uniqueParts.join(', ');
  }

  const Hotel({
    required this.id,
    required this.vendorId,
    required this.hotelName,
    required this.ownerName,
    required this.mobileNumber,
    required this.email,
    required this.hotelAddress,
    required this.latitude,
    required this.longitude,
    this.placeId,
    this.city,
    this.area,
    this.state,
    this.country,
    this.pincode,
    this.landmark,
    this.photoUrl,
    this.distance,
    required this.createdAt,
    this.isVendorOnline = true,
    this.serviceType = 'BOTH',
    this.foodType = 'BOTH',
  });

  factory Hotel.fromJson(Map<String, dynamic> json) {
    return Hotel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      vendorId: int.tryParse(json['vendor_id']?.toString() ?? '') ?? 0,
      hotelName: json['hotel_name'] as String? ?? '',
      ownerName: json['owner_name'] as String? ?? '',
      mobileNumber: json['mobile_number'] as String? ?? '',
      email: json['email'] as String? ?? '',
      hotelAddress: json['hotel_address'] as String? ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? '') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '') ?? 0.0,
      placeId: json['place_id'] as String?,
      city: json['city'] as String?,
      area: json['area'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      pincode: json['pincode'] as String?,
      landmark: json['landmark'] as String?,
      photoUrl: json['photo_url'] as String?,
      distance: json['distance'] != null ? double.tryParse(json['distance']?.toString() ?? '') : null,
      createdAt: json['created_at'] as String? ?? '',
      isVendorOnline: json['is_vendor_online'] == true || json['is_vendor_online'] == 1,
      serviceType: (json['service_type'] as String? ?? 'BOTH').toUpperCase(),
      foodType: (json['food_type'] as String? ?? 'BOTH').toUpperCase(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'vendor_id': vendorId,
        'hotel_name': hotelName,
        'owner_name': ownerName,
        'mobile_number': mobileNumber,
        'email': email,
        'hotel_address': hotelAddress,
        'latitude': latitude,
        'longitude': longitude,
        'place_id': placeId,
        'city': city,
        'area': area,
        'state': state,
        'country': country,
        'pincode': pincode,
        'landmark': landmark,
        'photo_url': photoUrl,
        'distance': distance,
        'created_at': createdAt,
        'is_vendor_online': isVendorOnline,
        'service_type': serviceType,
        'food_type': foodType,
      };

  Hotel copyWith({
    bool? isVendorOnline,
    String? serviceType,
    double? distance,
    String? foodType,
  }) {
    return Hotel(
      id: id,
      vendorId: vendorId,
      hotelName: hotelName,
      ownerName: ownerName,
      mobileNumber: mobileNumber,
      email: email,
      hotelAddress: hotelAddress,
      latitude: latitude,
      longitude: longitude,
      placeId: placeId,
      city: city,
      area: area,
      state: state,
      country: country,
      pincode: pincode,
      landmark: landmark,
      photoUrl: photoUrl,
      distance: distance ?? this.distance,
      createdAt: createdAt,
      isVendorOnline: isVendorOnline ?? this.isVendorOnline,
      serviceType: serviceType ?? this.serviceType,
      foodType: foodType ?? this.foodType,
    );
  }
}

