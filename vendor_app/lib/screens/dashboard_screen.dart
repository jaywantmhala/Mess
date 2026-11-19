import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../models/hotel.dart';
import '../services/hotel_service.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../theme/app_theme.dart';
import 'add_hotel_screen.dart';

import '../services/vendor_wallet_service.dart';
import '../services/websocket_service.dart';
import 'vendor_wallet_screen.dart';
import 'vendor_notifications_screen.dart';
import '../services/vendor_notification_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  List<Hotel> _hotels = [];
  bool _isLoading = true;
  String _vendorName = 'Vendor';
  int _totalOrdersCount = 0;
  int _todayOrdersCount = 0;
  double _vendorWalletBalance = 0.0;
  double _vendorTodayEarnings = 0.0;
  int _vendorTodayOrders = 0;
  StreamSubscription? _wsSubscription;
  Timer? _webRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadVendorName();
    loadHotels();
    VendorNotificationService.instance.refreshUnreadCount();
    _startAblyListener();
    if (kIsWeb) {
      _webRefreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        _silentSyncWallet();
      });
    }
  }

  void _startAblyListener() {
    _wsSubscription = WebSocketService.instance.messages.listen((msg) {
      final event = msg['event'] as String?;
      final data = msg['data'];

      if (event == 'VENDOR_WALLET_UPDATED') {
        _handleRealtimeOrderCompletion();
      } else if (event == 'ORDER_STATUS_UPDATED') {
        final status = (data is Map ? data['status'] : null)?.toString();
        if (status == 'completed') {
          _handleRealtimeOrderCompletion();
        }
      } else if (event == 'ADMIN_BROADCAST' || event == 'NEW_NOTIFICATION' || event == 'admin_notification') {
        VendorNotificationService.instance.refreshUnreadCount();
      }
    });
  }

  void _handleRealtimeOrderCompletion() {
    if (!mounted) return;
    // Instant zero-delay local state increment (no page reload / no loading spinner)
    setState(() {
      _vendorWalletBalance += 50.0;
      _vendorTodayEarnings += 50.0;
      _vendorTodayOrders += 1;
    });

    // Silent background sync with server to ensure 100% precision
    VendorWalletService.instance.getWalletInfo().then((info) {
      if (mounted) {
        setState(() {
          _vendorWalletBalance = info.balance;
          _vendorTodayEarnings = info.todayEarnings;
          _vendorTodayOrders = info.todayOrdersCount;
        });
      }
    }).catchError((_) {});
  }

  void _silentSyncWallet() {
    VendorWalletService.instance.getWalletInfo().then((info) {
      if (mounted) {
        setState(() {
          _vendorWalletBalance = info.balance;
          _vendorTodayEarnings = info.todayEarnings;
          _vendorTodayOrders = info.todayOrdersCount;
        });
      }
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _webRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadVendorName() async {
    final vendor = await AuthService.instance.getSavedVendor();
    if (vendor != null && mounted) {
      setState(() {
        _vendorName = vendor.fullName;
      });
    }
  }

  Future<void> loadHotels() async {
    setState(() => _isLoading = true);
    try {
      final hotels = await HotelService.instance.getHotels();
      final orderResult = await OrderService.instance.getOrders();
      final allOrders = orderResult.orders;
      final walletInfo = await VendorWalletService.instance.getWalletInfo().catchError(
        (_) => VendorWalletInfo(balance: 0, todayEarnings: 0, todayOrdersCount: 0, dailyBreakdown: []),
      );

      final todayStr = DateTime.now().toIso8601String().split('T').first;
      final todayOrders = allOrders.where((o) => o.createdAt.startsWith(todayStr)).toList();

      if (mounted) {
        setState(() {
          _hotels = hotels;
          _totalOrdersCount = allOrders.length;
          _todayOrdersCount = todayOrders.length;
          _vendorWalletBalance = walletInfo.balance;
          _vendorTodayEarnings = walletInfo.todayEarnings;
          _vendorTodayOrders = walletInfo.todayOrdersCount;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _editHotel(Hotel hotel) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddHotelScreen(hotel: hotel)),
    );
    if (updated == true) loadHotels();
  }

  Future<void> _confirmDelete(Hotel hotel) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.surfaceCard,
        title: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.errorSurface, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Text('Remove Listing?',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink))),
        ]),
        content: Text('Are you sure you want to remove "${hotel.hotelName}"? This cannot be undone.',
            style: AppText.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: AppText.bodyMedium.copyWith(fontWeight: FontWeight.w600))),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _isLoading = true);
      final res = await HotelService.instance.deleteHotel(hotel.id);
      if (!mounted) return;
      if (res.success) { 
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res.message),
          backgroundColor: AppColors.success,
        ));
        loadHotels();
    VendorNotificationService.instance.refreshUnreadCount(); 
      } else { 
        setState(() => _isLoading = false); 
        showDialog(context: context, builder: (_) => AlertDialog(
          title: const Text('Error'),
          content: Text(res.message),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ));
      }
    }
  }

  Future<void> _navigateToAddHotel() async {
    final added = await Navigator.push<bool>(
      context, MaterialPageRoute(builder: (_) => const AddHotelScreen()),
    );
    if (added == true) loadHotels();
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom + 90;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))
          : RefreshIndicator(
              onRefresh: loadHotels,
              color: AppColors.primary,
              backgroundColor: Colors.white,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                    parent: ClampingScrollPhysics()),
                slivers: [
                  // App Bar / Top Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      )
                                    ],
                                    image: const DecorationImage(
                                      image: AssetImage('assets/images/logo.png'),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Hi, $_vendorName 👋',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                      Text(
                                        'Manage your messes easily',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Notification Icon with Badge
                          ValueListenableBuilder<int>(
                            valueListenable: VendorNotificationService.instance.unreadCountNotifier,
                            builder: (context, unreadCount, _) {
                              return InkWell(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const VendorNotificationsScreen(),
                                    ),
                                  );
                                  VendorNotificationService.instance.refreshUnreadCount();
                                },
                                borderRadius: BorderRadius.circular(22),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.04),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          )
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.notifications_none_rounded,
                                        color: AppColors.ink,
                                        size: 24,
                                      ),
                                    ),
                                    if (unreadCount > 0)
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF3B30),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: Colors.white, width: 1.5),
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 18,
                                            minHeight: 18,
                                          ),
                                          child: Text(
                                            unreadCount > 99 ? '99+' : '$unreadCount',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              height: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Stats Gradient Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFF58220), Color(0xFFD36F1B)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF58220).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            // Watermark building icon on right
                            Positioned(
                              right: -10,
                              bottom: -15,
                              child: Icon(
                                Icons.apartment_rounded,
                                size: 130,
                                color: Colors.white.withOpacity(0.12),
                              ),
                            ),
                            // Stats columns
                            Padding(
                              padding: const EdgeInsets.all(22.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text('Total Messes', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 6),
                                        Text('${_hotels.length}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                                        const SizedBox(height: 6),
                                        const Text('Active Listings', style: TextStyle(color: Colors.white70, fontSize: 10)),
                                      ],
                                    ),
                                  ),
                                  Container(width: 1, height: 50, color: Colors.white24),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text('Total Orders', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 6),
                                        Text(_formatNumber(_totalOrdersCount), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                                        const SizedBox(height: 6),
                                        const Text('All Time', style: TextStyle(color: Colors.white70, fontSize: 10)),
                                      ],
                                    ),
                                  ),
                                  Container(width: 1, height: 50, color: Colors.white24),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text("Today's Orders", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 6),
                                        Text(_formatNumber(_todayOrdersCount), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                                        const SizedBox(height: 6),
                                        const Text('Today', style: TextStyle(color: Colors.white70, fontSize: 10)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Vendor Wallet Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const VendorWalletScreen()),
                        ).then((_) => loadHotels()),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: Color(0xFF10B981),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Row(
                                        children: [
                                          const Text(
                                            'Today: ',
                                            style: TextStyle(
                                              color: Color(0xFF64748B),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            '+₹${_vendorTodayEarnings.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color: Color(0xFF10B981),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          Text(
                                            ' (${_vendorTodayOrders} delivered)',
                                            style: const TextStyle(
                                              color: Color(0xFF94A3B8),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '₹${_vendorWalletBalance.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: AppColors.ink,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  children: [
                                    Text(
                                      'View Wallet',
                                      style: TextStyle(
                                        color: AppColors.ink,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(Icons.chevron_right_rounded, color: AppColors.ink, size: 16),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Add New Mess Card (Dashed Border)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: GestureDetector(
                        onTap: _navigateToAddHotel,
                        child: CustomPaint(
                          painter: _DashedBorderPainter(color: AppColors.primary),
                          child: Container(
                            height: 76,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFFF7F0),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 24),
                                ),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Add New Mess',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      Text(
                                        'Create a new mess listing',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Section Title Row
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'My Messes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                'Newest First',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.unfold_more_rounded, size: 16, color: AppColors.ink.withOpacity(0.7)),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),

                  // Hotels List
                  _hotels.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 100, height: 100,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.apartment_rounded, size: 48, color: AppColors.textHint),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text('No Listings Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink)),
                                  const SizedBox(height: 6),
                                  const Text('Add your first mess to get started.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                  const SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed: _navigateToAddHotel,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      minimumSize: const Size(200, 48),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('Add Mess', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  )
                                ],
                              ),
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) => _HotelListItem(
                                hotel: _hotels[i],
                                onEdit: () => _editHotel(_hotels[i]),
                                onDelete: () => _confirmDelete(_hotels[i]),
                              ),
                              childCount: _hotels.length,
                            ),
                          ),
                        ),
                ],
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashed Border Painter
// ─────────────────────────────────────────────────────────────────────────────
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.2,
    this.gap = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(16),
    ));

    final dashPath = Path();
    double distance = 0.0;
    for (PathMetric metric in path.computeMetrics()) {
      while (distance < metric.length) {
        final length = gap;
        if (distance + length < metric.length) {
          dashPath.addPath(
            metric.extractPath(distance, distance + length),
            Offset.zero,
          );
        }
        distance += length * 2.0;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Hotel List Item Widget
// ─────────────────────────────────────────────────────────────────────────────
class _HotelListItem extends StatelessWidget {
  final Hotel hotel;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HotelListItem({
    required this.hotel,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final rating = 4.0 + (hotel.id % 9) * 0.1;
    final viewsCount = hotel.id * 148 + 120;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Hotel Image (Rounded square)
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: hotel.photoUrl != null && hotel.photoUrl!.isNotEmpty
                ? Image.network(hotel.photoUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlaceholder())
                : _buildPlaceholder(),
          ),
          const SizedBox(width: 12),

          // Right: Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        hotel.hotelName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Active Status capsule
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F3EC),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF006837),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF006837),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Popup Actions menu
                    PopupMenuButton<String>(
                      onSelected: (val) {
                        if (val == 'edit') {
                          onEdit();
                        } else if (val == 'delete') {
                          onDelete();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_rounded, size: 18, color: AppColors.ink),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                              SizedBox(width: 8),
                              Text('Remove', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF8E8E93), size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 100),
                    ),
                  ],
                ),
                const SizedBox(height: 2),

                // Location line
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: Color(0xFF8E8E93), size: 12),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        hotel.hotelAddress.isNotEmpty
                            ? hotel.hotelAddress
                            : '${hotel.city ?? 'Goa'}, ${hotel.state ?? 'India'}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF8E8E93),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Rating, Views & Service Type Badge
                Row(
                  children: [
                    // Rating
                    const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 14),
                    const SizedBox(width: 2),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93), fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 6),
                    // Views
                    const Icon(Icons.visibility_outlined, color: Color(0xFF8E8E93), size: 14),
                    const SizedBox(width: 2),
                    Text(
                      '$viewsCount',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93), fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    // Service Type Badge (Dining / Delivery / Both)
                    Flexible(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _buildServiceTypeBadge(hotel.serviceType),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildServiceTypeBadge(String serviceType) {
    final st = serviceType.toUpperCase();
    String label = 'Dining & Delivery';
    IconData icon = Icons.two_wheeler_rounded;
    Color bg = const Color(0xFFECFDF5);
    Color border = const Color(0xFFA7F3D0);
    Color textCol = const Color(0xFF047857);

    if (st == 'DINING') {
      label = 'Dining';
      icon = Icons.restaurant_rounded;
      bg = const Color(0xFFFFF7ED);
      border = const Color(0xFFFFEDD5);
      textCol = const Color(0xFFC2410C);
    } else if (st == 'DELIVERY') {
      label = 'Delivery';
      icon = Icons.delivery_dining_rounded;
      bg = const Color(0xFFEFF6FF);
      border = const Color(0xFFBFDBFE);
      textCol = const Color(0xFF1D4ED8);
    } else {
      label = 'Dining & Delivery';
      icon = Icons.two_wheeler_rounded;
      bg = const Color(0xFFECFDF5);
      border = const Color(0xFFA7F3D0);
      textCol = const Color(0xFF047857);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: textCol),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                color: textCol,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE5E5EA), Color(0xFFD1D1D6)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.apartment_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}
