// lib/screens/order_details_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../services/websocket_service.dart';
import '../services/vendor_chat_service.dart';
import '../widgets/vendor_order_chat_sheet.dart';
import '../theme/app_theme.dart';
import '../utils/app_config.dart';

class OrderDetailsScreen extends StatefulWidget {
  final int orderId;
  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  VendorOrder? _order;
  bool _isLoading = true;
  bool _isUpdating = false;
  StreamSubscription? _wsSubscription;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadOrder();
    _startWebSocketListener();
    _fetchUnreadCount();
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    WebSocketService.instance.unsubscribeFromChannel(kOrderChatChannel(widget.orderId));
    super.dispose();
  }

  Future<void> _fetchUnreadCount() async {
    final res = await VendorChatService.instance.getMessages(widget.orderId);
    if (mounted && res.success) {
      setState(() {
        _unreadCount = res.unreadCount;
      });
    }
  }

  Future<void> _loadOrder() async {
    setState(() => _isLoading = true);
    final order = await OrderService.instance.getOrderById(widget.orderId);
    if (mounted) {
      setState(() {
        _order = order;
        _isLoading = false;
      });
    }
  }

  void _startWebSocketListener() {
    WebSocketService.instance.connect(role: 'vendor');
    WebSocketService.instance.subscribeToChannel(kOrderChatChannel(widget.orderId));
    _wsSubscription = WebSocketService.instance.messages.listen((msg) {
      final event = msg['event'] as String?;
      final eventData = msg['data'];
      if (eventData == null) return;

      final eventOrderId = int.tryParse(eventData['order_id']?.toString() ?? '');
      if (eventOrderId == widget.orderId) {
        if (event == 'ORDER_STATUS_UPDATED') {
          final newStatus = eventData['status'] as String?;
          if (newStatus != null && mounted) {
            setState(() {
              if (_order != null) {
                _order!.status = newStatus;
              }
            });
          }
        } else if (event == 'CHAT_MESSAGE') {
          if (eventData['sender_type'] == 'customer' && mounted) {
            setState(() {
              _unreadCount++;
            });
          }
        } else if (event == 'CHAT_READ_RECEIPT' && mounted) {
          setState(() {
            _unreadCount = 0;
          });
        }
      }
    });
  }

  Future<bool> _updateStatus(int orderId, String newStatus) async {
    setState(() => _isUpdating = true);

    bool success = false;
    try {
      success = await OrderService.instance.updateOrderStatus(orderId, newStatus);
    } catch (e) {
      debugPrint('Error updating status: $e');
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }

    if (success) {
      if (mounted) {
        setState(() {
          if (_order != null) {
            _order!.status = newStatus;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to "$newStatus".'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return true;
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update status. Please try again.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }
  }

  Future<void> _showDriverAssignmentSheet(int orderId) async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _DriverAssignmentSheetContent(
              orderId: orderId,
              onAssigned: () {
                _loadOrder();
              },
            ),
          ),
        );
      },
    );
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'created_order':
        return const Color(0xFFFFF3E0);
      case 'accepted':
        return const Color(0xFFE3F2FD);
      case 'preparing':
        return const Color(0xFFE0F2F1);
      case 'ready':
        return const Color(0xFFE8EAF6);
      case 'completed':
        return AppColors.successSurface;
      case 'rejected':
      case 'cancelled':
        return AppColors.errorSurface;
      default:
        return AppColors.border;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'created_order':
        return Colors.orange[800]!;
      case 'accepted':
        return Colors.blue[800]!;
      case 'preparing':
        return Colors.teal[800]!;
      case 'ready':
        return Colors.indigo[800]!;
      case 'completed':
        return AppColors.success;
      case 'rejected':
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.inkMid;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'created_order':
        return 'NEW ORDER';
      case 'accepted':
        return 'ACCEPTED';
      case 'preparing':
        return 'PREPARING';
      case 'ready':
        return 'READY';
      case 'completed':
        return 'DELIVERED';
      case 'rejected':
        return 'REJECTED';
      case 'cancelled':
        return 'CANCELLED';
      default:
        return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            title: Text(
              _order == null ? 'Order Details' : 'Order #${_order!.orderId}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: AppColors.ink,
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _order == null
                  ? const Center(
                      child: Text(
                        'Order not found.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildOrderInfoCard(_order!),
                          const SizedBox(height: 16),
                          _buildItemsCard(_order!),
                          const SizedBox(height: 24),
                          _buildActionButtonsWrapper(_order!),
                        ],
                      ),
                    ),
        ),
        if (_isUpdating)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.25),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOrderInfoCard(VendorOrder order) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order.orderId}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.createdAt,
                    style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _getStatusBgColor(order.status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStatusLabel(order.status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _getStatusTextColor(order.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: order.mealType.toLowerCase() == 'dinner' ? const Color(0xFFEEF2FF) : const Color(0xFFE6F4EA),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: order.mealType.toLowerCase() == 'dinner' ? const Color(0xFFC7D2FE) : const Color(0xFFA7F3D0),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      order.mealType.toLowerCase() == 'dinner' ? '🌙' : '🍛',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      order.mealType.toLowerCase() == 'dinner' ? 'Dinner' : 'Lunch',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: order.mealType.toLowerCase() == 'dinner' ? const Color(0xFF4F46E5) : const Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.border),
          ),
          Row(
            children: [
              const Icon(Icons.restaurant, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                order.hotelName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.inkMid,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primarySurface,
                child: Text(
                  order.customerName.isNotEmpty ? order.customerName[0].toUpperCase() : 'C',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.customerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.ink,
                      ),
                    ),
                    if (order.customerEmail.isNotEmpty)
                      Text(
                        order.customerEmail,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
              // Chat with Customer Button (Pre-pickup)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary),
                    onPressed: () async {
                      await VendorOrderChatSheet.show(
                        context,
                        orderId: order.orderId,
                        customerName: order.customerName,
                        isDriverAssigned: order.isDriverAssigned,
                      );
                      _fetchUnreadCount();
                    },
                  ),
                  if (_unreadCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981), // Green unread notification dot
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (order.deliveryAddress.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_rounded, size: 16, color: AppColors.textHint),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.deliveryAddress,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
                if (order.dropDistanceKm > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFFEDD5)),
                    ),
                    child: Text(
                      '${order.dropDistanceKm.toStringAsFixed(1)} km',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFC2410C),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsCard(VendorOrder order) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ITEMS ORDERED',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textHint,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: order.items.length,
            itemBuilder: (context, idx) {
              final item = order.items[idx];
              final List<String> optionals = item.selectedOptionalItems
                  .where((s) => s.trim().isNotEmpty)
                  .toList();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item.quantity}x  ${item.foodName}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        Text(
                          '₹${(item.price * item.quantity).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                    if (item.mandatoryItems.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Include: ${item.mandatoryItems.join(' + ')}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                    if (optionals.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Selected: ${optionals.join(' • ')}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.border),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Grand Total',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              Text(
                '₹${order.grandTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonsWrapper(VendorOrder order) {
    if (order.status == 'completed' || order.status == 'cancelled' || order.status == 'rejected') {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (order.status == 'created_order') ...[
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => _updateStatus(order.orderId, 'rejected'),
                child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                onPressed: () => _updateStatus(order.orderId, 'accepted'),
                child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
          if (order.status == 'accepted')
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                onPressed: () => _updateStatus(order.orderId, 'preparing'),
                icon: const Icon(Icons.flatware_rounded, size: 18),
                label: const Text('START PREPARING', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          if (order.status == 'preparing')
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                onPressed: () async {
                  final ok = await _updateStatus(order.orderId, 'ready');
                  if (ok && mounted) {
                    _showDriverAssignmentSheet(order.orderId);
                  }
                },
                icon: const Icon(Icons.inventory_2_rounded, size: 18),
                label: const Text('MARK AS READY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          if (order.status == 'ready') ...[
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                onPressed: () => _showDriverAssignmentSheet(order.orderId),
                icon: const Icon(Icons.person_add_rounded, size: 18),
                label: const Text('ASSIGN DRIVER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.success,
                  side: const BorderSide(color: AppColors.success, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => _updateStatus(order.orderId, 'completed'),
                child: const Text('COMPLETE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
          if (order.status == 'assigned' || order.status == 'accepted_by_driver' || order.status == 'picked_up')
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.delivery_dining_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      order.status == 'assigned'
                          ? 'AWAITING DRIVER ACCEPTANCE'
                          : order.status == 'accepted_by_driver'
                              ? 'DRIVER HEADING TO HOTEL'
                              : 'DRIVER DELIVERING ORDER',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DriverAssignmentSheetContent extends StatefulWidget {
  final int orderId;
  final VoidCallback onAssigned;

  const _DriverAssignmentSheetContent({
    required this.orderId,
    required this.onAssigned,
  });

  @override
  State<_DriverAssignmentSheetContent> createState() => _DriverAssignmentSheetContentState();
}

class _DriverAssignmentSheetContentState extends State<_DriverAssignmentSheetContent> {
  bool _isLoading = true;
  List<DriverOnline> _drivers = [];
  int? _assigningDriverId;

  @override
  void initState() {
    super.initState();
    _fetchDrivers();
  }

  Future<void> _fetchDrivers() async {
    final list = await OrderService.instance.getOnlineDrivers();
    if (mounted) {
      setState(() {
        _drivers = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _assignDriver(int driverId) async {
    setState(() => _assigningDriverId = driverId);
    final success = await OrderService.instance.assignDriver(widget.orderId, driverId);
    if (!mounted) return;

    setState(() => _assigningDriverId = null);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order successfully assigned to driver!'),
          backgroundColor: AppColors.success,
        ),
      );
      widget.onAssigned();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to assign driver. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Assign Driver',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else if (_drivers.isEmpty)
            const SizedBox(
              height: 120,
              child: Center(
                child: Text('No drivers are currently online.', style: TextStyle(color: AppColors.textSecondary)),
              ),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: _drivers.map((d) {
                    final isAssigning = _assigningDriverId == d.id;
                    final bool isBusy = d.activeOrderCount >= 1;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isBusy ? Colors.red.shade50.withValues(alpha: 0.5) : Colors.white,
                        border: Border.all(color: isBusy ? Colors.red.shade200 : AppColors.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d.fullName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Vehicle: ${d.vehicleNumber}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isBusy ? 'Busy (1 active order in progress)' : 'Available (0 active orders)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isBusy ? AppColors.error : AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isBusy ? Colors.grey.shade400 : AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: (isAssigning || isBusy) ? null : () => _assignDriver(d.id),
                            child: isAssigning
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(isBusy ? 'BUSY' : 'ASSIGN', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
