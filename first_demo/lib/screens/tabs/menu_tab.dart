import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../order_status_screen.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _kBg        = Color(0xFFF4F5F7);
const _kWhite     = Colors.white;
const _kDark      = Color(0xFF1A1A2E);
const _kMidText   = Color(0xFF6B7280);
const _kLightText = Color(0xFF9CA3AF);
const _kBorder    = Color(0xFFE9EAEC);
const _kShadow    = Color(0x0D000000);
const _kGreen     = Color(0xFF10B981);
const _kRed       = Color(0xFFEF4444);
const _kAmber     = Color(0xFFF59E0B);
const _kBlue      = Color(0xFF3B82F6);
const _kOrange    = Color(0xFFE8724A);
const _kDarkBtn   = Color(0xFF1A1A2E);

class MenuTab extends StatefulWidget {
  const MenuTab({super.key});

  @override
  State<MenuTab> createState() => MenuTabState();
}

class MenuTabState extends State<MenuTab> {
  final List<OrderHistoryItem> _orders = [];
  int _currentPage = 1;
  static const int _limit = 10;
  bool _isFirstLoad = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    fetchOrders(isRefresh: true);
  }

  Future<void> fetchOrders({bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 1;
      _hasMore = true;
      _orders.clear();
      if (mounted) setState(() => _isFirstLoad = true);
    } else {
      if (!_hasMore || _isLoadingMore) return;
      if (mounted) setState(() => _isLoadingMore = true);
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
      }
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  static String statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'delivered':          return 'Delivered';
      case 'cancelled':
      case 'rejected':
      case 'rejected_by_driver': return 'Cancelled';
      case 'created_order':      return 'Order Placed';
      case 'accepted_by_driver': return 'Driver Accepted';
      case 'picked_up':          return 'Out for Delivery';
      case 'preparing':          return 'Preparing';
      case 'ready':              return 'Ready';
      default:                   return 'In Progress';
    }
  }

  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'delivered':          return _kGreen;
      case 'cancelled':
      case 'rejected':
      case 'rejected_by_driver': return _kRed;
      default:                   return _kBlue;
    }
  }

  /// e.g.  "Jul 08, 2026 • 10:30 AM"
  static String formatDateTime(DateTime dt) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    final m   = months[dt.month - 1];
    final d   = dt.day.toString().padLeft(2, '0');
    final y   = dt.year;
    final h   = dt.hour > 12
        ? dt.hour - 12
        : (dt.hour == 0 ? 12 : dt.hour);
    final min = dt.minute.toString().padLeft(2, '0');
    final p   = dt.hour >= 12 ? 'PM' : 'AM';
    return '$m $d, $y • ${h.toString().padLeft(2,'0')}:$min $p';
  }

  /// Short date only: "Jul 08, 2026"
  static String formatDate(DateTime dt) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day.toString().padLeft(2,'0')}, ${dt.year}';
  }

  static Widget? tiffinBadge(OrderHistoryItem order) {
    final delivered = order.status.toLowerCase() == 'completed' ||
        order.status.toLowerCase() == 'delivered';
    if (!delivered) return null;
    if (order.tiffinReceivedToHotel == 'received') {
      return const _Chip(label: '✓ Tiffin Received', color: _kGreen);
    }
    return const _Chip(label: '⏳ Tiffin Pending', color: _kAmber);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Page header ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Order History',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: _kDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => fetchOrders(isRefresh: true),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _kWhite,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _kBorder),
                        boxShadow: const [
                          BoxShadow(color: _kShadow, blurRadius: 6, offset: Offset(0, 1)),
                        ],
                      ),
                      child: const Icon(Icons.refresh_rounded, color: _kDark, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            // ── List ────────────────────────────────────────────────────────
            Expanded(
              child: _isFirstLoad
                  ? const Center(
                      child: CircularProgressIndicator(color: _kOrange, strokeWidth: 2.5),
                    )
                  : RefreshIndicator(
                      color: _kOrange,
                      backgroundColor: _kWhite,
                      strokeWidth: 2.5,
                      onRefresh: () => fetchOrders(isRefresh: true),
                      child: _orders.isEmpty
                          ? _EmptyState(onRefresh: () => fetchOrders(isRefresh: true))
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(
                                parent: AlwaysScrollableScrollPhysics(),
                              ),
                              padding: EdgeInsets.fromLTRB(16, 4, 16, 80 + bottomPad),
                              itemCount: _orders.length + 1,
                              itemBuilder: (context, index) {
                                if (index == _orders.length) {
                                  return _Footer(
                                    hasMore: _hasMore,
                                    isLoadingMore: _isLoadingMore,
                                    onLoadMore: fetchOrders,
                                  );
                                }
                                final order = _orders[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _OrderCard(
                                    order: order,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            OrderStatusScreen(initialOrder: order),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Order Card ───────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final OrderHistoryItem order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sColor   = MenuTabState.statusColor(order.status);
    final sLabel   = MenuTabState.statusLabel(order.status);
    final dateStr  = MenuTabState.formatDate(order.createdAt);
    final tiffinW  = MenuTabState.tiffinBadge(order);
    final totalStr =
        '${order.itemCount} ${order.itemCount == 1 ? 'item' : 'items'}  ·  Total ₹${order.grandTotal.toStringAsFixed(2)}';

    return Container(
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder, width: 1),
        boxShadow: const [
          BoxShadow(color: _kShadow, blurRadius: 10, offset: Offset(0, 2)),
          BoxShadow(color: Color(0x05000000), blurRadius: 1),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          splashColor: _kDark.withOpacity(0.04),
          highlightColor: _kDark.withOpacity(0.02),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header: Order ID + Meal Badge | Date ─────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Order #${order.orderId}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _kDark,
                          ),
                        ),
                        const SizedBox(width: 8),
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
                      ],
                    ),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _kLightText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                Container(height: 1, color: _kBorder),
                const SizedBox(height: 10),

                // ── Hotel row: avatar + name | View Details ──────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _HotelAvatar(name: order.hotelName),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        order.hotelName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _kDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onTap,
                      child: const Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _kMidText,
                          decoration: TextDecoration.underline,
                          decorationColor: _kLightText,
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Tiffin badge ─────────────────────────────────────────────
                if (tiffinW != null) ...[
                  const SizedBox(height: 8),
                  tiffinW,
                ],

                const SizedBox(height: 12),

                // ── Vertical progress (inside card) ──────────────────────────
                _VerticalOrderProgress(order: order, finalLabel: sLabel, finalColor: sColor),

                const SizedBox(height: 12),
                Container(height: 1, color: _kBorder),
                const SizedBox(height: 10),

                // ── Footer: summary | Reorder ────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        totalStr,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: _kMidText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _ReorderBtn(onTap: onTap),
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

// ─── Vertical Order Progress (inside card) ────────────────────────────────────
/// Shows only 2 points:
///   ● Order Placed    Jul 08, 2026 • 10:30 AM
///   │  (vertical line)
///   ● Delivered / Cancelled / In Progress
///
/// If status is still in-progress the bottom node is open/dashed.

class _VerticalOrderProgress extends StatelessWidget {
  const _VerticalOrderProgress({
    required this.order,
    required this.finalLabel,
    required this.finalColor,
  });

  final OrderHistoryItem order;
  final String finalLabel;
  final Color finalColor;

  bool get _isTerminal {
    final s = order.status.toLowerCase();
    return s == 'completed' ||
        s == 'delivered' ||
        s == 'cancelled' ||
        s == 'rejected' ||
        s == 'rejected_by_driver';
  }

  @override
  Widget build(BuildContext context) {
    final placedTime = MenuTabState.formatDateTime(order.createdAt);
    final terminal   = _isTerminal;

    // Dot sizes
    const double dotR  = 8.0;   // dot diameter
    const double lineW = 2.0;   // connector line width

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Left: dots + connector line ───────────────────────────────────────
        SizedBox(
          width: dotR,
          child: Column(
            children: [
              // Top dot — always green (placed)
              Container(
                width: dotR,
                height: dotR,
                decoration: const BoxDecoration(
                  color: _kGreen,
                  shape: BoxShape.circle,
                ),
              ),
              // Connector line
              Container(
                width: lineW,
                height: 28,
                margin: EdgeInsets.symmetric(horizontal: (dotR - lineW) / 2),
                decoration: BoxDecoration(
                  color: terminal
                      ? finalColor.withOpacity(0.4)
                      : const Color(0xFFD1D5DB),
                ),
              ),
              // Bottom dot
              Container(
                width: dotR,
                height: dotR,
                decoration: BoxDecoration(
                  color: terminal ? finalColor : Colors.transparent,
                  shape: BoxShape.circle,
                  border: terminal
                      ? null
                      : Border.all(color: const Color(0xFFD1D5DB), width: 2),
                ),
                child: terminal
                    ? null
                    : null,
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        // ── Right: labels + times ─────────────────────────────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top: Order Placed ──────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Order Placed',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: _kGreen,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      placedTime,
                      style: const TextStyle(
                        fontSize: 10,
                        color: _kLightText,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28 + 2), // matches the connector height

              // ── Bottom: final status ───────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    finalLabel,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: terminal ? finalColor : _kLightText,
                    ),
                  ),
                  if (!terminal)
                    const Text(
                      'In progress…',
                      style: TextStyle(
                        fontSize: 10,
                        color: _kLightText,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Reorder Button ───────────────────────────────────────────────────────────

class _ReorderBtn extends StatelessWidget {
  const _ReorderBtn({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Material(
        color: _kDarkBtn,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          splashColor: Colors.white12,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                'Reorder',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _kWhite,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Chip (tiffin badge) ──────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.22), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

// ─── Hotel Avatar ─────────────────────────────────────────────────────────────

class _HotelAvatar extends StatelessWidget {
  const _HotelAvatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final hue = (name.codeUnits.fold(0, (a, b) => a + b) % 360).toDouble();
    final bg  = HSLColor.fromAHSL(1.0, hue, 0.55, 0.91).toColor();
    final fg  = HSLColor.fromAHSL(1.0, hue, 0.60, 0.30).toColor();

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder, width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }
}

// ─── Footer ───────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer({
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
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator(color: _kOrange, strokeWidth: 2.5)),
      );
    }
    if (hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: TextButton(
            onPressed: onLoadMore,
            style: TextButton.styleFrom(
              backgroundColor: _kWhite,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: _kBorder),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Load More',
                    style: TextStyle(
                        color: _kDark, fontWeight: FontWeight.w700, fontSize: 12.5)),
                SizedBox(width: 4),
                Icon(Icons.expand_more_rounded, color: _kDark, size: 16),
              ],
            ),
          ),
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          '— All orders shown —',
          style: TextStyle(
              fontSize: 11.5, color: _kLightText,
              fontWeight: FontWeight.w500, letterSpacing: 0.3),
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
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 86, height: 86,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                  border: Border.all(color: _kBorder, width: 1.5),
                ),
                child: const Icon(Icons.receipt_long_rounded, size: 38, color: _kLightText),
              ),
              const SizedBox(height: 18),
              const Text('No Orders Yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _kDark)),
              const SizedBox(height: 7),
              const Text('Your order history will appear here.',
                  style: TextStyle(fontSize: 13, color: _kLightText)),
              const SizedBox(height: 22),
              TextButton(
                onPressed: onRefresh,
                style: TextButton.styleFrom(
                  backgroundColor: _kDarkBtn,
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, color: _kWhite, size: 15),
                    SizedBox(width: 6),
                    Text('Refresh',
                        style: TextStyle(
                            color: _kWhite, fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
