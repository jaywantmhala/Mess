// lib/services/hotel_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/hotel.dart';
import 'auth_service.dart';
import '../utils/app_config.dart';
import '../utils/api_client.dart';

final String _baseUrl = kBaseUrl;
const Duration _timeout = Duration(seconds: 15);

class HotelResult {
  final bool success;
  final String message;
  final Hotel? hotel;

  const HotelResult({required this.success, required this.message, this.hotel});
}

class HotelService {
  HotelService._();
  static final HotelService instance = HotelService._();

  /// Retrieve all hotels owned by the logged-in vendor
  Future<List<Hotel>> getHotels() async {
    try {
      final response = await ApiClient.instance
          .get(Uri.parse('$_baseUrl/hotels'))
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
      print('Error getting hotels: $e');
      return [];
    }
  }

  /// Registers a new hotel in the database
  Future<HotelResult> addHotel({
    required String ownerName,
    required String mobileNumber,
    required String email,
    required String hotelName,
    required String hotelAddress,
    required double latitude,
    required double longitude,
    String? placeId,
    String? city,
    String? area,
    String? state,
    String? country,
    String? pincode,
    String? landmark,
    String? photoUrl,
    String? fssaiNumber,
    String? fssaiPhotoUrl,
    String? panNumber,
    String? panPhotoUrl,
    String? aadharNumber,
    String? aadharPhotoUrl,
    String? shopActNumber,
    String? shopActPhotoUrl,
    String? udyamAadharNumber,
    String? udyamAadharPhotoUrl,
    String? gstNumber,
    String? gstPhotoUrl,
    String? serviceType,
    String? foodType,
  }) async {
    try {
      final token = await AuthService.instance.getSavedToken();
      if (token == null) {
        return const HotelResult(
          success: false,
          message: 'Unauthorized. Please sign in again.',
        );
      }

      final response = await http
          .post(
            Uri.parse('$_baseUrl/add_hotel'),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'owner_name': ownerName.trim(),
              'mobile_number': mobileNumber.trim(),
              'email': email.trim(),
              'hotel_name': hotelName.trim(),
              'hotel_address': hotelAddress.trim(),
              'latitude': latitude,
              'longitude': longitude,
              if (placeId != null) 'place_id': placeId,
              if (city != null) 'city': city,
              if (area != null) 'area': area,
              if (state != null) 'state': state,
              if (country != null) 'country': country,
              if (pincode != null) 'pincode': pincode,
              if (landmark != null) 'landmark': landmark,
              if (photoUrl != null) 'photo_url': photoUrl,
              if (fssaiNumber != null) 'fssai_number': fssaiNumber.trim(),
              if (fssaiPhotoUrl != null) 'fssai_photo_url': fssaiPhotoUrl,
              if (panNumber != null) 'pan_number': panNumber.trim(),
              if (panPhotoUrl != null) 'pan_photo_url': panPhotoUrl,
              if (aadharNumber != null) 'aadhar_number': aadharNumber.trim(),
              if (aadharPhotoUrl != null) 'aadhar_photo_url': aadharPhotoUrl,
              if (shopActNumber != null) 'shop_act_number': shopActNumber.trim(),
              if (shopActPhotoUrl != null) 'shop_act_photo_url': shopActPhotoUrl,
              if (udyamAadharNumber != null) 'udyam_aadhar_number': udyamAadharNumber.trim(),
              if (udyamAadharPhotoUrl != null) 'udyam_aadhar_photo_url': udyamAadharPhotoUrl,
              if (gstNumber != null) 'gst_number': gstNumber.trim(),
              if (gstPhotoUrl != null) 'gst_photo_url': gstPhotoUrl,
              'service_type': serviceType ?? 'BOTH',
              'food_type': foodType ?? 'BOTH',
            }),
          )
          .timeout(_timeout);

      if (response.body.trim().isEmpty) {
        return const HotelResult(
          success: false,
          message: 'Server returned an empty response. Please check database schema or server logs.',
        );
      }

      final Map<String, dynamic> body;
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        return HotelResult(
          success: false,
          message: 'Server error (${response.statusCode}): ${response.body}',
        );
      }

      final bool ok = body['success'] == true;

      if (ok) {
        final data = body['data'] as Map<String, dynamic>;
        final hotel = Hotel.fromJson(data['hotel'] as Map<String, dynamic>);
        return HotelResult(
          success: true,
          message: body['message'] as String? ?? 'Hotel registered successfully',
          hotel: hotel,
        );
      }

      return HotelResult(
        success: false,
        message: body['message'] as String? ?? 'Failed to add hotel.',
      );
    } on SocketException {
      return const HotelResult(
        success: false,
        message: 'Server unreachable. Is the PHP server running?',
      );
    } catch (e) {
      return HotelResult(success: false, message: 'Error: $e');
    }
  }

  /// Updates an existing hotel's details
  Future<HotelResult> editHotel({
    required int id,
    required String ownerName,
    required String mobileNumber,
    required String email,
    required String hotelName,
    required String hotelAddress,
    required double latitude,
    required double longitude,
    String? placeId,
    String? city,
    String? area,
    String? state,
    String? country,
    String? pincode,
    String? landmark,
    String? photoUrl,
    String? fssaiNumber,
    String? fssaiPhotoUrl,
    String? panNumber,
    String? panPhotoUrl,
    String? aadharNumber,
    String? aadharPhotoUrl,
    String? shopActNumber,
    String? shopActPhotoUrl,
    String? udyamAadharNumber,
    String? udyamAadharPhotoUrl,
    String? gstNumber,
    String? gstPhotoUrl,
    String? serviceType,
    String? foodType,
  }) async {
    try {
      final token = await AuthService.instance.getSavedToken();
      if (token == null) {
        return const HotelResult(
          success: false,
          message: 'Unauthorized. Please sign in again.',
        );
      }

      final response = await http
          .post(
            Uri.parse('$_baseUrl/edit_hotel'),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'id': id,
              'owner_name': ownerName.trim(),
              'mobile_number': mobileNumber.trim(),
              'email': email.trim(),
              'hotel_name': hotelName.trim(),
              'hotel_address': hotelAddress.trim(),
              'latitude': latitude,
              'longitude': longitude,
              if (placeId != null) 'place_id': placeId,
              if (city != null) 'city': city,
              if (area != null) 'area': area,
              if (state != null) 'state': state,
              if (country != null) 'country': country,
              if (pincode != null) 'pincode': pincode,
              if (landmark != null) 'landmark': landmark,
              if (photoUrl != null) 'photo_url': photoUrl,
              if (fssaiNumber != null) 'fssai_number': fssaiNumber.trim(),
              if (fssaiPhotoUrl != null) 'fssai_photo_url': fssaiPhotoUrl,
              if (panNumber != null) 'pan_number': panNumber.trim(),
              if (panPhotoUrl != null) 'pan_photo_url': panPhotoUrl,
              if (aadharNumber != null) 'aadhar_number': aadharNumber.trim(),
              if (aadharPhotoUrl != null) 'aadhar_photo_url': aadharPhotoUrl,
              if (shopActNumber != null) 'shop_act_number': shopActNumber.trim(),
              if (shopActPhotoUrl != null) 'shop_act_photo_url': shopActPhotoUrl,
              if (udyamAadharNumber != null) 'udyam_aadhar_number': udyamAadharNumber.trim(),
              if (udyamAadharPhotoUrl != null) 'udyam_aadhar_photo_url': udyamAadharPhotoUrl,
              if (gstNumber != null) 'gst_number': gstNumber.trim(),
              if (gstPhotoUrl != null) 'gst_photo_url': gstPhotoUrl,
              'service_type': serviceType ?? 'BOTH',
              'food_type': foodType ?? 'BOTH',
            }),
          )
          .timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final bool ok = body['success'] == true;

      if (ok) {
        final data = body['data'] as Map<String, dynamic>;
        final hotel = Hotel.fromJson(data['hotel'] as Map<String, dynamic>);
        return HotelResult(
          success: true,
          message: body['message'] as String,
          hotel: hotel,
        );
      }

      return HotelResult(
        success: false,
        message: body['message'] as String? ?? 'Failed to update hotel.',
      );
    } on SocketException {
      return const HotelResult(
        success: false,
        message: 'Server unreachable. Is the PHP server running?',
      );
    } catch (e) {
      return HotelResult(success: false, message: 'Error: $e');
    }
  }

  /// Deletes an existing hotel
  Future<HotelResult> deleteHotel(int id) async {
    try {
      final token = await AuthService.instance.getSavedToken();
      if (token == null) {
        return const HotelResult(
          success: false,
          message: 'Unauthorized. Please sign in again.',
        );
      }

      final response = await http
          .post(
            Uri.parse('$_baseUrl/delete_hotel'),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'id': id}),
          )
          .timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final bool ok = body['success'] == true;

      return HotelResult(
        success: ok,
        message:
            body['message'] as String? ??
            (ok ? 'Hotel deleted successfully.' : 'Failed to delete hotel.'),
      );
    } on SocketException {
      return const HotelResult(
        success: false,
        message: 'Server unreachable. Is the PHP server running?',
      );
    } catch (e) {
      return HotelResult(success: false, message: 'Error: $e');
    }
  }
}
