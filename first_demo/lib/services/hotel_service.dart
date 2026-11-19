// lib/services/hotel_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/hotel.dart';
import '../models/subscription_plan.dart';
import 'auth_service.dart';
import '../utils/app_config.dart';
import '../utils/api_client.dart';

final String _baseUrl = '$kBaseUrl/api/hotels';
const Duration _timeout = Duration(seconds: 15);

class ServiceLocation {
  final int id;
  final String locationName;
  final String address;
  final double latitude;
  final double longitude;
  final double radiusKm;
  final double distanceKm;
  final double tiffinCharge;
  final double originalTiffinCharge;
  final double discountPercentage;

  bool get hasDiscount => originalTiffinCharge > tiffinCharge && originalTiffinCharge > 0;

  ServiceLocation({
    required this.id,
    required this.locationName,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
    required this.distanceKm,
    this.tiffinCharge = 50.0,
    this.originalTiffinCharge = 0.0,
    this.discountPercentage = 0.0,
  });

  factory ServiceLocation.fromJson(Map<String, dynamic> json) {
    final tiffin = (json['tiffin_charge'] as num?)?.toDouble() ?? 50.0;
    final orig   = (json['original_tiffin_charge'] as num?)?.toDouble() ?? 0.0;
    final disc   = (orig > tiffin && orig > 0)
        ? ((json['discount_percentage'] as num?)?.toDouble() ?? (((orig - tiffin) / orig) * 100))
        : 0.0;

    return ServiceLocation(
      id:                   (json['id'] as num?)?.toInt() ?? 0,
      locationName:         json['location_name']?.toString() ?? '',
      address:              json['address']?.toString() ?? '',
      latitude:             (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude:            (json['longitude'] as num?)?.toDouble() ?? 0.0,
      radiusKm:             (json['radius_km'] as num?)?.toDouble() ?? 5.0,
      distanceKm:           (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      tiffinCharge:         tiffin,
      originalTiffinCharge: orig,
      discountPercentage:   disc,
    );
  }
}

class ServiceablePlansResult {
  final bool serviceable;
  final List<SubscriptionPlan> plans;
  final ServiceLocation? serviceLocation;
  ServiceablePlansResult({
    required this.serviceable,
    required this.plans,
    this.serviceLocation,
  });
}

class NearbyHotelsResponse {
  final List<Hotel> hotels;
  final bool hasActiveSubscription;
  final String? message;
  NearbyHotelsResponse({required this.hotels, required this.hasActiveSubscription, this.message});
}

class HotelService {
  HotelService._();
  static final HotelService instance = HotelService._();

  /// Retrieve all hotels within 5 km of the given latitude and longitude coordinates
  Future<NearbyHotelsResponse> getNearbyHotels({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/nearby?latitude=$latitude&longitude=$longitude',
      );
      final response = await ApiClient.instance
          .get(uri)
          .timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final apiMsg = body['message']?.toString();
      if (body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>;
        final list = data['hotels'] as List? ?? [];
        final hotels = list
            .map((item) => Hotel.fromJson(item as Map<String, dynamic>))
            .toList();
        final hasSub = data['has_active_subscription'] == true;
        return NearbyHotelsResponse(hotels: hotels, hasActiveSubscription: hasSub, message: apiMsg);
      }
      return NearbyHotelsResponse(hotels: [], hasActiveSubscription: false, message: apiMsg);
    } catch (e) {
      debugPrint('Error getting nearby hotels: $e');
      return NearbyHotelsResponse(hotels: [], hasActiveSubscription: false, message: e.toString());
    }
  }

  /// Resolve customer coordinates to get available active subscription plans.
  /// Uses /api/customer/serviceable-plans-v2 — nearest eligible location algorithm.
  Future<ServiceablePlansResult> getServiceablePlans({
    required double latitude,
    required double longitude,
    String? pincode,
    String? address,
  }) async {
    try {
      final token = await AuthService.instance.getSavedToken();
      if (token == null) return ServiceablePlansResult(serviceable: false, plans: []);

      final uri = Uri.parse('$kBaseUrl/api/customer/serviceable-plans-v2');
      final requestBody = {
        'latitude':  latitude,
        'longitude': longitude,
        'pincode':   pincode ?? '',
        'customer_address': address ?? '',
      };

      debugPrint('📍 [ServiceablePlans v2] Request: lat=$latitude, lng=$longitude');

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      debugPrint('📍 [ServiceablePlans v2] Response success=${body['success']}, message=${body['message']}');

      if (body['success'] == true) {
        final data           = body['data'] as Map<String, dynamic>? ?? {};
        final isServiceable  = data['serviceable'] == true;
        final list           = (data['plans'] ?? []) as List? ?? [];
        final slData         = data['service_location'] as Map<String, dynamic>?;

        final serviceLocation = slData != null ? ServiceLocation.fromJson(slData) : null;
        debugPrint('📍 [ServiceablePlans v2] serviceable=$isServiceable, plans=${list.length}, location=${serviceLocation?.locationName}');

        final plans = list
            .map((item) => SubscriptionPlan.fromJson(item as Map<String, dynamic>))
            .toList();
        return ServiceablePlansResult(
          serviceable: isServiceable,
          plans: plans,
          serviceLocation: serviceLocation,
        );
      }

      debugPrint('📍 [ServiceablePlans v2] API returned success=false');
      return ServiceablePlansResult(serviceable: false, plans: []);
    } catch (e) {
      debugPrint('❌ [ServiceablePlans v2] Error: $e');
      return ServiceablePlansResult(serviceable: false, plans: []);
    }
  }

  /// Purchase a subscription plan
  Future<String?> subscribeToPlan(int planId) async {
    try {
      final token = await AuthService.instance.getSavedToken();
      if (token == null) return 'Session expired. Please log in.';

      final uri = Uri.parse('$kBaseUrl/api/customer/subscribe');
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'plan_id': planId,
            }),
          )
          .timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] == true) {
        return null; // Null means success
      }
      return body['message']?.toString() ?? 'Failed to purchase plan.';
    } catch (e) {
      debugPrint('Error purchasing plan: $e');
      return e.toString();
    }
  }

  /// Get current customer subscription details
  Future<Map<String, dynamic>?> getCurrentSubscription({double? latitude, double? longitude}) async {
    try {
      final token = await AuthService.instance.getSavedToken();
      if (token == null) return null;

      String url = '$kBaseUrl/api/customer/subscription/current';
      if (latitude != null && longitude != null) {
        url += '?latitude=$latitude&longitude=$longitude';
      }

      final uri = Uri.parse(url);
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] == true) {
        return body['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting current subscription: $e');
      return null;
    }
  }

  /// Check if the customer has an active subscription with remaining deliveries
  Future<bool> hasActiveSubscription({double? latitude, double? longitude}) async {
    try {
      final data = await getCurrentSubscription(latitude: latitude, longitude: longitude);
      if (data == null) return false;
      final sub = data['subscription'] as Map<String, dynamic>?;
      if (sub == null) return false;
      final status = (sub['status'] ?? '').toString().toUpperCase();
      final remaining = int.tryParse(sub['remaining_deliveries']?.toString() ?? '0') ?? 0;
      return status == 'ACTIVE' && remaining > 0;
    } catch (e) {
      debugPrint('Error checking active subscription: $e');
      return false;
    }
  }

  /// Pause current subscription
  Future<String?> pauseSubscription() async {
    try {
      final token = await AuthService.instance.getSavedToken();
      if (token == null) return 'Session expired. Please log in.';

      final uri = Uri.parse('$kBaseUrl/api/customer/subscription/pause');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] == true) {
        return null;
      }
      return body['message']?.toString() ?? 'Failed to pause subscription.';
    } catch (e) {
      debugPrint('Error pausing subscription: $e');
      return e.toString();
    }
  }

  /// Resume current subscription
  Future<String?> resumeSubscription() async {
    try {
      final token = await AuthService.instance.getSavedToken();
      if (token == null) return 'Session expired. Please log in.';

      final uri = Uri.parse('$kBaseUrl/api/customer/subscription/resume');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] == true) {
        return null;
      }
      return body['message']?.toString() ?? 'Failed to resume subscription.';
    } catch (e) {
      debugPrint('Error resuming subscription: $e');
      return e.toString();
    }
  }

  /// Renew current subscription
  Future<String?> renewSubscription({int? planId}) async {
    try {
      final token = await AuthService.instance.getSavedToken();
      if (token == null) return 'Session expired. Please log in.';

      final uri = Uri.parse('$kBaseUrl/api/customer/subscription/renew');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'plan_id': planId,
        }),
      ).timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] == true) {
        return null;
      }
      return body['message']?.toString() ?? 'Failed to renew subscription.';
    } catch (e) {
      debugPrint('Error renewing subscription: $e');
      return e.toString();
    }
  }

  /// Get past subscription transactions list
  Future<List<dynamic>> getSubscriptionHistory() async {
    try {
      final token = await AuthService.instance.getSavedToken();
      if (token == null) return [];

      final uri = Uri.parse('$kBaseUrl/api/customer/subscription/history');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] == true && body['data'] != null) {
        return body['data']['subscriptions'] as List? ?? [];
      }
      return [];
    } catch (e) {
      debugPrint('Error getting subscription history: $e');
      return [];
    }
  }
}
