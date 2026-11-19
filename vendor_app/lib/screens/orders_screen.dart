// lib/screens/orders_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../services/auth_service.dart';
import '../services/websocket_service.dart';
import '../widgets/vendor_order_chat_sheet.dart';
import '../theme/app_theme.dart';
import 'vendor_order_tracking_screen.dart';

// ─── Local design tokens (matching reference photo) ───────────────────────────
const _kRed         = Color(0xFFE23744);
const _kRedSurface  = Color(0xFFFFF0F0);
const _kGreen       = Color(0xFF00A651);
const _kGreenSurf   = Color(0xFFEAF7EF);
const _kBg          = Color(0xFFF5F5F5);
const _kCard        = Colors.white;
const _kBorder      = Color(0xFFEEEEEE);
const _kInk         = Color(0xFF1C1C1E);
const _kMid         = Color(0xFF6C6C70);
const _kHint        = Color(0xFFAEAEB2);
const _kItemsBg     = Color(0xFFFFF5F5);
const _kShadow      = Color(0x0A000000);

class AccordionItem {
  final DateTime date;
  final String label;
  final String dateQueryParam;
  bool isExpanded = false;
  bool isLoading = false;
  List<VendorOrder> orders = [];

  AccordionItem({
    required this.date,
    required this.label,
    required this.dateQueryParam,
  });
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with AutomaticKeepAliveClientMixin<OrdersScreen> {
  List<VendorOrder> _orders = [];
  String _selectedMealFilter = 'All'; // 'All', 'Lunch', 'Dinner'
  bool _isOnline = true;
  bool _isLoading = true;
  bool _isUpdating = false;
  StreamSubscription? _wsSubscription;
  final List<AccordionItem> _pastDays = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializePastDays();
    _loadOrders();
    _startWebSocketListener();
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    super.dispose();
  }

  void _initializePastDays() {
    final now = DateTime.now();
    _pastDays.clear();
    for (int i = 1; i <= 14; i++) {
      final date = now.subtract(Duration(days: i));
      final queryParam = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      
      String label;
      if (i == 1) {
        label = "Yesterday";
      } else {
        const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
        label = "${months[date.month - 1]} ${date.day}, ${date.year}";
      }
      
      _pastDays.add(AccordionItem(
        date: date,
        label: label,
        dateQueryParam: queryParam,
      ));
    }
  }

  Future<void> _toggleAccordion(AccordionItem item) async {
    if (item.isExpanded) {
      setState(() {
        item.isExpanded = false;
      });
      return;
    }

    setState(() {
      item.isExpanded = true;
    });

    if (item.orders.isNotEmpty) return;

    setState(() {
      item.isLoading = true;
    });

    try {
      final fetched = await OrderService.instance.getOrders(date: item.dateQueryParam);
      if (mounted) {
        setState(() {
          item.orders = fetched.orders;
          item.isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading accordion orders: $e");
      if (mounted) {
        setState(() {
          item.isLoading = false;
        });
      }
    }
  }

  Widget _buildAccordionWidget(AccordionItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleAccordion(item),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 18, color: Colors.grey.shade500),
                      const SizedBox(width: 10),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    item.isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
            ),
          ),
          if (item.isExpanded) ...[
            const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
            if (item.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: _kRed),
                  ),
                ),
              )
            else if (item.orders.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    "No orders for this date.",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: item.orders.map((o) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _OrderCard(
                      order: o,
                      onUpdateStatus: _updateStatus,
                      onAssignDriver: _showDriverSheet,
                    ),
                  )).toList(),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    var result = await OrderService.instance.getOrders(date: todayStr);
    if (result.orders.isEmpty) {
      result = await OrderService.instance.getOrders();
    }
    if (mounted) {
      setState(() {
        _orders = result.orders;
        _isOnline = result.isOnline;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleVendorStatus(bool value) async {
    setState(() => _isLoading = true);
    final success = await OrderService.instance.updateVendorStatus(value);
    if (success) {
      if (mounted) {
        setState(() {
          _isOnline = value;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to update online status. Please try again."),
            backgroundColor: _kRed,
          ),
        );
      }
    }
  }

  void _startWebSocketListener() {
    WebSocketService.instance.connect(role: 'vendor');
    _wsSubscription = WebSocketService.instance.messages.listen((msg) {
      final event     = msg['event'] as String?;
      final eventData = msg['data'];
      if (eventData == null) return;

      if (event == 'NEW_ORDER') {
        try {
          final targetVendorId = WebSocketService.instance.extractVendorId(eventData);
          AuthService.instance.getSavedVendor().then((currentVendor) {
            if (currentVendor == null || currentVendor.id <= 0 || targetVendorId <= 0 || targetVendorId != currentVendor.id) return;

            final map = eventData is Map ? eventData : {};
            final data = map['data'] is Map ? map['data'] : map;

            final newOrder =
                VendorOrder.fromJson(Map<String, dynamic>.from(data));
            setState(() {
              _orders.removeWhere((o) => o.orderId == newOrder.orderId);
              _orders.insert(0, newOrder);
            });
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('🎉 New Order #${newOrder.orderId} received!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ));
          });
        } catch (e) {
          debugPrint('Error parsing NEW_ORDER: $e');
        }
      } else if (event == 'ORDER_STATUS_UPDATED') {
        try {
          final orderId = int.tryParse(eventData['order_id']?.toString() ?? '') ?? 0;
          final status  = eventData['status'] as String?;
          if (orderId > 0 && status != null && mounted) {
            setState(() {
              for (var o in _orders) {
                if (o.orderId == orderId) {
                  o.status = status;
                  break;
                }
              }
            });
          }
        } catch (e) {
          debugPrint('Error updating status from WS: $e');
        }
      } else if (event == 'ORDER_ASSIGNED') {
        try {
          final orderId = int.tryParse(eventData['order_id']?.toString() ?? '') ?? 0;
          if (orderId > 0 && mounted) {
            WebSocketService.instance.stopAlertSound();
            setState(() {
              for (var o in _orders) {
                if (o.orderId == orderId) {
                  o.status = 'assigned';
                  break;
                }
              }
            });
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('✅ Driver assigned to Order #$orderId!'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ));
          }
        } catch (e) {
          debugPrint('Error handling ORDER_ASSIGNED: $e');
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
      debugPrint('Error updating order status: $e');
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }

    if (success && mounted) {
      setState(() {
        for (var o in _orders) {
          if (o.orderId == orderId) {
            o.status = newStatus;
            break;
          }
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Order status updated to "$newStatus".'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to update order status. Please try again.'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
    return success;
  }

  // ── Status helpers ──────────────────────────────────────────────────────────
  static String _statusLabel(String s) {
    switch (s) {
      case 'created_order': return 'New Order';
      case 'accepted':      return 'Accepted';
      case 'preparing':     return 'Preparing';
      case 'ready':         return 'Ready';
      case 'assigned':      return 'Driver Assigned';
      case 'accepted_by_driver': return 'Driver En Route';
      case 'picked_up':     return 'Out for Delivery';
      case 'completed':     return 'Delivered';
      case 'rejected':      return 'Rejected';
      case 'cancelled':     return 'Cancelled';
      default:              return s;
    }
  }

  static Color _statusColor(String s) {
    switch (s) {
      case 'completed':     return _kGreen;
      case 'rejected':
      case 'cancelled':     return _kRed;
      case 'created_order': return const Color(0xFFFF9500);
      default:              return const Color(0xFF007AFF);
    }
  }

  static Color _statusBg(String s) {
    switch (s) {
      case 'completed':     return _kGreenSurf;
      case 'rejected':
      case 'cancelled':     return _kRedSurface;
      case 'created_order': return const Color(0xFFFFF3E0);
      default:              return const Color(0xFFE8F0FF);
    }
  }

  /// "Today, 02:37 PM" format
  static String _formatTime(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    final local = dt.toLocal();
    final now   = DateTime.now();
    final h     = local.hour > 12
        ? local.hour - 12
        : (local.hour == 0 ? 12 : local.hour);
    final min   = local.minute.toString().padLeft(2, '0');
    final p     = local.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '${h.toString().padLeft(2, '0')}:$min $p';

    if (local.year == now.year &&
        local.month == now.month &&
        local.day == now.day) {
      return 'Today, $timeStr';
    }
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    return '${months[local.month - 1]} ${local.day}, $timeStr';
  }

  /// Only time part: "02:37 PM"
  static String _timeOnly(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    final local = dt.toLocal();
    final h   = local.hour > 12
        ? local.hour - 12
        : (local.hour == 0 ? 12 : local.hour);
    final min = local.minute.toString().padLeft(2, '0');
    final p   = local.hour >= 12 ? 'PM' : 'AM';
    return '${h.toString().padLeft(2, '0')}:$min $p';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bottomPad = MediaQuery.of(context).padding.bottom + 90;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: _kBg,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AppHeader(
                  onRefresh: _loadOrders,
                  isOnline: _isOnline,
                  onToggleStatus: _toggleVendorStatus,
                ),

                // ── List ────────────────────────────────────────────────────────
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: _kRed))
                      : RefreshIndicator(
                          onRefresh: _loadOrders,
                          color: _kRed,
                          backgroundColor: Colors.white,
                          child: ListView(
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad),
                            children: [
                              // Meal Type Filter Bar (All / Lunch / Dinner)
                              Row(
                                children: [
                                  _buildMealFilterChip('All', 'All Orders'),
                                  const SizedBox(width: 8),
                                  _buildMealFilterChip('Lunch', '🍛 Lunch'),
                                  const SizedBox(width: 8),
                                  _buildMealFilterChip('Dinner', '🌙 Dinner'),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: _kRedSurface,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      "TODAY",
                                      style: TextStyle(
                                        color: _kRed,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Today's Orders (${_orders.where((o) => _selectedMealFilter == 'All' || (_selectedMealFilter == 'Lunch' && o.mealType.toLowerCase() == 'lunch') || (_selectedMealFilter == 'Dinner' && o.mealType.toLowerCase() == 'dinner')).length})",
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: _kInk,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (_orders.where((o) => _selectedMealFilter == 'All' || (_selectedMealFilter == 'Lunch' && o.mealType.toLowerCase() == 'lunch') || (_selectedMealFilter == 'Dinner' && o.mealType.toLowerCase() == 'dinner')).isEmpty)
                                Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(color: Colors.grey.shade200),
                                  ),
                                  color: Colors.white,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                                    child: Center(
                                      child: Text(
                                        _selectedMealFilter == 'All'
                                            ? "No orders received today yet."
                                            : "No $_selectedMealFilter orders received today.",
                                        style: const TextStyle(color: _kMid, fontSize: 13),
                                      ),
                                    ),
                                  ),
                                )
                              else
                                ..._orders.where((o) => _selectedMealFilter == 'All' || (_selectedMealFilter == 'Lunch' && o.mealType.toLowerCase() == 'lunch') || (_selectedMealFilter == 'Dinner' && o.mealType.toLowerCase() == 'dinner')).map((o) => Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: _OrderCard(
                                        order: o,
                                        onUpdateStatus: _updateStatus,
                                        onAssignDriver: _showDriverSheet,
                                      ),
                                    )),
                              const SizedBox(height: 28),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F0FF),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      "HISTORY",
                                      style: TextStyle(
                                        color: Color(0xFF1A73E8),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "Past Orders",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: _kInk,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ..._pastDays.map((item) => _buildAccordionWidget(item)),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
        if (_isUpdating)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.25),
              child: const Center(
                child: CircularProgressIndicator(color: _kRed),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMealFilterChip(String value, String label) {
    final bool isSelected = _selectedMealFilter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected ? Colors.white : _kInk,
        ),
      ),
      selected: isSelected,
      selectedColor: _kRed,
      backgroundColor: Colors.grey.shade100,
      elevation: 0,
      side: BorderSide.none,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedMealFilter = value;
          });
        }
      },
    );
  }

  Future<void> _showDriverSheet(int orderId) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: _DriverAssignmentSheetContent(
            orderId: orderId,
            onAssigned: _loadOrders,
          ),
        ),
      ),
    );
  }
}

// ─── App Header ───────────────────────────────────────────────────────────────

class _AppHeader extends StatelessWidget {
  const _AppHeader({
    required this.onRefresh,
    required this.isOnline,
    required this.onToggleStatus,
  });
  final VoidCallback onRefresh;
  final bool isOnline;
  final ValueChanged<bool> onToggleStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Live Orders',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: _kInk,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isOnline ? 'Online — accepting orders' : 'Offline — closed',
                  style: TextStyle(
                    fontSize: 12,
                    color: isOnline ? _kGreen : _kMid,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isOnline ? "Online" : "Offline",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isOnline ? _kGreen : _kRed,
                ),
              ),
              const SizedBox(width: 4),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: isOnline,
                  activeColor: _kGreen,
                  activeTrackColor: _kGreenSurf,
                  inactiveThumbColor: _kRed,
                  inactiveTrackColor: _kRedSurface,
                  onChanged: onToggleStatus,
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          // Refresh button — round bordered
          GestureDetector(
            onTap: onRefresh,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: _kBorder, width: 1.5),
                boxShadow: const [
                  BoxShadow(color: _kShadow, blurRadius: 6, offset: Offset(0, 1)),
                ],
              ),
              child: const Icon(Icons.refresh_rounded, color: _kRed, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Order Card ───────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onUpdateStatus,
    required this.onAssignDriver,
  });

  final VendorOrder order;
  final Future<bool> Function(int, String) onUpdateStatus;
  final Future<void> Function(int) onAssignDriver;

  @override
  Widget build(BuildContext context) {
    final sLabel = _OrdersScreenState._statusLabel(order.status);
    final sColor = _OrdersScreenState._statusColor(order.status);
    final sBg    = _OrdersScreenState._statusBg(order.status);
    final timeStr = _OrdersScreenState._formatTime(order.createdAt);
    final timeOnly = _OrdersScreenState._timeOnly(order.createdAt);
    final totalItems = order.items.fold(0, (s, i) => s + i.quantity);

    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder, width: 1),
        boxShadow: const [
          BoxShadow(color: _kShadow, blurRadius: 12, offset: Offset(0, 3)),
          BoxShadow(color: Color(0x05000000), blurRadius: 2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card Header ────────────────────────────────────────────────────
          _CardHeader(
            order: order,
            timeStr: timeStr,
            sLabel: sLabel,
            sColor: sColor,
            sBg: sBg,
          ),

          const Divider(height: 1, color: _kBorder),

          // ── Order type row (Dine-in / Delivery + Meal Type) ─────────────────
          _OrderTypeRow(paymentMethod: order.paymentMethod, mealType: order.mealType),

          const Divider(height: 1, color: _kBorder),

          // ── Customer info ──────────────────────────────────────────────────
          _CustomerSection(order: order),

          const Divider(height: 1, color: _kBorder),

          // ── Items ─────────────────────────────────────────────────────────
          _ItemsSection(order: order, totalItems: totalItems),

          // ── Footer: Order ID + Time ────────────────────────────────────────
          _CardFooter(orderId: order.orderId, timeOnly: timeOnly),

          // ── Action buttons ─────────────────────────────────────────────────
          _ActionButtons(
            order: order,
            onUpdateStatus: onUpdateStatus,
            onAssignDriver: onAssignDriver,
          ),
        ],
      ),
    );
  }
}

// ─── Card Header ──────────────────────────────────────────────────────────────

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.order,
    required this.timeStr,
    required this.sLabel,
    required this.sColor,
    required this.sBg,
  });

  final VendorOrder order;
  final String timeStr;
  final String sLabel;
  final Color sColor;
  final Color sBg;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Red icon box
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _kRed,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // Order ID + Time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order.orderId}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _kInk,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _kHint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: sBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: sColor.withValues(alpha: 0.25), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (sLabel == 'Delivered' || sLabel == 'Accepted')
                  Icon(Icons.check_circle_rounded, size: 13, color: sColor),
                if (sLabel == 'Delivered' || sLabel == 'Accepted')
                  const SizedBox(width: 4),
                Text(
                  sLabel,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: sColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 4),

          // Three-dot menu
          GestureDetector(
            onTap: () {},
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.more_vert_rounded, color: _kHint, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Order Type Row ───────────────────────────────────────────────────────────

class _OrderTypeRow extends StatelessWidget {
  const _OrderTypeRow({required this.paymentMethod, required this.mealType});
  final String paymentMethod;
  final String mealType;

  String get _label {
    // Map payment method / order type to readable label
    if (paymentMethod.toLowerCase().contains('dine')) return 'Dine-in';
    if (paymentMethod.toLowerCase().contains('delivery')) return 'Delivery';
    return 'Delivery';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDinner = mealType.toLowerCase() == 'dinner';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant_menu_rounded, size: 16, color: _kInk),
              const SizedBox(width: 8),
              Text(
                _label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kInk,
                ),
              ),
            ],
          ),
          // 🍛 Lunch / 🌙 Dinner Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDinner ? const Color(0xFFEEF2FF) : const Color(0xFFE6F4EA),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDinner ? const Color(0xFFC7D2FE) : const Color(0xFFA7F3D0),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isDinner ? '🌙' : '🍛',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 4),
                Text(
                  isDinner ? 'Dinner' : 'Lunch',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isDinner ? const Color(0xFF4F46E5) : const Color(0xFF047857),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Customer Section ─────────────────────────────────────────────────────────

class _CustomerSection extends StatelessWidget {
  const _CustomerSection({required this.order});
  final VendorOrder order;

  @override
  Widget build(BuildContext context) {
    final initial = order.customerName.isNotEmpty
        ? order.customerName[0].toUpperCase()
        : 'C';

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer row
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFF0F0F0),
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _kInk,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Name + rating
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          order.customerName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _kInk,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Rating badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded,
                                  size: 11, color: Color(0xFFFFB300)),
                              SizedBox(width: 2),
                              Text(
                                '4.8',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFFFB300),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (order.customerPhone != null && order.customerPhone!.isNotEmpty)
                          ? order.customerPhone!
                          : (order.customerEmail.isNotEmpty
                              ? order.customerEmail
                              : '+91 98765 43210'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: _kMid,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Action icons
              _CircleIconBtn(
                icon: Icons.phone_rounded,
                color: _kRed,
                bg: _kRedSurface,
                onTap: () {
                  HapticFeedback.lightImpact();
                  final phone = (order.customerPhone != null && order.customerPhone!.isNotEmpty)
                      ? order.customerPhone!
                      : '';
                  if (phone.isNotEmpty) {
                    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
                    launchUrl(Uri.parse('tel:$clean'));
                  }
                },
              ),
              const SizedBox(width: 8),
              _CircleIconBtn(
                icon: Icons.chat_bubble_outline_rounded,
                color: _kRed,
                bg: _kRedSurface,
                onTap: () async {
                  HapticFeedback.lightImpact();
                  await VendorOrderChatSheet.show(
                    context,
                    orderId: order.orderId,
                    customerName: order.customerName,
                    isDriverAssigned: order.isDriverAssigned,
                  );
                },
              ),
              // Live Driver Tracking Icon — only displayed when driver is assigned
              if (order.isDriverAssigned) ...[
                const SizedBox(width: 8),
                _CircleIconBtn(
                  icon: Icons.near_me_rounded,
                  color: Colors.white,
                  bg: _kRed,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => VendorOrderTrackingScreen(order: order),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),

          // Address & Distance
          if (order.deliveryAddress.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_rounded,
                    size: 15, color: _kRed),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.deliveryAddress,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _kMid,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
}

// ─── Items Section ────────────────────────────────────────────────────────────

class _ItemsSection extends StatelessWidget {
  const _ItemsSection({required this.order, required this.totalItems});
  final VendorOrder order;
  final int totalItems;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kItemsBg,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "Items Ordered" header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Items Ordered',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _kRed,
                ),
              ),
              Text(
                '$totalItems ${totalItems == 1 ? 'item' : 'items'}',
                style: const TextStyle(
                  fontSize: 12,
                  color: _kHint,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Item rows
          ...order.items.map((item) {
            final List<String> optionals = item.selectedOptionalItems
                .where((s) => s.trim().isNotEmpty)
                .toList();

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${item.quantity}x',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _kRed,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.foodName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _kInk,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '₹${(item.price * item.quantity).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _kInk,
                        ),
                      ),
                    ],
                  ),
                  // Mandatory Items
                  if (item.mandatoryItems.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Padding(
                      padding: const EdgeInsets.only(left: 26),
                      child: Text(
                        'Include: ${item.mandatoryItems.join(' + ')}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ),
                  ],
                  // Selected Optional Items / Customizations
                  if (optionals.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.only(left: 26),
                      child: Text(
                        'Selected: ${optionals.join(' • ')}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Card Footer ──────────────────────────────────────────────────────────────

class _CardFooter extends StatelessWidget {
  const _CardFooter({required this.orderId, required this.timeOnly});
  final int orderId;
  final String timeOnly;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _kBorder, width: 1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_outlined, size: 14, color: _kHint),
          const SizedBox(width: 5),
          Text(
            'Order ID: #$orderId',
            style: const TextStyle(
              fontSize: 11,
              color: _kHint,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          const Icon(Icons.access_time_rounded, size: 14, color: _kHint),
          const SizedBox(width: 5),
          Text(
            timeOnly,
            style: const TextStyle(
              fontSize: 11,
              color: _kHint,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action Buttons ───────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.order,
    required this.onUpdateStatus,
    required this.onAssignDriver,
  });

  final VendorOrder order;
  final Future<bool> Function(int, String) onUpdateStatus;
  final Future<void> Function(int) onAssignDriver;

  @override
  Widget build(BuildContext context) {
    final s = order.status;

    if (s == 'completed' || s == 'cancelled' || s == 'rejected') {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          // NEW ORDER
          if (s == 'created_order') ...[
            Expanded(
              child: _OutBtn(
                label: 'Reject',
                color: _kRed,
                onTap: () => onUpdateStatus(order.orderId, 'rejected'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SolidBtn(
                label: 'Accept Order',
                color: AppColors.success,
                onTap: () => onUpdateStatus(order.orderId, 'accepted'),
              ),
            ),
          ],

          // ACCEPTED
          if (s == 'accepted')
            Expanded(
              child: _SolidBtn(
                label: '🍳  Start Preparing',
                color: _kRed,
                onTap: () => onUpdateStatus(order.orderId, 'preparing'),
              ),
            ),

          // PREPARING
          if (s == 'preparing')
            Expanded(
              child: _SolidBtn(
                label: '📦  Mark as Ready',
                color: AppColors.warning,
                onTap: () async {
                  final ok =
                      await onUpdateStatus(order.orderId, 'ready');
                  if (ok) await onAssignDriver(order.orderId);
                },
              ),
            ),

          // READY
          if (s == 'ready') ...[
            Expanded(
              child: _SolidBtn(
                label: '🏍  Assign Driver',
                color: _kRed,
                onTap: () => onAssignDriver(order.orderId),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _OutBtn(
                label: 'Complete',
                color: AppColors.success,
                onTap: () =>
                    onUpdateStatus(order.orderId, 'completed'),
              ),
            ),
          ],

          // DRIVER ACTIVE
          if (s == 'assigned' ||
              s == 'accepted_by_driver' ||
              s == 'picked_up')
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => VendorOrderTrackingScreen(order: order),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    decoration: BoxDecoration(
                      color: _kRed.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: _kRed.withValues(alpha: 0.18), width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.delivery_dining_rounded,
                            color: _kRed, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            s == 'assigned'
                                ? 'Awaiting Acceptance'
                                : s == 'accepted_by_driver'
                                    ? 'Driver Heading to Hotel'
                                    : 'Driver Delivering Order',
                            style: const TextStyle(
                              color: _kRed,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: _kRed,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.near_me_rounded, color: Colors.white, size: 11),
                              SizedBox(width: 3),
                              Text(
                                'Track',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Reusable small widgets ───────────────────────────────────────────────────

class _CircleIconBtn extends StatelessWidget {
  const _CircleIconBtn({
    required this.icon,
    required this.color,
    required this.bg,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        ),
        child: Icon(icon, size: 17, color: color),
      ),
    );
  }
}

class _SolidBtn extends StatelessWidget {
  const _SolidBtn(
      {required this.label, required this.color, required this.onTap});
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _OutBtn extends StatelessWidget {
  const _OutBtn(
      {required this.label, required this.color, required this.onTap});
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}


// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _kRedSurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_long_outlined,
                    size: 36, color: _kRed),
              ),
              const SizedBox(height: 18),
              const Text(
                'No Active Orders',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _kInk,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'New orders will appear here in real time.',
                style: TextStyle(fontSize: 13, color: _kHint),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              GestureDetector(
                onTap: onRefresh,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: _kRed,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded,
                          color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text('Refresh',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Driver Assignment Sheet (unchanged logic, updated style) ─────────────────

class _DriverAssignmentSheetContent extends StatefulWidget {
  const _DriverAssignmentSheetContent({
    required this.orderId,
    required this.onAssigned,
  });
  final int orderId;
  final VoidCallback onAssigned;

  @override
  State<_DriverAssignmentSheetContent> createState() =>
      _DriverAssignmentSheetContentState();
}

class _DriverAssignmentSheetContentState
    extends State<_DriverAssignmentSheetContent> {
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
    if (mounted) setState(() { _drivers = list; _isLoading = false; });
  }

  Future<void> _assignDriver(int driverId) async {
    setState(() => _assigningDriverId = driverId);
    final success =
        await OrderService.instance.assignDriver(widget.orderId, driverId);
    if (!mounted) return;
    setState(() => _assigningDriverId = null);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Order successfully assigned to driver!'),
        backgroundColor: AppColors.success,
      ));
      widget.onAssigned();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to assign driver. Please try again.'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_isLoading) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    } else if (_drivers.isEmpty) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_motorsports_outlined,
                size: 48, color: AppColors.textHint),
            SizedBox(height: 12),
            Text('No available drivers online right now.',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary),
                textAlign: TextAlign.center),
            SizedBox(height: 4),
            Text('Toggle a driver account online or complete manually.',
                style: TextStyle(fontSize: 12, color: AppColors.textHint),
                textAlign: TextAlign.center),
          ],
        ),
      );
    } else {
      final cards = <Widget>[];
      for (final d in _drivers) {
        final isAssigning = _assigningDriverId == d.id;
        final bool isBusy = d.activeOrderCount >= 1;
        cards.add(Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isBusy ? Colors.red.shade50.withValues(alpha: 0.5) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isBusy ? Colors.red.shade200 : Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isBusy ? AppColors.error.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.sports_motorsports_rounded,
                    color: isBusy ? AppColors.error : AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.fullName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.ink)),
                    const SizedBox(height: 2),
                    Text('Vehicle: ${d.vehicleNumber}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
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
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isBusy ? Colors.grey.shade400 : AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  minimumSize: const Size(70, 36),
                ),
                onPressed: (isAssigning || isBusy) ? null : () => _assignDriver(d.id),
                child: isAssigning
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(isBusy ? 'Busy' : 'Assign',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ));
      }
      body = SingleChildScrollView(
          child:
              Column(mainAxisSize: MainAxisSize.min, children: cards));
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
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.ink),
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

// ─── Dotted Separator ──────────────────────────────────────────────────────────

class _DottedSeparator extends StatelessWidget {
  const _DottedSeparator();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 3.0;
        const dashHeight = 3.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Color(0xFFB0B0B5),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

