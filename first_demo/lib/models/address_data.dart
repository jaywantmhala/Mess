// lib/models/address_data.dart

class AddressData {
  final String fullAddress;
  final String area;
  final String city;
  final String state;
  final String country;
  final String pincode;
  final String landmark;
  final String placeId;
  final double latitude;
  final double longitude;

  const AddressData({
    required this.fullAddress,
    this.area = '',
    this.city = '',
    this.state = '',
    this.country = '',
    this.pincode = '',
    this.landmark = '',
    this.placeId = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
  });

  factory AddressData.fromJson(Map<String, dynamic> json) => AddressData(
        fullAddress: json['full_address'] as String? ?? '',
        area:        json['area']         as String? ?? '',
        city:        json['city']         as String? ?? '',
        state:       json['state']        as String? ?? '',
        country:     json['country']      as String? ?? '',
        pincode:     json['pincode']      as String? ?? '',
        landmark:    json['landmark']     as String? ?? '',
        placeId:     json['place_id']     as String? ?? '',
        latitude:    double.tryParse(json['latitude'].toString())  ?? 0.0,
        longitude:   double.tryParse(json['longitude'].toString()) ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
        'full_address': fullAddress,
        'area':         area,
        'city':         city,
        'state':        state,
        'country':      country,
        'pincode':      pincode,
        'landmark':     landmark,
        'place_id':     placeId,
        'latitude':     latitude,
        'longitude':    longitude,
      };

  /// Short display label used in the top bar (area/city or first part of address).
  String get shortLabel {
    if (area.isNotEmpty && city.isNotEmpty) return '$area, $city';
    if (city.isNotEmpty) return city;
    final parts = fullAddress.split(',');
    return parts.first.trim();
  }

  /// Secondary line shown below short label.
  String get secondaryLabel {
    if (area.isNotEmpty && city.isNotEmpty) return fullAddress;
    return fullAddress;
  }
}
