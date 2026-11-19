// lib/services/vendor_chat_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/app_config.dart';
import 'auth_service.dart';

class VendorChatMessage {
  final int id;
  final int orderId;
  final String senderType; // 'customer' or 'vendor'
  final int senderId;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  VendorChatMessage({
    required this.id,
    required this.orderId,
    required this.senderType,
    required this.senderId,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory VendorChatMessage.fromJson(Map<String, dynamic> json) {
    return VendorChatMessage(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      orderId: int.tryParse(json['order_id']?.toString() ?? '0') ?? 0,
      senderType: json['sender_type']?.toString() ?? 'vendor',
      senderId: int.tryParse(json['sender_id']?.toString() ?? '0') ?? 0,
      message: json['message']?.toString() ?? '',
      isRead: json['is_read'] == true || json['is_read'] == 1 || json['is_read'] == '1',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class VendorChatServiceResult {
  final bool success;
  final String message;
  final bool isChatEnabled;
  final int unreadCount;
  final List<VendorChatMessage> messages;

  VendorChatServiceResult({
    required this.success,
    required this.message,
    this.isChatEnabled = true,
    this.unreadCount = 0,
    this.messages = const [],
  });
}

class VendorChatService {
  VendorChatService._();
  static final VendorChatService instance = VendorChatService._();

  /// Get messages for an order
  Future<VendorChatServiceResult> getMessages(int orderId) async {
    try {
      final token = await AuthService.instance.getSavedToken();
      if (token == null) {
        return VendorChatServiceResult(success: false, message: 'Authentication required.');
      }

      final uri = Uri.parse('$kApiHost/orders/chat/messages?order_id=$orderId');
      final res = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      }).timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        final payload = data['data'] as Map<String, dynamic>? ?? {};
        final list = (payload['messages'] as List? ?? [])
            .map((item) => VendorChatMessage.fromJson(item as Map<String, dynamic>))
            .toList();

        return VendorChatServiceResult(
          success: true,
          message: data['message']?.toString() ?? 'Success',
          isChatEnabled: payload['is_chat_enabled'] == true,
          unreadCount: int.tryParse(payload['unread_count']?.toString() ?? '0') ?? 0,
          messages: list,
        );
      }
      return VendorChatServiceResult(success: false, message: data['message']?.toString() ?? 'Failed to load messages.');
    } catch (e) {
      debugPrint('Error loading vendor chat messages: $e');
      return VendorChatServiceResult(success: false, message: 'Connection error: $e');
    }
  }

  /// Send a message
  Future<bool> sendMessage(int orderId, String message) async {
    try {
      final token = await AuthService.instance.getSavedToken();
      if (token == null) return false;

      final uri = Uri.parse('$kApiHost/orders/chat/send');
      final res = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'order_id': orderId,
          'message': message,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['success'] == true;
    } catch (e) {
      debugPrint('Error sending vendor chat message: $e');
      return false;
    }
  }

  /// Mark messages as read
  Future<bool> markAsRead(int orderId) async {
    try {
      final token = await AuthService.instance.getSavedToken();
      if (token == null) return false;

      final uri = Uri.parse('$kApiHost/orders/chat/mark_read');
      final res = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'order_id': orderId,
        }),
      ).timeout(const Duration(seconds: 8));

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['success'] == true;
    } catch (e) {
      debugPrint('Error marking vendor chat as read: $e');
      return false;
    }
  }
}
