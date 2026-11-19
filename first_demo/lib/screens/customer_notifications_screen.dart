// lib/screens/customer_notifications_screen.dart
import 'package:flutter/material.dart';
import '../models/customer_notification.dart';
import '../models/order.dart';
import '../services/notification_service.dart';
import 'order_status_screen.dart';

class CustomerNotificationsScreen extends StatefulWidget {
  const CustomerNotificationsScreen({super.key});

  @override
  State<CustomerNotificationsScreen> createState() =>
      _CustomerNotificationsScreenState();
}

class _CustomerNotificationsScreenState
    extends State<CustomerNotificationsScreen> {
  static const Color _brandOrange = Color(0xFFF58220);
  static const Color _bgWarm = Color(0xFFF8F9FA);
  static const Color _ink = Color(0xFF1A1A2E);
  static const Color _greySub = Color(0xFF6B7280);

  bool _isLoading = true;
  List<CustomerNotification> _notifications = [];
  String _selectedFilter = 'all'; // 'all', 'orders', 'offers'

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final items = await NotificationService.instance.getNotifications();
    if (mounted) {
      setState(() {
        _notifications = items;
        _isLoading = false;
      });
    }
  }

  List<CustomerNotification> get _filteredNotifications {
    if (_selectedFilter == 'orders') {
      return _notifications.where((n) => n.type == 'order' || n.source == 'order').toList();
    } else if (_selectedFilter == 'offers') {
      return _notifications.where((n) => n.type != 'order' && n.source != 'order').toList();
    }
    return _notifications;
  }

  Future<void> _handleTapNotification(CustomerNotification notif) async {
    if (!notif.isRead) {
      setState(() {
        notif.isRead = true;
      });
      await NotificationService.instance.markAsRead(notif.id);
    }

    if (!mounted) return;

    // Check if it's an order notification
    final orderId = notif.meta['order_id'] ?? (notif.source == 'order' ? notif.rawId : null);
    if (orderId != null && int.tryParse(orderId.toString()) != null) {
      final parsedOrderId = int.parse(orderId.toString());
      final orderItem = OrderHistoryItem(
        orderId: parsedOrderId,
        hotelName: notif.meta['hotel_name']?.toString() ?? 'Restaurant',
        status: notif.meta['status']?.toString() ?? 'PLACED',
        grandTotal: 0.0,
        walletDeducted: 0.0,
        itemCount: 1,
        createdAt: notif.createdAt,
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderStatusScreen(initialOrder: orderItem),
        ),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    final allIds = _notifications.map((n) => n.id).toList();
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
    await NotificationService.instance.markAllAsRead(allIds);
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: _bgWarm,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _ink, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                color: _ink,
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
                  color: _brandOrange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount new',
                  style: const TextStyle(
                    color: _brandOrange,
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
                  color: _brandOrange,
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
                  'Broadcasts & Offers',
                  'offers',
                  _notifications.where((n) => n.type != 'order' && n.source != 'order').length,
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _brandOrange),
            )
          : RefreshIndicator(
              color: _brandOrange,
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
          color: isSelected ? _brandOrange : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : _greySub,
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

  Widget _buildNotificationCard(CustomerNotification notif) {
    final bool isOrder = notif.type == 'order' || notif.source == 'order';

    IconData iconData = Icons.notifications_rounded;
    Color iconColor = _brandOrange;
    Color iconBg = _brandOrange.withOpacity(0.1);

    if (isOrder) {
      final status = notif.meta['status']?.toString().toLowerCase() ?? '';
      if (status.contains('delivered') || status.contains('completed')) {
        iconData = Icons.check_circle_rounded;
        iconColor = const Color(0xFF10B981);
        iconBg = const Color(0xFF10B981).withOpacity(0.12);
      } else if (status.contains('assigned') || status.contains('delivery')) {
        iconData = Icons.delivery_dining_rounded;
        iconColor = const Color(0xFF3B82F6);
        iconBg = const Color(0xFF3B82F6).withOpacity(0.12);
      } else {
        iconData = Icons.receipt_long_rounded;
        iconColor = const Color(0xFFF58220);
        iconBg = const Color(0xFFF58220).withOpacity(0.12);
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
            color: notif.isRead ? const Color(0xFFE5E7EB) : _brandOrange.withOpacity(0.3),
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
                                color: _ink,
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
                                color: _brandOrange,
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
                          color: notif.isRead ? _greySub : const Color(0xFF374151),
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
                          Icon(Icons.access_time_rounded, size: 12, color: _greySub.withOpacity(0.8)),
                          const SizedBox(width: 4),
                          Text(
                            notif.timeAgo,
                            style: TextStyle(
                              color: _greySub.withOpacity(0.8),
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
                                  'Track Order',
                                  style: TextStyle(
                                    color: _brandOrange,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(width: 2),
                                Icon(Icons.arrow_forward_ios_rounded, color: _brandOrange, size: 10),
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
            // Big picture banner if attached
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
                  color: _brandOrange.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  size: 40,
                  color: _brandOrange,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'No Notifications Yet',
                style: TextStyle(
                  color: _ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'We\'ll notify you here about your order status, delicious offers, and important updates.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _greySub,
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
