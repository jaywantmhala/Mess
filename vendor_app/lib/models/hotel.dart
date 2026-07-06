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
  final String createdAt;

  String get contactNo => mobileNumber;
  String get address => hotelAddress;

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
    required this.createdAt,
  });

  factory Hotel.fromJson(Map<String, dynamic> json) {
    return Hotel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      vendorId: int.tryParse(json['vendor_id'].toString()) ?? 0,
      hotelName: json['hotel_name'] as String? ?? '',
      ownerName: json['owner_name'] as String? ?? '',
      mobileNumber: json['mobile_number'] as String? ?? json['contact_no'] as String? ?? '',
      email: json['email'] as String? ?? '',
      hotelAddress: json['hotel_address'] as String? ?? json['address'] as String? ?? '',
      latitude: double.tryParse(json['latitude'].toString()) ?? 0.0,
      longitude: double.tryParse(json['longitude'].toString()) ?? 0.0,
      placeId: json['place_id'] as String?,
      city: json['city'] as String?,
      area: json['area'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      pincode: json['pincode'] as String?,
      landmark: json['landmark'] as String?,
      photoUrl: json['photo_url'] as String?,
      createdAt: json['created_at'] as String? ?? '',
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
        'created_at': createdAt,
      };
}
