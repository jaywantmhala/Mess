// lib/services/vendor_notification_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vendor_notification.dart';
import '../utils/api_client.dart';
import '../utils/app_config.dart';

class VendorNotificationService {
  VendorNotificationService._();
  static final VendorNotificationService instance = VendorNotificationService._();

  final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);
  final ValueNotifier<List<VendorNotification>> notificationsNotifier =
      ValueNotifier<List<VendorNotification>>([]);

  static const String _kLocalReadIdsKey = 'vendor_read_notification_ids';
  Timer? _periodicTimer;

  void startPeriodicSync() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      refreshUnreadCount();
    });
  }

  void stopPeriodicSync() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

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

  /// Ingest an incoming realtime broadcast or push event immediately
  Future<void> handleRealtimeBroadcast(Map<String, dynamic> data) async {
    try {
      final notifId = data['notification_id']?.toString() ??
          (data['id'] != null ? 'admin_${data['id']}' : 'admin_live_${DateTime.now().millisecondsSinceEpoch}');
      final title = data['title']?.toString() ?? 'Announcement';
      final body = data['body']?.toString() ?? '';
      final imageUrl = data['image_url']?.toString();
      final clickAction = data['click_action']?.toString() ?? 'HOME';

      final currentList = List<VendorNotification>.from(notificationsNotifier.value);
      if (!currentList.any((n) => n.id == notifId)) {
        final newNotif = VendorNotification(
          id: notifId,
          rawId: int.tryParse(data['id']?.toString() ?? '0') ?? 0,
          source: 'admin',
          title: title,
          body: body,
          type: 'broadcast',
          imageUrl: (imageUrl != null && imageUrl.trim().isNotEmpty) ? imageUrl.trim() : null,
          clickAction: clickAction,
          createdAt: DateTime.now(),
          isRead: false,
          meta: data,
        );

        currentList.insert(0, newNotif);
        notificationsNotifier.value = currentList;
        unreadCountNotifier.value = unreadCountNotifier.value + 1;
      }

      // Silent sync with backend
      refreshUnreadCount();
    } catch (e) {
      debugPrint('VendorNotificationService handleRealtimeBroadcast error: $e');
    }
  }

  /// Fetches notifications for the authenticated vendor from local / remote API
  Future<List<VendorNotification>> getNotifications() async {
    try {
      final url = Uri.parse('$kBaseUrl/notifications');
      final response = await ApiClient.instance.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final listJson = data['data']['notifications'] as List? ?? [];
          final localReadIds = await _getLocalReadIds();

          final notifications = listJson.map((item) {
            final n = VendorNotification.fromJson(item as Map<String, dynamic>);
            if (localReadIds.contains(n.id)) {
              n.isRead = true;
            }
            return n;
          }).toList();

          int unread = notifications.where((n) => !n.isRead).length;
          unreadCountNotifier.value = unread;
          notificationsNotifier.value = notifications;
          return notifications;
        }
      }
      return [];
    } catch (e) {
      debugPrint('VendorNotificationService error fetching notifications: $e');
      return [];
    }
  }

  /// Refreshes unread count only
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

    // Update in-memory notifications
    final currentList = List<VendorNotification>.from(notificationsNotifier.value);
    for (final n in currentList) {
      if (n.id == id) {
        n.isRead = true;
      }
    }
    notificationsNotifier.value = currentList;

    try {
      final url = Uri.parse('$kBaseUrl/notifications/mark-read');
      await ApiClient.instance.post(
        url,
        body: jsonEncode({'notification_id': id}),
      );
    } catch (e) {
      debugPrint('VendorNotificationService error marking notification read: $e');
    }
  }

  /// Marks all notifications as read
  Future<void> markAllAsRead(List<String> allIds) async {
    await _saveAllLocalReadIds(allIds);
    unreadCountNotifier.value = 0;

    final currentList = List<VendorNotification>.from(notificationsNotifier.value);
    for (final n in currentList) {
      n.isRead = true;
    }
    notificationsNotifier.value = currentList;

    try {
      final url = Uri.parse('$kBaseUrl/notifications/mark-read');
      await ApiClient.instance.post(
        url,
        body: jsonEncode({'all': true}),
      );
    } catch (e) {
      debugPrint('VendorNotificationService error marking all read: $e');
    }
  }
}
