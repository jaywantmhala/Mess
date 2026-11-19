// lib/services/chat_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/app_config.dart';
import 'auth_service.dart';

class OrderChatMessage {
  final int id;
  final int orderId;
  final String senderType; // 'customer' or 'vendor'
  final int senderId;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  OrderChatMessage({
    required this.id,
    required this.orderId,
    required this.senderType,
    required this.senderId,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory OrderChatMessage.fromJson(Map<String, dynamic> json) {
    return OrderChatMessage(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      orderId: int.tryParse(json['order_id']?.toString() ?? '0') ?? 0,
      senderType: json['sender_type']?.toString() ?? 'customer',
      senderId: int.tryParse(json['sender_id']?.toString() ?? '0') ?? 0,
      message: json['message']?.toString() ?? '',
      isRead: json['is_read'] == true || json['is_read'] == 1 || json['is_read'] == '1',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class ChatServiceResult {
  final bool success;
  final String message;
  final bool isChatEnabled;
  final String hotelName;
  final int unreadCount;
  final List<OrderChatMessage> messages;

  ChatServiceResult({
    required this.success,
    required this.message,
    this.isChatEnabled = true,
    this.hotelName = 'Restaurant',
    this.unreadCount = 0,
    this.messages = const [],
  });
}

class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  /// Get messages for an order
  Future<ChatServiceResult> getMessages(int orderId) async {
    try {
      final token = await AuthService.instance.getSavedToken();
      if (token == null) {
        return ChatServiceResult(success: false, message: 'Authentication required.');
      }

      final uri = Uri.parse('$kBaseUrl/api/orders/chat/messages?order_id=$orderId');
      final res = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      }).timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        final payload = data['data'] as Map<String, dynamic>? ?? {};
        final list = (payload['messages'] as List? ?? [])
            .map((item) => OrderChatMessage.fromJson(item as Map<String, dynamic>))
            .toList();

        return ChatServiceResult(
          success: true,
          message: data['message']?.toString() ?? 'Success',
          isChatEnabled: payload['is_chat_enabled'] == true,
          hotelName: payload['hotel_name']?.toString() ?? 'Restaurant',
          unreadCount: int.tryParse(payload['unread_count']?.toString() ?? '0') ?? 0,
          messages: list,
        );
      }
      return ChatServiceResult(success: false, message: data['message']?.toString() ?? 'Failed to load messages.');
    } catch (e) {
      debugPrint('Error loading chat messages: $e');
      return ChatServiceResult(success: false, message: 'Connection error: $e');
    }
  }

  /// Send a message
  Future<bool> sendMessage(int orderId, String message) async {
    try {
      final token = await AuthService.instance.getSavedToken();
      if (token == null) return false;

      final uri = Uri.parse('$kBaseUrl/api/orders/chat/send');
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
      debugPrint('Error sending chat message: $e');
      return false;
    }
  }

  /// Mark messages as read
  Future<bool> markAsRead(int orderId) async {
    try {
      final token = await AuthService.instance.getSavedToken();
      if (token == null) return false;

      final uri = Uri.parse('$kBaseUrl/api/orders/chat/mark_read');
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
      debugPrint('Error marking chat as read: $e');
      return false;
    }
  }
}
