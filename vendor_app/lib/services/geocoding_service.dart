// lib/services/geocoding_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingService {
  /// Fetches actual address string from coordinates using OpenStreetMap Nominatim API (free, no API key needed)
  static Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      final data = await getStructuredAddress(latitude, longitude);
      if (data != null) {
        final displayName = data['display_name'] as String?;
        if (displayName != null && displayName.isNotEmpty) {
          return displayName;
        }
      }
      return 'Coordinates: (${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)})';
    } catch (e) {
      print('Nominatim geocoding error: $e');
      return 'Coordinates: (${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)})';
    }
  }

  /// Fetches the raw JSON response containing structured address elements
  static Future<Map<String, dynamic>?> getStructuredAddress(double latitude, double longitude) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'ZenQubeVendorApp/1.0',
          'Accept-Language': 'en',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print('Nominatim structured geocoding error: $e');
    }
    return null;
  }
}
