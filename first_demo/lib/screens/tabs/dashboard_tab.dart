// lib/screens/tabs/dashboard_tab.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/hotel.dart';
import '../../services/hotel_service.dart';
import '../hotel_menu_screen.dart';
import '../../models/address_data.dart';
import '../../services/address_service.dart';
import '../select_address_screen.dart';
import '../../services/wallet_service.dart';
import '../../services/order_service.dart';
import '../../models/order.dart';
import '../../services/ably_service.dart';
import 'dart:async';
import '../order_status_screen.dart';
import '../customer_subscription_screen.dart';
import '../hotels_near_you_screen.dart';
import '../saved_addresses_screen.dart';
import '../customer_notifications_screen.dart';
import '../../services/notification_service.dart';

class HotelModel {
  final String id;
  final String name;
  final double rating;
  final int reviews;
  final double distanceKm;
  final bool isOpen;
  final String tag;
  final String deliveryTime;
  final String costForTwo;
  final String address;
  final String phone;
  final IconData icon;
  final List<Color> gradient;
  final Alignment mapAlignment;
  final Hotel rawHotel;

  HotelModel({
    required this.id,
    required this.name,
    required this.rating,
    required this.reviews,
    required this.distanceKm,
    required this.isOpen,
    required this.tag,
    required this.deliveryTime,
    required this.costForTwo,
    required this.address,
    required this.phone,
    required this.icon,
    required this.gradient,
    required this.mapAlignment,
    required this.rawHotel,
  });

  String get distanceLabel => '${distanceKm.toStringAsFixed(1)} km away';
}

class HotelLocatorDashboard extends StatefulWidget {
  const HotelLocatorDashboard({super.key});

  @override
  State<HotelLocatorDashboard> createState() => _HotelLocatorDashboardState();
}

class _HotelLocatorDashboardState extends State<HotelLocatorDashboard>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  Position? _userPosition;
  List<Hotel> _backendHotels = [];
  bool _hasActiveSubscription = false;
  bool _isLocationServiceable = true;
  bool _isSubscribedPlanServiceableAtLocation = true;
  bool _isLoading = true;
  String _errorMessage = '';

  AddressData? _savedAddress;
  double? _walletBalance;
  OrderHistoryItem? _activeOrder;
  StreamSubscription? _wsSubscription;

  late ScrollController _scrollController;
  late AnimationController _radarController;

  // Design Tokens matching reference photo 100%
  static const Color _brandOrange = Color(0xFFF58220);
  static const Color _gradientEnd = Color(0xFFE65100);
  static const Color _bgWarm = Color(0xFFF6F8FA);
  static const Color _white = Colors.white;
  static const Color _ink = Color(0xFF1A1A2E);
  static const Color _greySub = Color(0xFF6B7280);
  static const Color _cardBorder = Color(0xFFF3F4F6);
  static const Color _darkGreen = Color(0xFF0F3A22);

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _loadAddressAndHotels();
    NotificationService.instance.refreshUnreadCount();
    _fetchActiveOrder();
    _fetchWalletBalance();

    WalletService.instance.balanceNotifier.addListener(_onWalletBalanceChanged);
    _walletBalance = WalletService.instance.balanceNotifier.value;

    AblyService.instance.connect();
    _wsSubscription = AblyService.instance.messages.listen((msg) {
      if (msg['type'] == 'order_status_update') {
        _fetchActiveOrder();
      }
    });
  }

  void _onWalletBalanceChanged() {
    if (mounted)
      setState(
        () => _walletBalance = WalletService.instance.balanceNotifier.value,
      );
  }

  Future<void> _fetchWalletBalance() async {
    try {
      final wallet = await WalletService.instance.getBalance();
      if (mounted) {
        setState(() => _walletBalance = wallet.balance);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    WalletService.instance.balanceNotifier.removeListener(
      _onWalletBalanceChanged,
    );
    _wsSubscription?.cancel();
    _radarController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAddressAndHotels() async {
    try {
      final addr = await AddressService.instance.getAddress();
      if (mounted) setState(() => _savedAddress = addr);
    } catch (_) {}
    await _fetchNearbyHotels();
  }

  Future<void> _fetchActiveOrder() async {
    try {
      final orders = await OrderService.instance.getHistory(limit: 5);
      final active = orders.firstWhere(
        (o) =>
            o.status != 'completed' &&
            o.status != 'rejected' &&
            o.status != 'cancelled',
        orElse: () => OrderHistoryItem(
          orderId: 0,
          hotelName: '',
          status: '',
          grandTotal: 0.0,
          walletDeducted: 0.0,
          itemCount: 0,
          createdAt: DateTime.now(),
        ),
      );
      if (mounted && active.orderId != 0) {
        setState(() => _activeOrder = active);
      } else if (mounted) {
        setState(() => _activeOrder = null);
      }
    } catch (_) {}
  }

  Future<void> _fetchNearbyHotels() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      // Use saved address coordinates first, GPS second, 0,0 last (backend fallback)
      double lat = 0.0, lng = 0.0;
      if (_savedAddress != null && _savedAddress!.latitude != 0.0) {
        lat = _savedAddress!.latitude;
        lng = _savedAddress!.longitude;
        _userPosition = Position(
          latitude: lat,
          longitude: lng,
          timestamp: DateTime.now(),
          accuracy: 0.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
      } else {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always) {
            final position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            );
            _userPosition = position;
            lat = position.latitude;
            lng = position.longitude;
          }
        }
      }

      debugPrint(
        '📍 [Dashboard] Fetching plans with lat=$lat, lng=$lng, addr=${_savedAddress?.fullAddress}',
      );

      final res = await HotelService.instance.getNearbyHotels(
        latitude: lat,
        longitude: lng,
      );
      final planRes = await HotelService.instance.getServiceablePlans(
        latitude: lat,
        longitude: lng,
        pincode: _savedAddress?.pincode,
        address: _savedAddress?.fullAddress,
      );
      final currentSub = await HotelService.instance.getCurrentSubscription(
        latitude: lat,
        longitude: lng,
      );

      // Single source of truth: currentSub from /api/customer/subscription/current
      // res.hasActiveSubscription is used ONLY for hotels display, not for plan banner
      final sub = currentSub?['subscription'] as Map<String, dynamic>?;
      final subStatus = sub?['status'] as String? ?? '';
      final subEnd = sub?['end_date'] as String? ?? '';
      final subRemaining = (sub?['remaining_deliveries'] ?? 0) as int;

      bool hasSub =
          subStatus == 'ACTIVE' &&
          subRemaining > 0 &&
          subEnd.isNotEmpty &&
          DateTime.tryParse(
                subEnd,
              )?.isAfter(DateTime.now().subtract(const Duration(days: 1))) ==
              true;

      bool locationServiceable =
          planRes.serviceable || planRes.plans.isNotEmpty;
      bool planServiceableAtLocation = true;

      if (hasSub) {
        if (currentSub != null &&
            currentSub['is_serviceable_at_address'] == false) {
          planServiceableAtLocation = false;
        }
      }

      debugPrint(
        '📍 [Dashboard] Result: hasSub=$hasSub, locationServiceable=$locationServiceable, planServiceable=$planServiceableAtLocation',
      );

      if (mounted) {
        setState(() {
          _backendHotels = res.hotels
              .where((h) => (h.distance ?? 0) <= 5.0)
              .toList();
          _hasActiveSubscription = hasSub;
          _isLocationServiceable = locationServiceable;
          _isSubscribedPlanServiceableAtLocation = planServiceableAtLocation;
          _errorMessage = res.message ?? '';
          _isLoading = false;
        });
        _fetchWalletBalance();
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
    }
  }

  List<HotelModel> get _hotels {
    final userLat = _userPosition?.latitude ?? 18.5204;
    final userLng = _userPosition?.longitude ?? 73.8567;

    if (_backendHotels.isEmpty) {
      return [];
    }

    return _backendHotels.map((h) {
      final dyKm = (h.latitude - userLat) * 111.0;
      final dxKm = (h.longitude - userLng) * 105.0;
      final alignX = (dxKm / 5.0 * 0.72).clamp(-0.85, 0.85);
      final alignY = (-(dyKm / 5.0) * 0.72).clamp(-0.85, 0.85);
      return HotelModel(
        id: h.id.toString(),
        name: h.hotelName,
        rating: 4.5,
        reviews: 120,
        distanceKm: h.distance ?? 0.0,
        isOpen: true,
        tag: 'Nearby',
        deliveryTime: '20-25 mins',
        costForTwo: '₹₹',
        address: h.hotelAddress,
        phone: h.mobileNumber,
        icon: Icons.storefront_rounded,
        gradient: const [_brandOrange, _gradientEnd],
        mapAlignment: Alignment(alignX, alignY),
        rawHotel: h,
      );
    }).toList();
  }

  Future<void> _openAddressPicker() async {
    final result = await Navigator.push<AddressData>(
      context,
      MaterialPageRoute(builder: (_) => const SavedAddressesScreen()),
    );
    if (result != null) {
      if (mounted) {
        setState(() => _savedAddress = result);
        await _fetchNearbyHotels();
      }
    } else {
      final latest = await AddressService.instance.getAddress();
      if (mounted) {
        setState(() => _savedAddress = latest);
        await _fetchNearbyHotels();
      }
    }
  }

  @override
  Widget _buildNotificationBell() {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CustomerNotificationsScreen(),
          ),
        );
        NotificationService.instance.refreshUnreadCount();
      },
      child: ValueListenableBuilder<int>(
        valueListenable: NotificationService.instance.unreadCountNotifier,
        builder: (context, unreadCount, _) {
          return Stack(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _white,
                  shape: BoxShape.circle,
                  border: Border.all(color: _cardBorder, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: _ink,
                  size: 21,
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final mq = MediaQuery.of(context);
    final isWide = mq.size.width > 600;
    final addressText = _savedAddress?.fullAddress.isNotEmpty == true
        ? _savedAddress!.fullAddress
        : 'Karvenagar, Pune, Maharashtra';

    return Scaffold(
      backgroundColor: _bgWarm,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWide ? 540 : double.infinity,
            ),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 1. Top Header: Location, Wallet & Notification Bell ───────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left: Circular Logo Avatar & Address Column
                      Expanded(
                        child: InkWell(
                          onTap: _openAddressPicker,
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _white,
                                  border: Border.all(
                                    color: const Color(0xFF10B981),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    'H',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: _brandOrange,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: const [
                                        Flexible(
                                          child: Text(
                                            'Hungrily Foods',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w900,
                                              color: _ink,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: _ink,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on_rounded,
                                          color: _brandOrange,
                                          size: 13,
                                        ),
                                        const SizedBox(width: 3),
                                        Expanded(
                                          child: Text(
                                            addressText,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: _greySub,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Right: Wallet Balance Pill & Bell Icon
                      Row(
                        children: [
                          // Wallet Pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFFFEDD5),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: _brandOrange,
                                  size: 16,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _walletBalance != null
                                      ? '₹${_walletBalance!.toStringAsFixed(1)}'
                                      : '...',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w900,
                                    color: _ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Notification Bell
                          Stack(
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const CustomerNotificationsScreen(),
                                    ),
                                  );
                                  NotificationService.instance
                                      .refreshUnreadCount();
                                },
                                child: Container(
                                  /*
                            children: [
                              Container(
                        */
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: _white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _cardBorder,
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.notifications_outlined,
                                    color: _ink,
                                    size: 21,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── 2. Promotional Hero Banner ("Hunger Delivered!") ──────────
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AspectRatio(
                      aspectRatio: 1024 / 512,
                      child: Image.asset(
                        'assets/images/hungrily_banner.png',
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Container(
                          height: 175,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_brandOrange, _gradientEnd],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Center(
                            child: Text(
                              'HUNGER DELIVERED!',
                              style: TextStyle(
                                color: _white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── 3. Interactive Radar Map Card ─────────────────────────────
                  Container(
                    height: 175,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE8E3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _cardBorder, width: 1.2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        // Custom Light Street Map Painter
                        Positioned.fill(
                          child: CustomPaint(painter: _LightMapPainter()),
                        ),

                        // Animated Radar Circle Sweep
                        Positioned.fill(
                          child: Center(
                            child: Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(
                                  0xFF10B981,
                                ).withOpacity(0.12),
                                border: Border.all(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withOpacity(0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF10B981),
                                    border: Border.all(
                                      color: _white,
                                      width: 2.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Live Hotel Pins on Map
                        for (final hotel in _hotels)
                          Align(
                            alignment: hotel.mapAlignment,
                            child: GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      HotelMenuScreen(hotel: hotel.rawHotel),
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _brandOrange,
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.12),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: _brandOrange,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.restaurant_rounded,
                                        color: _white,
                                        size: 10,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      hotel.name,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w900,
                                        color: _ink,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // Top Center Floating Pill Tag: Showing hotels within 2 km
                        Positioned(
                          top: 10,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.my_location_rounded,
                                    size: 14,
                                    color: Color(0xFF10B981),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Showing ${_hotels.length} hotels within 5 km',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: _ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Right Side Map Control Buttons (Target & Refresh)
                        Positioned(
                          right: 10,
                          top: 10,
                          child: Column(
                            children: [
                              _buildMapControlBtn(
                                Icons.my_location_rounded,
                                onTap: _fetchNearbyHotels,
                              ),
                              const SizedBox(height: 8),
                              _buildMapControlBtn(
                                Icons.refresh_rounded,
                                onTap: _fetchNearbyHotels,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── 4. Subscription Promo Banner (Dynamic State Render) ────────
                  _buildSubscriptionPanel(),
                  // ── 5. Live Order Status Tracker Card (ONLY shown if user has active order) ──
                  if (_activeOrder != null) ...[
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                OrderStatusScreen(initialOrder: _activeOrder!),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF072C1C),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: const Color(0xFF10B981).withOpacity(0.3),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Left Circular Food Bag Graphic with Outer Mint Ring
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFFFFBF5),
                                border: Border.all(
                                  color: const Color(0xFFD1FAE5),
                                  width: 2.2,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.shopping_bag_rounded,
                                  color: _brandOrange,
                                  size: 26,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Center Info Column (Hotel Name, Order Tag Capsule, Time)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Hotel Name
                                  Text(
                                    _activeOrder!.hotelName.isNotEmpty
                                        ? _activeOrder!.hotelName
                                        : 'Restaurant',
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w900,
                                      color: _white,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 5),

                                  // Order Tag Capsule (Order #85 | RECEIVED)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 3.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F472F),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(
                                          0xFF10B981,
                                        ).withOpacity(0.4),
                                        width: 1,
                                      ),
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.confirmation_number_outlined,
                                            color: Color(0xFF10B981),
                                            size: 14,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            'Order #${_activeOrder!.orderId}',
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w800,
                                              color: _white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 5),

                                  // Time Row (Clock Icon + Timestamp)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time_rounded,
                                        color: Color(0xFFA0A5BA),
                                        size: 14,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Today, ${_activeOrder!.createdAt.hour.toString().padLeft(2, '0')}:${_activeOrder!.createdAt.minute.toString().padLeft(2, '0')}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFFA0A5BA),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Vertical Divider Line
                            Container(
                              height: 48,
                              width: 1,
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              color: Colors.white.withOpacity(0.12),
                            ),

                            // Right Column: Received Capsule Badge & View Details Link
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Solid Green Gradient Pill Badge (✓ RECEIVED)
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF00B074),
                                            Color(0xFF10B981),
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF10B981,
                                            ).withOpacity(0.3),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(
                                              color: _white,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.check_rounded,
                                              color: Color(0xFF00B074),
                                              size: 10,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            _activeOrder!.status
                                                        .toLowerCase() ==
                                                    'created_order'
                                                ? 'PLACED'
                                                : _activeOrder!.status
                                                      .toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                              color: _white,
                                              letterSpacing: 0.6,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // View Details Link + Right Chevron Circle Button
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'View Details',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w800,
                                            color: _white,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF0E4A32),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.chevron_right_rounded,
                                            color: _white,
                                            size: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // ── 6. "Explore More" 4-Card Feature Grid Matrix ────────────────
                  const Text(
                    'Explore More',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      // 1. Browse Hotels
                      Expanded(
                        child: _buildExploreCard(
                          iconWidget: const Text(
                            '🥗',
                            style: TextStyle(fontSize: 22),
                          ),
                          iconBg: const Color(0xFFFFF0E6),
                          title: 'Browse Mess',
                          subtitle: 'Explore nearby\nmess',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HotelsNearYouScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 2. Daily Menus
                      Expanded(
                        child: _buildExploreCard(
                          iconWidget: const Text(
                            '📅',
                            style: TextStyle(fontSize: 22),
                          ),
                          iconBg: const Color(0xFFFFF0E6),
                          title: 'Daily Menus',
                          subtitle: "See today's menu\n& offers",
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HotelsNearYouScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 3. Top Rated
                      Expanded(
                        child: _buildExploreCard(
                          iconWidget: const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFF59E0B),
                            size: 24,
                          ),
                          iconBg: const Color(0xFFFEF3C7),
                          title: 'Top Rated',
                          subtitle: 'Try top rated\nmess',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HotelsNearYouScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 4. Offers
                      Expanded(
                        child: _buildExploreCard(
                          iconWidget: const Text(
                            '🎟️',
                            style: TextStyle(fontSize: 22),
                          ),
                          iconBg: const Color(0xFFFEE2E2),
                          title: 'Offers',
                          subtitle: 'Exciting deals\nfor you',
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapControlBtn(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: _ink),
      ),
    );
  }

  Widget _buildSubscriptionPanel() {
    // Case 1: Active Subscription & Valid Location -> Plan Activated! (See Nearby Hotels)
    if (_hasActiveSubscription && _isSubscribedPlanServiceableAtLocation) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFA7F3D0), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: _white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Plan Activated!',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F5B33),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'You can now see and order from top mess.',
                    style: TextStyle(
                      fontSize: 12,
                      color: _greySub,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HotelsNearYouScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: _brandOrange,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _brandOrange.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: const [
                    Text(
                      'View Mess',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: _white,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, color: _white, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Case 2: Active Subscription BUT Plan is NOT Serviceable at Current Location
    if (_hasActiveSubscription && !_isSubscribedPlanServiceableAtLocation) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFD97706),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Plan Not Available Here',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF92400E),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Your active plan is not available at this current location.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: _greySub,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SelectAddressScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD97706).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: const [
                    Text(
                      'Change Location',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: _white,
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(Icons.chevron_right_rounded, color: _white, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Case 3: NOT Subscribed AND NO Plans Available at Current Location
    if (!_hasActiveSubscription && !_isLocationServiceable) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.location_off_rounded,
                color: Color(0xFF4B5563),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'No plan available here',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Meal plans are not serviceable in this area yet.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: _greySub,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SelectAddressScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4B5563),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: const [
                    Text(
                      'Check Area',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: _white,
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(Icons.chevron_right_rounded, color: _white, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Case 4: NOT Subscribed AND Plans ARE Available at Current Location -> Subscribe to Unlock Hotels
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFEDD5), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0E6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.lock_rounded,
              color: _brandOrange,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Subscribe to Unlock Mess',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Choose a meal plan for your area',
                  style: TextStyle(
                    fontSize: 12,
                    color: _greySub,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CustomerSubscriptionScreen(),
                ),
              );
              if (mounted) {
                await WalletService.instance.getBalance();
                await _fetchWalletBalance();
                await _fetchNearbyHotels();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: _brandOrange,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _brandOrange.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: const [
                  Text(
                    'View Plan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: _white,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, color: _white, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreCard({
    required Widget iconWidget,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 135,
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _cardBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Center(child: iconWidget),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9.5,
                color: _greySub,
                fontWeight: FontWeight.w500,
                height: 1.15,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Light Map Painter for Radar Map Card
// ─────────────────────────────────────────────────────────────────────────────

class _LightMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFECEAE6);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;

    final roadPaintThin = Paint()
      ..color = Colors.white
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;

    final greenAreaPaint = Paint()
      ..color = const Color(0xFFD1E7DD).withOpacity(0.7);

    // Green park shapes
    final park1 = Path()
      ..moveTo(size.width * 0.05, size.height * 0.3)
      ..lineTo(size.width * 0.25, size.height * 0.1)
      ..lineTo(size.width * 0.3, size.height * 0.45)
      ..close();
    canvas.drawPath(park1, greenAreaPaint);

    // Diagonal roads
    canvas.drawLine(
      Offset(0, size.height * 0.2),
      Offset(size.width, size.height * 0.6),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.1, size.height),
      Offset(size.width * 0.8, 0),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.3, 0),
      Offset(size.width * 0.9, size.height),
      roadPaintThin,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
