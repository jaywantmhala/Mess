// lib/screens/driver_dashboard_tab.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/driver.dart';
import '../services/driver_auth_service.dart';
import '../services/driver_order_service.dart';
import '../services/websocket_service.dart';

class DriverDashboardTab extends StatefulWidget {
  const DriverDashboardTab({super.key});

  @override
  State<DriverDashboardTab> createState() => _DriverDashboardTabState();
}

class _DriverDashboardTabState extends State<DriverDashboardTab> {
  Driver? _driver;
  bool _isOnline = false;
  bool _isLoading = true;
  List<DriverOrder> _activeOrders = [];
  Timer? _gpsTimer;

  // Design Tokens matching reference photo
  static const Color _brandOrange  = Color(0xFFF58220);
  static const Color _gradientEnd  = Color(0xFFE65100);
  static const Color _bgWarm       = Color(0xFFFAF7F2);
  static const Color _white        = Colors.white;
  static const Color _ink          = Color(0xFF1A1A2E);
  static const Color _greySub      = Color(0xFF8A8FA8);
  static const Color _cardBorder   = Color(0xFFEEEEEE);

  double _simulatedProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final driver = await DriverAuthService.instance.getSavedDriver();
    if (driver != null) {
      if (mounted) {
        setState(() {
          _driver = driver;
          _isOnline = driver.isOnline;
          _isLoading = false;
        });
      }
      _fetchActiveOrders();
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchActiveOrders() async {
    final list = await DriverOrderService.instance.fetchOrders();
    final active = list.where((o) => o.status != 'completed' && o.status != 'rejected').toList();
    if (mounted) {
      setState(() {
        _activeOrders = active;
      });
    }
    _manageGpsBroadcast();
  }

  void _manageGpsBroadcast() {
    _gpsTimer?.cancel();
    
    final pickedUpOrders = _activeOrders.where((o) => o.status == 'picked_up').toList();
    if (pickedUpOrders.isEmpty || !_isOnline) {
      _simulatedProgress = 0.0;
      return;
    }

    final activeOrder = pickedUpOrders.first;
    
    _gpsTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!_isOnline || !mounted) {
        timer.cancel();
        return;
      }

      if (_simulatedProgress < 1.0) {
        _simulatedProgress += 0.05;
        if (_simulatedProgress > 1.0) _simulatedProgress = 1.0;
      }

      final double lat = activeOrder.hotelLat + (activeOrder.customerLat - activeOrder.hotelLat) * _simulatedProgress;
      final double lng = activeOrder.hotelLng + (activeOrder.customerLng - activeOrder.hotelLng) * _simulatedProgress;

      WebSocketService.instance.sendLocationUpdate(lat, lng);

      await DriverAuthService.instance.updateStatus(
        isOnline: true,
        latitude: lat,
        longitude: lng,
      );
    });
  }

  Future<void> _toggleOnlineStatus(bool online) async {
    setState(() => _isLoading = true);
    final success = await DriverAuthService.instance.updateStatus(isOnline: online);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (success) {
        _isOnline = online;
      }
    });
    _manageGpsBroadcast();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _driver == null) {
      return const Scaffold(
        backgroundColor: _bgWarm,
        body: Center(
          child: CircularProgressIndicator(color: _brandOrange),
        ),
      );
    }

    final driverName = _driver?.fullName ?? 'Jaywant';
    final vehicleNo  = _driver?.vehicleNumber ?? 'MH-27-BB-1234';

    return Scaffold(
      backgroundColor: _bgWarm,
      body: SafeArea(
        child: RefreshIndicator(
          color: _brandOrange,
          onRefresh: () async {
            await _loadProfile();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top Header Bar ───────────────────────────────────────────
                _buildHeaderBar(),
                const SizedBox(height: 18),

                // ── "YOU ARE ONLINE" Toggle Card Banner ──────────────────────
                _buildOnlineStatusCard(),
                const SizedBox(height: 20),

                // ── Welcome Driver & Rating Row ──────────────────────────────
                _buildDriverWelcomeRow(driverName, vehicleNo),
                const SizedBox(height: 20),

                // ── Delivery Activity Card ───────────────────────────────────
                _buildDeliveryActivityCard(),
                const SizedBox(height: 22),

                // ── Current Assigned Delivery Section ───────────────────────
                if (_activeOrders.isNotEmpty) ...[
                  const Text(
                    'Current Assigned Delivery',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                _buildAssignedDeliverySection(),
                const SizedBox(height: 16),

                // ── Quick Action Buttons Bar (When active order present) ─────
                if (_activeOrders.isNotEmpty) ...[
                  _buildQuickActionsBar(),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 1. Top Header Bar ──────────────────────────────────────────────────────
  Widget _buildHeaderBar() {
    return Row(
      children: [
        // Brand Logo Image
        Image.asset(
          'assets/images/logo.png',
          height: 44,
          fit: BoxFit.contain,
          errorBuilder: (ctx, _, __) => const Text(
            'OMNI VENDOR',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: _brandOrange,
            ),
          ),
        ),

        const Spacer(),

        // Notification Bell Button with Red Dot
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _cardBorder, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.notifications_none_rounded, color: _ink, size: 24),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935),
                  shape: BoxShape.circle,
                  border: Border.all(color: _white, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── 2. "YOU ARE ONLINE" Switch Card Banner ──────────────────────────────────
  Widget _buildOnlineStatusCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isOnline
              ? [_brandOrange, _gradientEnd]
              : [const Color(0xFF78909C), const Color(0xFF455A64)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (_isOnline ? _brandOrange : Colors.grey).withOpacity(0.30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          // Delivery Scooter Badge with Green Active Dot
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _white.withOpacity(0.22),
                  shape: BoxShape.circle,
                  border: Border.all(color: _white.withOpacity(0.35), width: 1.5),
                ),
                child: const Center(
                  child: Icon(Icons.delivery_dining_rounded, color: _white, size: 30),
                ),
              ),
              if (_isOnline)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF28A745),
                      shape: BoxShape.circle,
                      border: Border.all(color: _white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Online Status Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isOnline ? 'YOU ARE ONLINE' : 'YOU ARE OFFLINE',
                  style: const TextStyle(
                    color: _white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _isOnline
                      ? 'Waiting for new orders'
                      : 'Go online to start\nreceiving orders',
                  style: TextStyle(
                    color: _white.withOpacity(0.85),
                    fontSize: 12.5,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Switch Toggle Button
          Switch.adaptive(
            value: _isOnline,
            activeColor: _white,
            activeTrackColor: _white.withOpacity(0.35),
            inactiveThumbColor: Colors.grey.shade300,
            inactiveTrackColor: Colors.white24,
            onChanged: (val) => _toggleOnlineStatus(val),
          ),
        ],
      ),
    );
  }

  // ── 3. Welcome Driver & Rating Row ─────────────────────────────────────────
  Widget _buildDriverWelcomeRow(String driverName, String vehicleNo) {
    final firstName = driverName.trim().split(RegExp(r'\s+')).first;

    return Row(
      children: [
        // Driver Avatar Image
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFFF0E6),
            border: Border.all(color: _white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(34),
            child: Image.asset(
              'assets/images/driver_avatar.png',
              width: 68,
              height: 68,
              fit: BoxFit.cover,
              errorBuilder: (ctx, _, __) => const Icon(
                Icons.person_rounded,
                color: _brandOrange,
                size: 38,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Welcome Text & Vehicle Number
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Welcome, ',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text: '$firstName!',
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Vehicle: $vehicleNo',
                style: const TextStyle(
                  color: _greySub,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Rating Badge Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _cardBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: _brandOrange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.star_rounded, color: _white, size: 15),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '4.8',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                'Rating',
                style: TextStyle(
                  fontSize: 11,
                  color: _greySub,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── 4. Delivery Activity Card ──────────────────────────────────────────────
  Widget _buildDeliveryActivityCard() {
    final activeCount  = _activeOrders.length;
    final pendingCount = _activeOrders.where((o) => o.status == 'accepted_by_driver' || o.status == 'assigned').length;
    final transitCount = _activeOrders.where((o) => o.status == 'picked_up').length;

    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          // Card Title Header & Today Dropdown
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _brandOrange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bar_chart_rounded, color: _white, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Delivery Activity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              const Spacer(),
              // Today Filter Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0), width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Today',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down_rounded, color: _ink, size: 18),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF0EBE5)),
          const SizedBox(height: 16),

          // 3 Stat Columns with Vertical Dividers
          Row(
            children: [
              Expanded(
                child: _buildActivityStatItem(
                  icon: Icons.assignment_outlined,
                  value: '$activeCount',
                  label: 'Active Tasks',
                ),
              ),
              Container(height: 44, width: 1, color: const Color(0xFFF0EBE5)),
              Expanded(
                child: _buildActivityStatItem(
                  icon: Icons.inventory_2_outlined,
                  value: '$pendingCount',
                  label: 'Pickup Pending',
                ),
              ),
              Container(height: 44, width: 1, color: const Color(0xFFF0EBE5)),
              Expanded(
                child: _buildActivityStatItem(
                  icon: Icons.local_shipping_outlined,
                  value: '$transitCount',
                  label: 'In Transit',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0E6),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: _brandOrange, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: _ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            color: _greySub,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── 5. Current Assigned Delivery Section ───────────────────────────────────
  Widget _buildAssignedDeliverySection() {
    if (_activeOrders.isEmpty) {
      return Column(
        children: [
          const SizedBox(height: 10),
          // Exact Scooter Illustration
          Image.asset(
            'assets/images/no_orders_illustration.png',
            height: 185,
            fit: BoxFit.contain,
            errorBuilder: (ctx, _, __) => Container(
              width: 110,
              height: 110,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0E6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.two_wheeler_rounded, size: 55, color: _brandOrange),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          const Text(
            'No orders assigned yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: _ink,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          const Text(
            'We\'ll notify you as soon as\na new order is assigned.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: _greySub,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),

          // Waiting loader ring and label
          SizedBox(
            width: 38,
            height: 38,
            child: CircularProgressIndicator(
              valueColor: const AlwaysStoppedAnimation<Color>(_brandOrange),
              backgroundColor: const Color(0xFFFFF0E6),
              strokeWidth: 3.5,
              strokeCap: StrokeCap.round,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _isOnline ? 'Waiting for orders...' : 'Offline - Go online to get orders',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _isOnline ? _brandOrange : _greySub,
            ),
          ),
          const SizedBox(height: 28),

          // Bottom Tip Card Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFEAD8), width: 1.2),
            ),
            child: Row(
              children: const [
                Icon(Icons.lightbulb_outline_rounded, color: _brandOrange, size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Keep your app open and stay online to get more orders.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF4A4A5A),
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final order = _activeOrders.first;

    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Orange Shopping Bag Icon Badge
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_brandOrange, _gradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.shopping_bag_outlined, color: _white, size: 24),
          ),
          const SizedBox(width: 10),

          // Order Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Order #${order.orderId}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${order.hotelName} to Customer',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _greySub,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: const [
                    Icon(Icons.location_on_rounded, color: _brandOrange, size: 13),
                    SizedBox(width: 3),
                    Text(
                      '2.4 km away',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: _brandOrange,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Assigned Pill Badge & Arrow
          Flexible(
            fit: FlexFit.loose,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0E6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _brandOrange.withOpacity(0.4), width: 1),
                    ),
                    child: Text(
                      order.status.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(
                        color: _brandOrange,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFFBDBDBD), size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 6. Quick Action Buttons Bar ────────────────────────────────────────────
  Widget _buildQuickActionsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6F0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFE5D4), width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(
            icon: Icons.near_me_rounded,
            label: 'Navigate',
            onTap: () {},
          ),
          _buildActionButton(
            icon: Icons.chat_bubble_rounded,
            label: 'Contact',
            onTap: () {},
          ),
          _buildActionButton(
            icon: Icons.phone_in_talk_rounded,
            label: 'Call Support',
            onTap: () {},
          ),
          _buildActionButton(
            icon: Icons.more_horiz_rounded,
            label: 'More',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: _brandOrange, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: _brandOrange,
            ),
          ),
        ],
      ),
    );
  }
}
