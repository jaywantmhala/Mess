// lib/screens/orders_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../services/websocket_service.dart';
import '../theme/app_theme.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with AutomaticKeepAliveClientMixin<OrdersScreen> {
  List<VendorOrder> _orders = [];
  bool _isLoading = true;
  StreamSubscription? _wsSubscription;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _startWebSocketListener();
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final orders = await OrderService.instance.getOrders();
    if (mounted) {
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    }
  }

  void _startWebSocketListener() {
    // Connect WS just in case
    WebSocketService.instance.connect(role: 'vendor');

    _wsSubscription = WebSocketService.instance.messages.listen((msg) {
      final event = msg['event'] as String?;
      final eventData = msg['data'];
      if (eventData == null) return;

      if (event == 'NEW_ORDER') {
        try {
          final newOrder = VendorOrder.fromJson(Map<String, dynamic>.from(eventData));
          if (mounted) {
            setState(() {
              // Avoid duplicates
              _orders.removeWhere((o) => o.orderId == newOrder.orderId);
              _orders.insert(0, newOrder);
            });
            // Show alert snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('🎉 New Order #${newOrder.orderId} received!'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        } catch (e) {
          debugPrint('Error parsing new order WebSocket payload: $e');
        }
      } else if (event == 'ORDER_STATUS_UPDATED') {
        try {
          final orderId = eventData['order_id'] as int?;
          final status = eventData['status'] as String?;
          if (orderId != null && status != null) {
            if (mounted) {
              setState(() {
                for (var order in _orders) {
                  if (order.orderId == orderId) {
                    order.status = status;
                    break;
                  }
                }
              });
            }
          }
        } catch (e) {
          debugPrint('Error updating order status from WebSocket payload: $e');
        }
      } else if (event == 'ORDER_ASSIGNED') {
        // When vendor assigns a driver, update the order card instantly
        try {
          final orderId = eventData['order_id'] as int?;
          final driverId = eventData['driver_id'] as int?;
          if (orderId != null && mounted) {
            // Stop the alert sound that may still be playing
            WebSocketService.instance.stopAlertSound();
            setState(() {
              for (var order in _orders) {
                if (order.orderId == orderId) {
                  order.status = 'assigned';
                  break;
                }
              }
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Driver assigned to Order #$orderId successfully!'),
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } catch (e) {
          debugPrint('Error handling ORDER_ASSIGNED in vendor: $e');
        }
      }
    });
  }

  Future<bool> _updateStatus(int orderId, String newStatus) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    final success = await OrderService.instance.updateOrderStatus(orderId, newStatus);
    
    // Dismiss loading indicator
    if (mounted) Navigator.pop(context);

    if (success) {
      if (mounted) {
        setState(() {
          for (var order in _orders) {
            if (order.orderId == orderId) {
              order.status = newStatus;
              break;
            }
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
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update order status. Please try again.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    return success;
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'created_order':
        return const Color(0xFFFFF3E0); // Soft orange
      case 'accepted':
        return const Color(0xFFE3F2FD); // Soft blue
      case 'preparing':
        return const Color(0xFFE0F2F1); // Soft teal
      case 'ready':
        return const Color(0xFFE8EAF6); // Soft indigo
      case 'completed':
        return AppColors.successSurface; // Soft green
      case 'rejected':
      case 'cancelled':
        return AppColors.errorSurface; // Soft red
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
    super.build(context);
    final bottomPad = MediaQuery.of(context).padding.bottom + 90;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text(
          'Live Orders',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: AppColors.ink,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _loadOrders,
              color: AppColors.primary,
              child: _orders.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                        const Center(
                          child: Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: AppColors.textHint,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            'No active orders found.',
                            style: AppText.bodyLarge.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Center(
                          child: Text(
                            'Any new orders placed will pop up here in real time.',
                            style: TextStyle(fontSize: 12, color: AppColors.textHint),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad),
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        return _buildOrderCard(_orders[index]);
                      },
                    ),
            ),
    );
  }

  Widget _buildOrderCard(VendorOrder order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row (Order ID & Time)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.orderId}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.createdAt,
                      style: const TextStyle(fontSize: 11, color: AppColors.textHint),
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
          ),
          const Divider(height: 1, color: AppColors.border),

          // Hotel & Customer Info Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Restaurant Tag
                Row(
                  children: [
                    const Icon(Icons.restaurant, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      order.hotelName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.inkMid,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Customer Details
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primarySurface,
                      child: Text(
                        order.customerName.isNotEmpty ? order.customerName[0].toUpperCase() : 'C',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.customerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.ink,
                            ),
                          ),
                          if (order.customerEmail.isNotEmpty)
                            Text(
                              order.customerEmail,
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Delivery Address
                if (order.deliveryAddress.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_rounded, size: 14, color: AppColors.textHint),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          order.deliveryAddress,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Menu Items Section
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ITEMS ORDERED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textHint,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: order.items.length,
                  itemBuilder: (context, idx) {
                    final item = order.items[idx];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item.quantity}x  ${item.foodName}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.inkMid,
                              ),
                            ),
                          ),
                          Text(
                            '₹${(item.price * item.quantity).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Grand Total',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      '₹${order.grandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Dynamic Action Buttons Section
          _buildActionButtons(order),
        ],
      ),
    );
  }

  Widget _buildActionButtons(VendorOrder order) {
    // If completed or cancelled or rejected, show no action buttons
    if (order.status == 'completed' || order.status == 'cancelled' || order.status == 'rejected') {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          // ── Case 1: NEW ORDER (created_order) ──────────────────────────────
          if (order.status == 'created_order') ...[
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => _updateStatus(order.orderId, 'rejected'),
                child: const Text(
                  'Reject',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                onPressed: () => _updateStatus(order.orderId, 'accepted'),
                child: const Text(
                  'Accept',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],

          // ── Case 2: ACCEPTED ───────────────────────────────────────────────
          if (order.status == 'accepted')
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                onPressed: () => _updateStatus(order.orderId, 'preparing'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.flatware_rounded, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'START PREPARING',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ),

          // ── Case 3: PREPARING ──────────────────────────────────────────────
          if (order.status == 'preparing')
            Expanded(
              child: ElevatedButton(
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.inventory_2_rounded, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'MARK AS READY',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ),

          // ── Case 4: READY ──────────────────────────────────────────────────
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
                icon: const Icon(Icons.person_add_rounded, size: 16),
                label: const Text(
                  'ASSIGN DRIVER',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
                ),
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
                child: const Text(
                  'COMPLETE MANUALLY',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],

          // ── Case 5: DRIVER ACTIVE DELIVERIES ──────────────────────────────
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
                    const Icon(Icons.delivery_dining_rounded, color: AppColors.primary, size: 18),
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
                        fontSize: 12,
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
                _loadOrders();
              },
            ),
          ),
        );
      },
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
    // Build driver list items as plain widgets (no ListView inside dialog)
    Widget body;
    if (_isLoading) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    } else if (_drivers.isEmpty) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_motorsports_outlined, size: 48, color: AppColors.textHint),
            SizedBox(height: 12),
            Text(
              'No available drivers online right now.',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              'Toggle a driver account online or complete manually.',
              style: TextStyle(fontSize: 12, color: AppColors.textHint),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else {
      // Build each driver card as a Column child — no ListView needed
      final cards = <Widget>[];
      for (int i = 0; i < _drivers.length; i++) {
        final d = _drivers[i];
        final isAssigning = _assigningDriverId == d.id;
        cards.add(
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.sports_motorsports_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.fullName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.ink),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Vehicle: ${d.vehicleNumber}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Active Tasks: ${d.activeOrderCount}/${d.maxCapacity}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: d.activeOrderCount >= d.maxCapacity ? AppColors.error : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: const Size(70, 36),
                  ),
                  onPressed: isAssigning ? null : () => _assignDriver(d.id),
                  child: isAssigning
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Assign', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      }
      body = SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: cards,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Assign Driver — Order #${widget.orderId}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.ink),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textHint),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 20),
          body,
        ],
      ),
    );
  }
}
