// lib/services/hotel_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/hotel.dart';
import 'auth_service.dart';
import '../utils/app_config.dart';

final String _baseUrl = '$kBaseUrl/api/hotels';
const Duration _timeout = Duration(seconds: 15);

class HotelService {
  HotelService._();
  static final HotelService instance = HotelService._();

  /// Retrieve all hotels within 2 km of the given latitude and longitude coordinates
  Future<List<Hotel>> getNearbyHotels({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final token = await AuthService.instance.getSavedToken();
      if (token == null) return [];

      final uri = Uri.parse(
        '$_baseUrl/nearby?latitude=$latitude&longitude=$longitude',
      );
      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>;
        final list = data['hotels'] as List;
        return list
            .map((item) => Hotel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting nearby hotels: $e');
      return [];
    }
  }
}
