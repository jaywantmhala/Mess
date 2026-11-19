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
  final String? fssaiNumber;
  final String? fssaiPhotoUrl;
  final String? panNumber;
  final String? panPhotoUrl;
  final String? aadharNumber;
  final String? aadharPhotoUrl;
  final String? shopActNumber;
  final String? shopActPhotoUrl;
  final String? udyamAadharNumber;
  final String? udyamAadharPhotoUrl;
  final String? gstNumber;
  final String? gstPhotoUrl;
  final String serviceType; // 'DINING', 'DELIVERY', 'BOTH'
  final String foodType; // 'VEG', 'NON_VEG', 'BOTH'
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
    this.fssaiNumber,
    this.fssaiPhotoUrl,
    this.panNumber,
    this.panPhotoUrl,
    this.aadharNumber,
    this.aadharPhotoUrl,
    this.shopActNumber,
    this.shopActPhotoUrl,
    this.udyamAadharNumber,
    this.udyamAadharPhotoUrl,
    this.gstNumber,
    this.gstPhotoUrl,
    this.serviceType = 'BOTH',
    this.foodType = 'BOTH',
    required this.createdAt,
  });

  factory Hotel.fromJson(Map<String, dynamic> json) {
    return Hotel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      vendorId: int.tryParse(json['vendor_id']?.toString() ?? '') ?? 0,
      hotelName: json['hotel_name'] as String? ?? '',
      ownerName: json['owner_name'] as String? ?? '',
      mobileNumber: json['mobile_number'] as String? ?? json['contact_no'] as String? ?? '',
      email: json['email'] as String? ?? '',
      hotelAddress: json['hotel_address'] as String? ?? json['address'] as String? ?? '',
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
      fssaiNumber: json['fssai_number'] as String?,
      fssaiPhotoUrl: json['fssai_photo_url'] as String?,
      panNumber: json['pan_number'] as String?,
      panPhotoUrl: json['pan_photo_url'] as String?,
      aadharNumber: json['aadhar_number'] as String?,
      aadharPhotoUrl: json['aadhar_photo_url'] as String?,
      shopActNumber: json['shop_act_number'] as String?,
      shopActPhotoUrl: json['shop_act_photo_url'] as String?,
      udyamAadharNumber: json['udyam_aadhar_number'] as String?,
      udyamAadharPhotoUrl: json['udyam_aadhar_photo_url'] as String?,
      gstNumber: json['gst_number'] as String?,
      gstPhotoUrl: json['gst_photo_url'] as String?,
      serviceType: (json['service_type'] as String? ?? 'BOTH').toUpperCase(),
      foodType: (json['food_type'] as String? ?? 'BOTH').toUpperCase(),
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
        'fssai_number': fssaiNumber,
        'fssai_photo_url': fssaiPhotoUrl,
        'pan_number': panNumber,
        'pan_photo_url': panPhotoUrl,
        'aadhar_number': aadharNumber,
        'aadhar_photo_url': aadharPhotoUrl,
        'shop_act_number': shopActNumber,
        'shop_act_photo_url': shopActPhotoUrl,
        'udyam_aadhar_number': udyamAadharNumber,
        'udyam_aadhar_photo_url': udyamAadharPhotoUrl,
        'gst_number': gstNumber,
        'gst_photo_url': gstPhotoUrl,
        'service_type': serviceType,
        'food_type': foodType,
        'created_at': createdAt,
      };
}
