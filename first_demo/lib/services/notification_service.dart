// lib/services/notification_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/customer_notification.dart';
import '../utils/api_client.dart';
import '../utils/app_config.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);
  static const String _kLocalReadIdsKey = 'customer_read_notification_ids';

  Future<Set<String>> _getLocalReadIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_kLocalReadIdsKey) ?? [];
      return list.toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveLocalReadId(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_kLocalReadIdsKey) ?? [];
      if (!list.contains(id)) {
        list.add(id);
        await prefs.setStringList(_kLocalReadIdsKey, list);
      }
    } catch (_) {}
  }

  Future<void> _saveAllLocalReadIds(Iterable<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final set = (prefs.getStringList(_kLocalReadIdsKey) ?? []).toSet();
      set.addAll(ids);
      await prefs.setStringList(_kLocalReadIdsKey, set.toList());
    } catch (_) {}
  }

  /// Fetches customer notifications from the local / production API
  Future<List<CustomerNotification>> getNotifications() async {
    try {
      final url = Uri.parse('$kBaseUrl/api/customer/notifications');
      final response = await ApiClient.instance.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final listJson = data['data']['notifications'] as List? ?? [];
          final localReadIds = await _getLocalReadIds();

          final notifications = listJson.map((item) {
            final n = CustomerNotification.fromJson(item as Map<String, dynamic>);
            if (localReadIds.contains(n.id)) {
              n.isRead = true;
            }
            return n;
          }).toList();

          int unread = notifications.where((n) => !n.isRead).length;
          unreadCountNotifier.value = unread;
          return notifications;
        }
      }
      return [];
    } catch (e) {
      debugPrint('NotificationService error fetching notifications: $e');
      return [];
    }
  }

  /// Refreshes only the unread count
  Future<int> refreshUnreadCount() async {
    try {
      final list = await getNotifications();
      return list.where((n) => !n.isRead).length;
    } catch (_) {
      return 0;
    }
  }

  /// Marks a single notification as read
  Future<void> markAsRead(String id) async {
    await _saveLocalReadId(id);
    if (unreadCountNotifier.value > 0) {
      unreadCountNotifier.value--;
    }

    try {
      final url = Uri.parse('$kBaseUrl/api/customer/notifications/mark-read');
      await ApiClient.instance.post(
        url,
        body: jsonEncode({'notification_id': id}),
      );
    } catch (e) {
      debugPrint('NotificationService error marking notification as read: $e');
    }
  }

  /// Marks all notifications as read
  Future<void> markAllAsRead(List<String> allIds) async {
    await _saveAllLocalReadIds(allIds);
    unreadCountNotifier.value = 0;

    try {
      final url = Uri.parse('$kBaseUrl/api/customer/notifications/mark-read');
      await ApiClient.instance.post(
        url,
        body: jsonEncode({'all': true}),
      );
    } catch (e) {
      debugPrint('NotificationService error marking all notifications as read: $e');
    }
  }
}
