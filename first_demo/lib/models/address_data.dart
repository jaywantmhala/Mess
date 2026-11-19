// lib/models/address_data.dart

class AddressData {
  final int? id;
  final String name;
  final String mobileNumber;
  final String tag; // 'HOME', 'OFFICE', 'OTHER'
  final String houseNo;
  final String fullAddress;
  final String area;
  final String city;
  final String state;
  final String district;
  final String taluka;
  final String country;
  final String pincode;
  final String landmark;
  final String placeId;
  final double latitude;
  final double longitude;
  final bool isDefault;

  const AddressData({
    this.id,
    this.name = '',
    this.mobileNumber = '',
    this.tag = 'HOME',
    this.houseNo = '',
    required this.fullAddress,
    this.area = '',
    this.city = '',
    this.state = '',
    this.district = '',
    this.taluka = '',
    this.country = 'India',
    this.pincode = '',
    this.landmark = '',
    this.placeId = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.isDefault = false,
  });

  factory AddressData.fromJson(Map<String, dynamic> json) => AddressData(
        id:           int.tryParse(json['id']?.toString() ?? ''),
        name:         json['name']          as String? ?? json['receiver_name'] as String? ?? '',
        mobileNumber: json['mobile_number'] as String? ?? json['mobile_no'] as String? ?? json['phone'] as String? ?? '',
        tag:          (json['tag']          as String? ?? 'HOME').toUpperCase(),
        houseNo:      json['house_no']      as String? ?? '',
        fullAddress:  json['full_address']  as String? ?? '',
        area:         json['area']          as String? ?? '',
        city:         json['city']          as String? ?? '',
        state:        json['state']         as String? ?? '',
        district:     json['district']      as String? ?? '',
        taluka:       json['taluka']        as String? ?? '',
        country:      (json['country'] as String? ?? '').isNotEmpty ? (json['country'] as String) : 'India',
        pincode:      json['pincode']       as String? ?? '',
        landmark:     json['landmark']      as String? ?? '',
        placeId:      json['place_id']      as String? ?? '',
        latitude:     double.tryParse(json['latitude'].toString())  ?? 0.0,
        longitude:    double.tryParse(json['longitude'].toString()) ?? 0.0,
        isDefault:    json['is_default'] == true || json['is_default'] == 1 || json['is_default'].toString() == '1',
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name':          name,
        'mobile_number': mobileNumber,
        'tag':           tag,
        'house_no':      houseNo,
        'full_address':  fullAddress,
        'area':          area,
        'city':          city,
        'state':         state,
        'district':      district,
        'taluka':        taluka,
        'country':       country,
        'pincode':       pincode,
        'landmark':      landmark,
        'place_id':      placeId,
        'latitude':      latitude,
        'longitude':     longitude,
        'is_default':    isDefault ? 1 : 0,
      };

  AddressData copyWith({
    int? id,
    String? name,
    String? mobileNumber,
    String? tag,
    String? houseNo,
    String? fullAddress,
    String? area,
    String? city,
    String? state,
    String? district,
    String? taluka,
    String? country,
    String? pincode,
    String? landmark,
    String? placeId,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) {
    return AddressData(
      id: id ?? this.id,
      name: name ?? this.name,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      tag: tag ?? this.tag,
      houseNo: houseNo ?? this.houseNo,
      fullAddress: fullAddress ?? this.fullAddress,
      area: area ?? this.area,
      city: city ?? this.city,
      state: state ?? this.state,
      district: district ?? this.district,
      taluka: taluka ?? this.taluka,
      country: country ?? this.country,
      pincode: pincode ?? this.pincode,
      landmark: landmark ?? this.landmark,
      placeId: placeId ?? this.placeId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  /// Short display label used in the top bar (area/city or first part of address).
  String get shortLabel {
    if (tag.isNotEmpty) return '$tag • ${name.isNotEmpty ? name : 'Address'}';
    if (area.isNotEmpty && city.isNotEmpty) return '$area, $city';
    if (city.isNotEmpty) return city;
    final parts = fullAddress.split(',');
    return parts.first.trim();
  }

  /// Secondary line shown below short label.
  String get secondaryLabel {
    if (houseNo.isNotEmpty) return '$houseNo, $fullAddress';
    return fullAddress;
  }
}
