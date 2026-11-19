// lib/screens/vendor_notifications_screen.dart
import 'package:flutter/material.dart';
import '../models/vendor_notification.dart';
import '../services/vendor_notification_service.dart';
import '../theme/app_theme.dart';
import 'order_details_screen.dart';

class VendorNotificationsScreen extends StatefulWidget {
  const VendorNotificationsScreen({super.key});

  @override
  State<VendorNotificationsScreen> createState() =>
      _VendorNotificationsScreenState();
}

class _VendorNotificationsScreenState
    extends State<VendorNotificationsScreen> {
  bool _isLoading = true;
  List<VendorNotification> _notifications = [];
  String _selectedFilter = 'all'; // 'all', 'orders', 'broadcasts'

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    VendorNotificationService.instance.notificationsNotifier.addListener(_onNotificationsChanged);
  }

  void _onNotificationsChanged() {
    if (mounted) {
      setState(() {
        _notifications = VendorNotificationService.instance.notificationsNotifier.value;
      });
    }
  }

  @override
  void dispose() {
    VendorNotificationService.instance.notificationsNotifier.removeListener(_onNotificationsChanged);
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final items = await VendorNotificationService.instance.getNotifications();
    if (mounted) {
      setState(() {
        _notifications = items;
        _isLoading = false;
      });
    }
  }

  List<VendorNotification> get _filteredNotifications {
    if (_selectedFilter == 'orders') {
      return _notifications.where((n) => n.type == 'order' || n.source == 'order').toList();
    } else if (_selectedFilter == 'broadcasts') {
      return _notifications.where((n) => n.type != 'order' && n.source != 'order').toList();
    }
    return _notifications;
  }

  Future<void> _handleTapNotification(VendorNotification notif) async {
    if (!notif.isRead) {
      setState(() {
        notif.isRead = true;
      });
      await VendorNotificationService.instance.markAsRead(notif.id);
    }

    if (!mounted) return;

    final orderId = notif.meta['order_id'] ?? (notif.source == 'order' ? notif.rawId : null);
    if (orderId != null && int.tryParse(orderId.toString()) != null) {
      final parsedOrderId = int.parse(orderId.toString());
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderDetailsScreen(orderId: parsedOrderId),
        ),
      );
    } else {
      _showNotificationDialog(notif);
    }
  }

  void _showNotificationDialog(VendorNotification notif) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.campaign_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notif.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          notif.timeAgo,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (notif.imageUrl != null && notif.imageUrl!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    notif.imageUrl!,
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Text(
                notif.body,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  ),
                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _markAllAsRead() async {
    final allIds = _notifications.map((n) => n.id).toList();
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
    await VendorNotificationService.instance.markAllAsRead(allIds);
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.ink, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount new',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
              ),
            ),
            child: Row(
              children: [
                _buildFilterChip('All', 'all', _notifications.length),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Orders',
                  'orders',
                  _notifications.where((n) => n.type == 'order' || n.source == 'order').length,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Broadcasts & System',
                  'broadcasts',
                  _notifications.where((n) => n.type != 'order' && n.source != 'order').length,
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadNotifications,
              child: _filteredNotifications.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      itemCount: _filteredNotifications.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final notif = _filteredNotifications[index];
                        return _buildNotificationCard(notif);
                      },
                    ),
            ),
    );
  }

  Widget _buildFilterChip(String label, String key, int count) {
    final isSelected = _selectedFilter == key;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = key),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                '($count)',
                style: TextStyle(
                  color: isSelected ? Colors.white.withOpacity(0.85) : const Color(0xFF9CA3AF),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(VendorNotification notif) {
    final bool isOrder = notif.type == 'order' || notif.source == 'order';

    IconData iconData = Icons.notifications_rounded;
    Color iconColor = AppColors.primary;
    Color iconBg = AppColors.primary.withOpacity(0.1);

    if (isOrder) {
      final status = notif.meta['status']?.toString().toLowerCase() ?? '';
      if (status.contains('delivered') || status.contains('completed')) {
        iconData = Icons.check_circle_rounded;
        iconColor = const Color(0xFF10B981);
        iconBg = const Color(0xFF10B981).withOpacity(0.12);
      } else if (status.contains('assigned') || status.contains('driver')) {
        iconData = Icons.two_wheeler_rounded;
        iconColor = const Color(0xFF3B82F6);
        iconBg = const Color(0xFF3B82F6).withOpacity(0.12);
      } else if (status.contains('cancel')) {
        iconData = Icons.cancel_rounded;
        iconColor = const Color(0xFFEF4444);
        iconBg = const Color(0xFFEF4444).withOpacity(0.12);
      } else {
        iconData = Icons.storefront_rounded;
        iconColor = AppColors.primary;
        iconBg = AppColors.primary.withOpacity(0.12);
      }
    } else if (notif.type == 'broadcast') {
      iconData = Icons.campaign_rounded;
      iconColor = const Color(0xFF8B5CF6);
      iconBg = const Color(0xFF8B5CF6).withOpacity(0.12);
    }

    return InkWell(
      onTap: () => _handleTapNotification(notif),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: notif.isRead ? Colors.white : const Color(0xFFFFF9F3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notif.isRead ? const Color(0xFFE5E7EB) : AppColors.primary.withOpacity(0.3),
            width: notif.isRead ? 1 : 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Avatar
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notif.title,
                              style: TextStyle(
                                color: AppColors.ink,
                                fontSize: 14,
                                fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w700,
                              ),
                            ),
                          ),
                          if (!notif.isRead) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notif.body,
                        style: TextStyle(
                          color: notif.isRead ? AppColors.textSecondary : const Color(0xFF374151),
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                      if (notif.imageUrl != null && notif.imageUrl!.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            notif.imageUrl!.trim(),
                            width: double.infinity,
                            height: 140,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 12, color: AppColors.textSecondary.withOpacity(0.8)),
                          const SizedBox(width: 4),
                          Text(
                            notif.timeAgo,
                            style: TextStyle(
                              color: AppColors.textSecondary.withOpacity(0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (isOrder && notif.meta['order_id'] != null) ...[
                            const Spacer(),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text(
                                  'View Order',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(width: 2),
                                Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary, size: 10),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Picture banner if attached
            if (notif.imageUrl != null && notif.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  notif.imageUrl!,
                  width: double.infinity,
                  height: 140,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'No Notifications Yet',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Orders from customers, driver pickups, and platform announcements will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
