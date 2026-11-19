// lib/screens/your_orders_screen.dart
import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import 'order_status_screen.dart';

// ─── Design Tokens ─────────────────────────────────────────────────────────────
const _kBg            = Color(0xFFF4F5F7);
const _kCardBg        = Colors.white;
const _kTextDark      = Color(0xFF1A1A2E);
const _kTextMid       = Color(0xFF4B5563);
const _kTextLight     = Color(0xFF9CA3AF);
const _kBorderColor   = Color(0xFFE9EAEC);
const _kTimelineDot   = Color(0xFF1A1A2E);
const _kTimelineLine  = Color(0xFFDDE0E7);
const _kGreen         = Color(0xFF10B981);
const _kRed           = Color(0xFFEF4444);
const _kAmber         = Color(0xFFF59E0B);
const _kCoralPrimary  = Color(0xFFF07070);
const _kDarkBtn       = Color(0xFF1A1A2E);
const _kShadow        = Color(0x0D000000);

class YourOrdersScreen extends StatefulWidget {
  const YourOrdersScreen({super.key});

  @override
  State<YourOrdersScreen> createState() => _YourOrdersScreenState();
}

class _YourOrdersScreenState extends State<YourOrdersScreen> {
  final List<OrderHistoryItem> _orders = [];
  int _currentPage = 1;
  static const int _limit = 5;
  bool _isFirstLoad = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders({bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 1;
      _hasMore = true;
      _orders.clear();
      if (mounted) setState(() => _isFirstLoad = true);
    } else {
      if (!_hasMore) return;
      if (mounted) {
        setState(() {
          if (_currentPage > 1) {
            _isLoadingMore = true;
          } else {
            _isFirstLoad = true;
          }
        });
      }
    }

    try {
      final newOrders = await OrderService.instance.getHistory(
        page: _currentPage,
        limit: _limit,
      );
      if (mounted) {
        setState(() {
          _orders.addAll(newOrders);
          _isFirstLoad = false;
          _isLoadingMore = false;
          if (newOrders.length < _limit) {
            _hasMore = false;
          } else {
            _currentPage++;
          }
        });
      }
    } catch (e) {
      debugPrint('Failed to load orders: $e');
      if (mounted) {
        setState(() {
          _isFirstLoad = false;
          _isLoadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load orders. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _openOrderStatus(OrderHistoryItem order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderStatusScreen(initialOrder: order),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(),
      body: _isFirstLoad
          ? const _LoadingView()
          : RefreshIndicator(
              color: _kCoralPrimary,
              backgroundColor: Colors.white,
              strokeWidth: 2.5,
              onRefresh: () => _fetchOrders(isRefresh: true),
              child: _orders.isEmpty
                  ? _EmptyView(onRefresh: () => _fetchOrders(isRefresh: true))
                  : _OrderList(
                      orders: _orders,
                      hasMore: _hasMore,
                      isLoadingMore: _isLoadingMore,
                      onLoadMore: _fetchOrders,
                      onViewDetails: _openOrderStatus,
                      onReorder: _openOrderStatus,
                    ),
            ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: const Color(0x1A000000),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: _kTextDark, size: 20),
        onPressed: () => Navigator.pop(context),
        tooltip: 'Back',
      ),
      title: const Text(
        'Order History',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: _kTextDark,
          letterSpacing: -0.3,
        ),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _kBorderColor),
      ),
    );
  }
}

// ─── Order List ─────────────────────────────────────────────────────────────────

class _OrderList extends StatelessWidget {
  const _OrderList({
    required this.orders,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
    required this.onViewDetails,
    required this.onReorder,
  });

  final List<OrderHistoryItem> orders;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;
  final ValueChanged<OrderHistoryItem> onViewDetails;
  final ValueChanged<OrderHistoryItem> onReorder;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: orders.length + 1,
      itemBuilder: (context, index) {
        if (index == orders.length) {
          return _FooterWidget(
            hasMore: hasMore,
            isLoadingMore: isLoadingMore,
            onLoadMore: onLoadMore,
          );
        }

        final order = orders[index];
        final isLast = index == orders.length - 1;

        return _TimelineOrderRow(
          order: order,
          isLast: isLast,
          onViewDetails: () => onViewDetails(order),
          onReorder: () => onReorder(order),
        );
      },
    );
  }
}

// ─── Timeline Row (dot + line + card) ───────────────────────────────────────────

class _TimelineOrderRow extends StatelessWidget {
  const _TimelineOrderRow({
    required this.order,
    required this.isLast,
    required this.onViewDetails,
    required this.onReorder,
  });

  final OrderHistoryItem order;
  final bool isLast;
  final VoidCallback onViewDetails;
  final VoidCallback onReorder;

  @override
  Widget build(BuildContext context) {
    const double dotSize   = 14.0;
    const double dotOffset = 22.0; // vertical offset for dot from card top

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Timeline column ──────────────────────────────────────────────────
          SizedBox(
            width: 30,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // Vertical line (drawn behind the dot)
                Positioned(
                  top: dotOffset + dotSize / 2,
                  bottom: isLast ? null : 0,
                  left: (30 - 2) / 2,
                  child: isLast
                      ? const SizedBox.shrink()
                      : Container(
                          width: 2,
                          color: _kTimelineLine,
                        ),
                ),
                // Dot
                Positioned(
                  top: dotOffset - dotSize / 2,
                  child: Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      color: _kTimelineDot,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x28000000),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // ── Card ─────────────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: _OrderCard(
                order: order,
                onViewDetails: onViewDetails,
                onReorder: onReorder,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Order Card ─────────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onViewDetails,
    required this.onReorder,
  });

  final OrderHistoryItem order;
  final VoidCallback onViewDetails;
  final VoidCallback onReorder;

  static Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'delivered':
        return _kGreen;
      case 'cancelled':
      case 'rejected':
      case 'rejected_by_driver':
        return _kRed;
      default:
        return _kAmber;
    }
  }

  static String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'created_order':
        return 'Order Created';
      case 'rejected_by_driver':
        return 'Driver Rejected';
      case 'accepted_by_driver':
        return 'Driver Accepted';
      case 'picked_up':
        return 'Out for Delivery';
      case 'completed':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        if (status.isEmpty) return 'Pending';
        return status[0].toUpperCase() + status.substring(1);
    }
  }

  static String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final d = dt.day.toString().padLeft(2, '0');
    final m = months[dt.month - 1];
    final y = dt.year;
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final hRaw = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final h = hRaw.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d $m $y • $h:$min $period';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status);
    final statusLabel = _statusLabel(order.status);
    final dateStr     = _formatDate(order.createdAt);
    final totalStr    = '₹${order.grandTotal.toStringAsFixed(2)}';
    final summaryStr  =
        '${order.itemCount} ${order.itemCount == 1 ? 'item' : 'items'}  ·  Total $totalStr';

    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorderColor, width: 1),
        boxShadow: const [
          BoxShadow(color: _kShadow, blurRadius: 12, offset: Offset(0, 2)),
          BoxShadow(color: Color(0x06000000), blurRadius: 1, offset: Offset(0, 0)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onViewDetails,
          splashColor: _kTextDark.withOpacity(0.04),
          highlightColor: _kTextDark.withOpacity(0.03),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Main content (left 2/3) ─────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: Status badge + Meal Type badge  |  Order ID + Date
                      Row(
                        children: [
                          _StatusBadge(
                              label: statusLabel, color: statusColor),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: order.mealType.toLowerCase() == 'dinner'
                                  ? const Color(0xFFEEF2FF)
                                  : const Color(0xFFE6F4EA),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: order.mealType.toLowerCase() == 'dinner'
                                    ? const Color(0xFFC7D2FE)
                                    : const Color(0xFFA7F3D0),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  order.mealType.toLowerCase() == 'dinner' ? '🌙' : '🍛',
                                  style: const TextStyle(fontSize: 10),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  order.mealType.toLowerCase() == 'dinner' ? 'Dinner' : 'Lunch',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: order.mealType.toLowerCase() == 'dinner'
                                        ? const Color(0xFF4F46E5)
                                        : const Color(0xFF047857),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '#${order.orderId}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: _kTextMid,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dateStr,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: _kTextLight,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),
                      const Divider(height: 1, color: _kBorderColor),
                      const SizedBox(height: 10),

                      // Row 2: Thumbnail + Restaurant name
                      Row(
                        children: [
                          _FoodThumbnail(hotelName: order.hotelName),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              order.hotelName,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: _kTextDark,
                                letterSpacing: -0.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Row 3: Summary (items · total)
                      Text(
                        summaryStr,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _kTextMid,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // ── Action buttons (right side, stacked) ───────────────────
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const SizedBox(height: 28), // push buttons lower
                    _ActionButton(
                      label: 'View Details',
                      isPrimary: false,
                      onTap: onViewDetails,
                    ),
                    const SizedBox(height: 6),
                    _ActionButton(
                      label: 'Reorder',
                      isPrimary: true,
                      onTap: onReorder,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Status Badge ───────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Food Thumbnail ──────────────────────────────────────────────────────────────

class _FoodThumbnail extends StatelessWidget {
  const _FoodThumbnail({required this.hotelName});

  final String hotelName;

  @override
  Widget build(BuildContext context) {
    // Generate a pastel colour deterministically from the hotel name
    final hue = (hotelName.codeUnits.fold(0, (a, b) => a + b) % 360).toDouble();
    final bg  = HSLColor.fromAHSL(1.0, hue, 0.55, 0.92).toColor();
    final fg  = HSLColor.fromAHSL(1.0, hue, 0.6, 0.35).toColor();

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorderColor, width: 1),
      ),
      child: Center(
        child: Text(
          hotelName.isNotEmpty ? hotelName[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: fg,
          ),
        ),
      ),
    );
  }
}

// ─── Action Button ───────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 32,
      child: Material(
        color: isPrimary ? _kDarkBtn : Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          splashColor:
              isPrimary ? Colors.white12 : _kTextDark.withOpacity(0.06),
          highlightColor:
              isPrimary ? Colors.white10 : _kTextDark.withOpacity(0.03),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: isPrimary
                  ? null
                  : Border.all(color: const Color(0xFFD1D5DB), width: 1),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isPrimary ? Colors.white : _kTextMid,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Footer / Load More ──────────────────────────────────────────────────────────

class _FooterWidget extends StatelessWidget {
  const _FooterWidget({
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
  });

  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(
            color: _kCoralPrimary,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: TextButton(
            onPressed: onLoadMore,
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: _kBorderColor),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Show More',
                  style: TextStyle(
                    color: _kTextDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.expand_more_rounded, color: _kTextDark, size: 18),
              ],
            ),
          ),
        ),
      );
    }

    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Text(
          '— All orders shown —',
          style: TextStyle(
            fontSize: 12,
            color: _kTextLight,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

// ─── Loading View ────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: _kCoralPrimary, strokeWidth: 2.5),
          SizedBox(height: 16),
          Text(
            'Loading your orders…',
            style: TextStyle(
              fontSize: 13,
              color: _kTextLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty View ──────────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    shape: BoxShape.circle,
                    border: Border.all(color: _kBorderColor, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    size: 40,
                    color: _kTextLight,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'No Orders Yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _kTextDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "You haven't placed any orders yet.\nOrder something delicious today!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: _kTextLight,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: onRefresh,
                  style: TextButton.styleFrom(
                    backgroundColor: _kDarkBtn,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Refresh',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
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
    );
  }
}
