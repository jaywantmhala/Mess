// lib/services/cart_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/app_config.dart';
import '../models/cart.dart';
import 'auth_service.dart';

const Duration _kCartTimeout = Duration(seconds: 15);

class HotelConflictException implements Exception {
  final String existingHotelName;
  final int existingHotelId;
  const HotelConflictException({
    required this.existingHotelName,
    required this.existingHotelId,
  });

  @override
  String toString() =>
      'Your cart has items from "$existingHotelName". Clear cart to add from new hotel.';
}

class CartService {
  CartService._();
  static final CartService instance = CartService._();

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.instance.getSavedToken();
    return {
      'Content-Type': 'application/json; charset=utf-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  CartSummary _parseCart(Map<String, dynamic> body) {
    if (body['success'] == true && body['data'] != null) {
      return CartSummary.fromJson(body['data'] as Map<String, dynamic>);
    }
    return CartSummary.empty();
  }

  // ── Get Cart ─────────────────────────────────────────────────────────────────

  Future<CartSummary> getCart() async {
    final headers = await _authHeaders();
    try {
      final response = await http
          .get(
            Uri.parse('$kBaseUrl/api/cart/list'),
            headers: headers,
          )
          .timeout(_kCartTimeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return _parseCart(body);
    } on SocketException {
      throw Exception('No internet connection');
    } catch (_) {
      return CartSummary.empty();
    }
  }

  // ── Add Item ─────────────────────────────────────────────────────────────────

  /// Throws [HotelConflictException] if cart has items from a different hotel.
  Future<CartSummary> addItem({
    required int menuItemId,
    required int hotelId,
    int quantity = 1,
  }) async {
    final headers = await _authHeaders();
    try {
      final response = await http
          .post(
            Uri.parse('$kBaseUrl/api/cart/add'),
            headers: headers,
            body: jsonEncode({
              'menu_item_id': menuItemId,
              'hotel_id': hotelId,
              'quantity': quantity,
            }),
          )
          .timeout(_kCartTimeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      // Hotel conflict
      if (body['hotel_conflict'] == true) {
        throw HotelConflictException(
          existingHotelName: body['existing_hotel_name'] as String? ?? 'another hotel',
          existingHotelId: int.parse((body['existing_hotel_id'] ?? 0).toString()),
        );
      }

      if (body['success'] == true && body['data'] != null) {
        return CartSummary.fromJson(body['data'] as Map<String, dynamic>);
      }
      throw Exception(body['message'] ?? 'Failed to add item');
    } on HotelConflictException {
      rethrow;
    } on SocketException {
      throw Exception('No internet connection');
    } catch (e) {
      rethrow;
    }
  }

  // ── Update Item ───────────────────────────────────────────────────────────────

  /// Pass [quantity] = 0 to remove the item.
  Future<CartSummary> updateItem({
    required int cartItemId,
    required int quantity,
  }) async {
    final headers = await _authHeaders();
    try {
      final response = await http
          .post(
            Uri.parse('$kBaseUrl/api/cart/update'),
            headers: headers,
            body: jsonEncode({
              'cart_item_id': cartItemId,
              'quantity': quantity,
            }),
          )
          .timeout(_kCartTimeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return _parseCart(body);
    } on SocketException {
      throw Exception('No internet connection');
    } catch (_) {
      return CartSummary.empty();
    }
  }

  // ── Clear Cart ───────────────────────────────────────────────────────────────

  Future<void> clearCart() async {
    final headers = await _authHeaders();
    try {
      await http
          .post(
            Uri.parse('$kBaseUrl/api/cart/clear'),
            headers: headers,
          )
          .timeout(_kCartTimeout);
    } catch (_) {}
  }
}
