// lib/services/menu_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/menu_item.dart';
import 'auth_service.dart';

const String _baseIp = '127.0.0.1';
const String _baseUrl = 'http://$_baseIp:8000/api/vendor/menu';
const Duration _timeout = Duration(seconds: 15);

class MenuResult {
  final bool success;
  final String message;
  final MenuItem? menuItem;

  const MenuResult({
    required this.success,
    required this.message,
    this.menuItem,
  });
}

class MenuService {
  MenuService._();
  static final MenuService instance = MenuService._();

  /// Retrieve menu items for a hotel and date
  Future<List<MenuItem>> getMenuItems(int hotelId, String date) async {
    try {
      final token = await AuthService.instance.getSavedToken();
      if (token == null) return [];

      final uri = Uri.parse('$_baseUrl/list').replace(
        queryParameters: {'hotel_id': hotelId.toString(), 'date': date},
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
        final list = data['menu_items'] as List;
        return list
            .map((item) => MenuItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting menu items: $e');
      return [];
    }
  }

  /// Adds a new daily menu item
  Future<MenuResult> addMenuItem({
    required int hotelId,
    required String foodName,
    required String description,
    required String foodType,
    required double price,
    required String spiceLevel,
    required bool isPopular,
    required bool isAvailable,
    required String menuDate,
    String? imageUrl,
  }) async {
    try {
      final token = await AuthService.instance.getSavedToken();
      if (token == null) {
        return const MenuResult(success: false, message: 'Unauthorized.');
      }

      final response = await http
          .post(
            Uri.parse('$_baseUrl/add'),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'hotel_id': hotelId,
              'food_name': foodName.trim(),
              'description': description.trim(),
              'food_type': foodType,
              'price': price,
              'spice_level': spiceLevel,
              'is_popular': isPopular ? 1 : 0,
              'is_available': isAvailable ? 1 : 0,
              'menu_date': menuDate,
              if (imageUrl != null) 'image_url': imageUrl,
            }),
          )
          .timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final bool ok = body['success'] == true;

      if (ok) {
        final data = body['data'] as Map<String, dynamic>;
        final item = MenuItem.fromJson(
          data['menu_item'] as Map<String, dynamic>,
        );
        return MenuResult(
          success: true,
          message: body['message'] as String,
          menuItem: item,
        );
      }

      return MenuResult(
        success: false,
        message: body['message'] as String? ?? 'Failed to add food item.',
      );
    } on SocketException {
      return const MenuResult(success: false, message: 'Server unreachable.');
    } catch (e) {
      return MenuResult(success: false, message: 'Error: $e');
    }
  }

  /// Edits an existing menu item
  Future<MenuResult> editMenuItem({
    required int id,
    required String foodName,
    required String description,
    required String foodType,
    required double price,
    required String spiceLevel,
    required bool isPopular,
    required bool isAvailable,
    required String menuDate,
    String? imageUrl,
  }) async {
    try {
      final token = await AuthService.instance.getSavedToken();
      if (token == null) {
        return const MenuResult(success: false, message: 'Unauthorized.');
      }

      final response = await http
          .post(
            Uri.parse('$_baseUrl/edit'),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'id': id,
              'food_name': foodName.trim(),
              'description': description.trim(),
              'food_type': foodType,
              'price': price,
              'spice_level': spiceLevel,
              'is_popular': isPopular ? 1 : 0,
              'is_available': isAvailable ? 1 : 0,
              'menu_date': menuDate,
              if (imageUrl != null) 'image_url': imageUrl,
            }),
          )
          .timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final bool ok = body['success'] == true;

      if (ok) {
        final data = body['data'] as Map<String, dynamic>;
        final item = MenuItem.fromJson(
          data['menu_item'] as Map<String, dynamic>,
        );
        return MenuResult(
          success: true,
          message: body['message'] as String,
          menuItem: item,
        );
      }

      return MenuResult(
        success: false,
        message: body['message'] as String? ?? 'Failed to update food item.',
      );
    } on SocketException {
      return const MenuResult(success: false, message: 'Server unreachable.');
    } catch (e) {
      return MenuResult(success: false, message: 'Error: $e');
    }
  }

  /// Deletes a menu item
  Future<MenuResult> deleteMenuItem(int id) async {
    try {
      final token = await AuthService.instance.getSavedToken();
      if (token == null) {
        return const MenuResult(success: false, message: 'Unauthorized.');
      }

      final response = await http
          .post(
            Uri.parse('$_baseUrl/delete'),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'id': id}),
          )
          .timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final bool ok = body['success'] == true;

      return MenuResult(
        success: ok,
        message:
            body['message'] as String? ??
            (ok
                ? 'Food item deleted successfully.'
                : 'Failed to delete food item.'),
      );
    } on SocketException {
      return const MenuResult(success: false, message: 'Server unreachable.');
    } catch (e) {
      return MenuResult(success: false, message: 'Error: $e');
    }
  }
}
