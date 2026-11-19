// lib/screens/home_shell.dart
import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'orders_screen.dart';
import 'tabs/menu_tab.dart';
import 'tabs/profile_tab.dart';
import '../services/websocket_service.dart';
import '../services/auth_service.dart';
import '../services/hotel_service.dart';
import '../services/order_service.dart';
import '../services/fcm_service.dart';
import '../services/vendor_notification_service.dart';
import 'vendor_notifications_screen.dart';
import 'add_hotel_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late List<Widget> _tabs;
  StreamSubscription? _wsSubscription;

  final GlobalKey<DashboardScreenState> _dashboardKey = GlobalKey<DashboardScreenState>();

  // Per-tab animation controllers for icon bounce
  late List<AnimationController> _iconControllers;
  late List<Animation<double>> _iconScales;

  static const _navItems = [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded, label: 'Orders'),
    _NavItem(icon: Icons.restaurant_menu_outlined, activeIcon: Icons.restaurant_menu_rounded, label: 'Menu'),
    _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _tabs = [
      DashboardScreen(key: _dashboardKey),
      const OrdersScreen(),
      const MenuTab(),
      const ProfileTab(),
    ];

    _iconControllers = List.generate(
      _navItems.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 350),
      ),
    );
    _iconScales = _iconControllers.map((ctrl) {
      return TweenSequence<double>([
        TweenSequenceItem(
            tween: Tween(begin: 1.0, end: 1.28)
                .chain(CurveTween(curve: Curves.easeOut)),
            weight: 40),
        TweenSequenceItem(
            tween: Tween(begin: 1.28, end: 1.0)
                .chain(CurveTween(curve: Curves.elasticOut)),
            weight: 60),
      ]).animate(ctrl);
    }).toList();

    // Trigger initial animation for tab 0
    _iconControllers[0].forward(from: 0);

    // Start WebSocket listener FIRST so no incoming broadcast events are missed
    _startWSListener();
    _initWithVendor();
    VendorNotificationService.instance.startPeriodicSync();
  }

  int _currentVendorId = 0; // 0 = not loaded yet
  List<int> _myHotelIds = [];

  Future<void> _initWithVendor() async {
    // Load from SharedPreferences (fast, cached)
    final v = await AuthService.instance.getSavedVendor();
    _currentVendorId = v?.id ?? 0;
    debugPrint('🔑 [HomeShell] Loaded vendor ID: $_currentVendorId');

    // Share with WebSocketService so sound alert also uses correct ID
    WebSocketService.instance.cachedVendorId = _currentVendorId;
    if (_currentVendorId > 0) {
      await WebSocketService.instance.subscribeToVendor(_currentVendorId);
    }

    try {
      final hotels = await HotelService.instance.getHotels();
      _myHotelIds = hotels.map((h) => h.id).toList();
      await WebSocketService.instance.subscribeToHotels(_myHotelIds);
    } catch (e) {
      debugPrint('🔑 [HomeShell] Error fetching hotels: $e');
    }

    // Connect to Ably
    await WebSocketService.instance.connect(role: 'vendor');
    FcmService.instance.registerToken('vendor');
  }

  void _startWSListener() {
    _wsSubscription = WebSocketService.instance.messages.listen((msg) async {
      final event = msg['event'] as String?;
      final eventData = msg['data'];

      if ((event == 'new_order' || event == 'NEW_ORDER') && eventData != null) {
        final targetVendorId = WebSocketService.instance.extractVendorId(eventData);
        final targetHotelId  = WebSocketService.instance.extractHotelId(eventData);
        debugPrint('🔔 [HomeShell] NEW_ORDER: targetVendorId=$targetVendorId, myVendorId=$_currentVendorId, targetHotelId=$targetHotelId, myHotelIds=$_myHotelIds');

        // If vendor ID wasn't loaded yet, try again from SharedPreferences
        if (_currentVendorId == 0) {
          final v = await AuthService.instance.getSavedVendor();
          _currentVendorId = v?.id ?? 0;
          debugPrint('🔑 [HomeShell] Re-loaded vendor ID: $_currentVendorId');
        }

        // If hotel list empty, reload
        if (_myHotelIds.isEmpty) {
          try {
            final hotels = await HotelService.instance.getHotels();
            _myHotelIds = hotels.map((h) => h.id).toList();
            WebSocketService.instance.subscribeToHotels(_myHotelIds);
          } catch (_) {}
        }

        final bool isVendorMismatch = (_currentVendorId > 0 && targetVendorId > 0 && targetVendorId != _currentVendorId);
        final bool isHotelMismatch  = (targetHotelId > 0 && _myHotelIds.isNotEmpty && !_myHotelIds.contains(targetHotelId));

        if (!isVendorMismatch && !isHotelMismatch) {
          debugPrint('✅ [HomeShell] Vendor & Hotel matched! Showing popup for Vendor #$_currentVendorId Hotel #$targetHotelId');
          if (mounted) _showNewOrderNotification(eventData);
        } else {
          debugPrint('⛔ [HomeShell] Mismatched vendor/hotel: targetVendorId=#$targetVendorId targetHotelId=#$targetHotelId myVendorId=#$_currentVendorId myHotelIds=$_myHotelIds — suppressed');
        }
      } else if (event == 'VENDOR_WALLET_UPDATED' && mounted) {
        final map = eventData is Map ? eventData : {};
        final orderId = map['order_id'] ?? '';
        final creditAmt = (map['credit_amount'] != null && map['credit_amount'].toString().isNotEmpty)
            ? map['credit_amount'].toString()
            : '50';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Order #$orderId Delivered! ₹$creditAmt credited to your Vendor Wallet.'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      } else if (event == 'ADMIN_BROADCAST' || event == 'NEW_NOTIFICATION' || event == 'admin_notification') {
        final map = eventData is Map ? Map<String, dynamic>.from(eventData) : <String, dynamic>{};
        final target = (map['target'] ?? '').toString().toLowerCase();

        // If broadcast is for vendors or all users
        if (target.isEmpty || target == 'all' || target == 'vendors' || target == 'vendor') {
          VendorNotificationService.instance.handleRealtimeBroadcast(map);

          if (mounted) {
            final title = map['title']?.toString() ?? 'New Announcement';
            final body = map['body']?.toString() ?? '';

            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.campaign_rounded, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (body.isNotEmpty)
                            Text(
                              body,
                              style: const TextStyle(fontSize: 12, color: Colors.white70),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'VIEW',
                  textColor: Colors.white,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VendorNotificationsScreen(),
                      ),
                    ).then((_) {
                      VendorNotificationService.instance.refreshUnreadCount();
                    });
                  },
                ),
              ),
            );
          }
        }
      }
    });
  }

  OverlayEntry? _newOrderOverlay;

  void _showNewOrderNotification(dynamic orderData) {
    if (!mounted || orderData == null) return;
    try {
      final map = orderData is Map ? orderData : {};
      final data = map['data'] is Map ? map['data'] : map;
      
      final orderId = int.tryParse(data['order_id']?.toString() ?? '') ?? 0;
      final hotelName = data['hotel_name']?.toString() ?? 'Hotel';
      final grandTotal = double.tryParse((data['grand_total'] ?? 0).toString()) ?? 0.0;
      final itemsList = data['items'] as List? ?? [];
      final distanceKm = double.tryParse((data['drop_distance_km'] ?? data['distance_km'] ?? data['distance'] ?? 0).toString()) ?? 0.0;
      final hotelLat = double.tryParse((data['hotel_latitude'] ?? 0).toString()) ?? 0.0;
      final hotelLng = double.tryParse((data['hotel_longitude'] ?? 0).toString()) ?? 0.0;
      final custLat = double.tryParse((data['customer_latitude'] ?? 0).toString()) ?? 0.0;
      final custLng = double.tryParse((data['customer_longitude'] ?? 0).toString()) ?? 0.0;
      final deliveryAddress = data['delivery_address']?.toString() ?? '';

      if (orderId > 0) {
        WebSocketService.instance.markOrderProcessed(orderId);
      }

      // Dismiss any existing popup & trigger alarm sound
      if (_newOrderOverlay != null) {
        WebSocketService.instance.stopAlertSound();
        try {
          _newOrderOverlay?.remove();
        } catch (_) {}
        _newOrderOverlay = null;
      }
      
      WebSocketService.instance.playAlertSound();

      _newOrderOverlay = OverlayEntry(
        builder: (dialogCtx) {
          return Positioned.fill(
            child: Stack(
              children: [
                // Full-screen blurred backdrop
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.65),
                  ),
                ),
                // Centered Accept/Reject Popup Card
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Material(
                      color: Colors.transparent,
                      child: _NewOrderOverlayContent(
                        orderId: orderId,
                        hotelName: hotelName,
                        grandTotal: grandTotal,
                        itemsList: itemsList,
                        distanceKm: distanceKm,
                        hotelLatitude: hotelLat,
                        hotelLongitude: hotelLng,
                        customerLatitude: custLat,
                        customerLongitude: custLng,
                        deliveryAddress: deliveryAddress,
                        onClose: () {
                          WebSocketService.instance.stopAlertSound();
                          try {
                            _newOrderOverlay?.remove();
                          } catch (_) {}
                          _newOrderOverlay = null;
                        },
                        onViewDetails: () {
                          WebSocketService.instance.stopAlertSound();
                          try {
                            _newOrderOverlay?.remove();
                          } catch (_) {}
                          _newOrderOverlay = null;
                          _onTabSelected(1);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );

      final overlayState = Overlay.of(context);
      overlayState.insert(_newOrderOverlay!);
      debugPrint('✅ [HomeShell] New Order Accept/Reject Overlay inserted successfully!');
    } catch (e, stack) {
      debugPrint('HomeShell: Failed to show new order notification: $e\n$stack');
    }
  }

  @override
  void dispose() {
    VendorNotificationService.instance.stopPeriodicSync();
    WebSocketService.instance.stopAlertSound();
    if (_newOrderOverlay != null) {
      try {
        _newOrderOverlay?.remove();
      } catch (_) {}
      _newOrderOverlay = null;
    }
    _wsSubscription?.cancel();
    _pageController.dispose();
    for (final c in _iconControllers) {
      c.dispose();
    }
    WebSocketService.instance.disconnect();
    super.dispose();
  }

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
    if (_pageController.hasClients) {
      _pageController.jumpToPage(index);
    }
    if (index < _iconControllers.length) {
      _iconControllers[index].forward(from: 0);
    }
  }

  DateTime? _lastBackPressTime;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenW = mq.size.width;
    final isWide = screenW >= 600;

    // On wide screens, constrain the navbar items; on phone, let them stretch
    final navbarHPad = isWide ? screenW * 0.2 : 0.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Press back again to exit',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: const Color(0xFF1E293B),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        extendBody: true,
        body: PageView(
          controller: _pageController,
          physics: const ClampingScrollPhysics(),
          onPageChanged: (i) => setState(() => _currentIndex = i),
          children: _tabs,
        ),
        bottomNavigationBar: _buildNavbar(navbarHPad, mq),
      ),
    );
  }

  Widget _buildNavbar(double hPad, MediaQueryData mq) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: AppShadows.navbar,
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 68,
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildNavItem(0, _navItems[0]),
              _buildNavItem(1, _navItems[1]),
              // Center Add button
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final added = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => const AddHotelScreen()),
                    );
                    if (added == true) {
                      _dashboardKey.currentState?.loadHotels();
                    }
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x3DF58220),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            )
                          ],
                        ),
                        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
              _buildNavItem(2, _navItems[2]),
              _buildNavItem(3, _navItems[3]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, _NavItem item) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onTabSelected(index),
        child: AnimatedBuilder(
          animation: _iconScales[index],
          builder: (_, child) => Transform.scale(
            scale: _iconScales[index].value,
            child: child,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Gradient pill for selected, plain for unselected
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                width: isSelected ? 60 : 44,
                height: 36,
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.primaryGradient : null,
                  color: isSelected ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: isSelected
                      ? [BoxShadow(
                          color: AppColors.primary.withOpacity(0.30),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )]
                      : [],
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      isSelected ? item.activeIcon : item.icon,
                      key: ValueKey('${item.label}_$isSelected'),
                      size: 22,
                      color: isSelected ? Colors.white : AppColors.textHint,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textHint,
                  letterSpacing: 0.1,
                ),
                child: Text(item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _NewOrderOverlayContent extends StatefulWidget {
  final int orderId;
  final String hotelName;
  final double grandTotal;
  final List itemsList;
  final double distanceKm;
  final double hotelLatitude;
  final double hotelLongitude;
  final double customerLatitude;
  final double customerLongitude;
  final String deliveryAddress;
  final VoidCallback onClose;
  final VoidCallback onViewDetails;

  const _NewOrderOverlayContent({
    required this.orderId,
    required this.hotelName,
    required this.grandTotal,
    required this.itemsList,
    this.distanceKm = 0.0,
    this.hotelLatitude = 0.0,
    this.hotelLongitude = 0.0,
    this.customerLatitude = 0.0,
    this.customerLongitude = 0.0,
    this.deliveryAddress = '',
    required this.onClose,
    required this.onViewDetails,
  });

  @override
  State<_NewOrderOverlayContent> createState() => _NewOrderOverlayContentState();
}

class _NewOrderOverlayContentState extends State<_NewOrderOverlayContent> with TickerProviderStateMixin {
  bool _isAccepting = false;
  bool _isRejecting = false;
  double _distanceKm = 0.0;

  late AnimationController _entryController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late AnimationController _timerController;

  Future<void> _handleAction(String status) async {
    if (_isAccepting || _isRejecting) return;
    // Stop alarm sound IMMEDIATELY when vendor clicks/slides accept or reject
    WebSocketService.instance.stopAlertSound();

    setState(() {
      if (status == 'accepted') {
        _isAccepting = true;
      } else {
        _isRejecting = true;
      }
    });

    final success = await OrderService.instance.updateOrderStatus(widget.orderId, status);

    if (mounted) {
      setState(() {
        _isAccepting = false;
        _isRejecting = false;
      });
    }

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order #${widget.orderId} was $status successfully!'),
            backgroundColor: status == 'accepted' ? AppColors.success : AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      if (status == 'accepted') {
        widget.onViewDetails();
      } else {
        widget.onClose();
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
  }

  @override
  void initState() {
    super.initState();
    _distanceKm = widget.distanceKm;

    // If distance not passed directly, calculate from hotel and customer coordinates
    if (_distanceKm <= 0 && widget.hotelLatitude != 0.0 && widget.customerLatitude != 0.0) {
      _distanceKm = Geolocator.distanceBetween(
        widget.hotelLatitude,
        widget.hotelLongitude,
        widget.customerLatitude,
        widget.customerLongitude,
      ) / 1000.0;
    }

    // If still 0, load order details asynchronously
    if (_distanceKm <= 0 && widget.orderId > 0) {
      _loadActualDistance();
    }

    // Entry animations
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutBack,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _entryController.forward();

    // Pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Draining timer animation (30 seconds)
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..forward();
  }

  Future<void> _loadActualDistance() async {
    try {
      final order = await OrderService.instance.getOrderById(widget.orderId);
      if (order != null && mounted) {
        final dist = order.dropDistanceKm;
        if (dist > 0) {
          setState(() {
            _distanceKm = dist;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading actual distance: $e');
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
    _timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemsList = widget.itemsList;
    final String itemsSummary = itemsList.isNotEmpty
        ? itemsList.map((i) {
            String name = "${i['quantity'] ?? 1}x ${i['food_name'] ?? 'Item'}";
            List opts = i['selected_optional_items'] ?? i['customizations'] ?? [];
            if (opts.isNotEmpty) {
              List clean = opts
                  .map((s) => s.toString().replaceAll(RegExp(r'^(Sukhi Bhaji|Dry Sabji|Patal Bhaji|Gravy Sabji):\s*', caseSensitive: false), '').trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
              if (clean.isNotEmpty) {
                name += " (${clean.join(' + ')})";
              }
            }
            return name;
          }).join(", ")
        : "Standard Food Parcel";
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // Main White Card Container
              Container(
                margin: const EdgeInsets.only(top: 22),
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 36,
                      spreadRadius: 2,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      'Order #${widget.orderId}',
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    
                    // Thin horizontal divider
                    Divider(color: Colors.grey.shade200, height: 1, thickness: 1),
                    const SizedBox(height: 12),
                    
                    // Single Drop distance row (showing actual customer distance from hotel)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFFFEDD5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFEDD5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: Color(0xFFEA580C),
                              size: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _distanceKm > 0
                                ? 'Drop Distance • ${_distanceKm.toStringAsFixed(1)} kms'
                                : 'Drop Distance • Customer Location',
                            style: const TextStyle(
                              color: Color(0xFF9A3412),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Thin horizontal divider
                    Divider(color: Colors.grey.shade200, height: 1, thickness: 1),
                    const SizedBox(height: 16),
                    
                    // Vendor Info Block
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Square Logo / Icon container
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text(
                                  'ORDER',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  'FOOD',
                                  style: TextStyle(
                                    color: Color(0xFFF97316),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      widget.hotelName,
                                      style: const TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF10B981),
                                    size: 16,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                itemsSummary,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (widget.deliveryAddress.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.home_work_outlined,
                                      color: Color(0xFF64748B),
                                      size: 13,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        widget.deliveryAddress,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time_filled_rounded,
                                    color: Color(0xFF10B981),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _distanceKm > 0
                                        ? '${(_distanceKm * 3.5 + 5).round()} mins delivery'
                                        : 'Standard delivery',
                                    style: const TextStyle(
                                      color: Color(0xFF059669),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Slide to Accept Order Control
                    _SlideToAcceptSlider(
                      isAccepting: _isAccepting,
                      onAccept: () => _handleAction('accepted'),
                    ),
                    const SizedBox(height: 14),
                    
                    // Bottom disclaimer / Reject trigger
                    GestureDetector(
                      onTap: _isAccepting || _isRejecting ? null : () => _handleAction('rejected'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.verified_user_outlined,
                            color: Color(0xFF059669),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "You won't be penalized for rejecting orders",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Top Floating Green Badge
              Positioned(
                top: 0,
                child: ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: const Color(0xFF10B981),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.shopping_bag_outlined,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'New Order',
                          style: TextStyle(
                            color: Color(0xFF047857),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom Slide to Accept slider widget
class _SlideToAcceptSlider extends StatefulWidget {
  final bool isAccepting;
  final VoidCallback onAccept;

  const _SlideToAcceptSlider({
    required this.isAccepting,
    required this.onAccept,
  });

  @override
  State<_SlideToAcceptSlider> createState() => _SlideToAcceptSliderState();
}

class _SlideToAcceptSliderState extends State<_SlideToAcceptSlider> {
  double _dragValue = 0.0; // 0.0 to 1.0

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double trackWidth = constraints.maxWidth;
        const double handleSize = 52.0;
        const double padding = 6.0;
        final double maxDrag = trackWidth - handleSize - (padding * 2);

        return Container(
          height: 64,
          padding: const EdgeInsets.all(padding),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF047857), Color(0xFF059669), Color(0xFF10B981)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Center Label & Right Chevrons
              Center(
                child: widget.isAccepting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Accepting Order...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(width: 32),
                          const Text(
                            'Slide to accept order',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Opacity(
                            opacity: (1.0 - _dragValue).clamp(0.2, 1.0),
                            child: const Icon(
                              Icons.keyboard_double_arrow_right_rounded,
                              color: Colors.white70,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
              ),

              // Draggable Handle
              if (!widget.isAccepting)
                Positioned(
                  left: _dragValue * maxDrag,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      setState(() {
                        double delta = details.delta.dx / maxDrag;
                        _dragValue = (_dragValue + delta).clamp(0.0, 1.0);
                      });
                    },
                    onHorizontalDragEnd: (details) {
                      if (_dragValue >= 0.75) {
                        setState(() {
                          _dragValue = 1.0;
                        });
                        widget.onAccept();
                      } else {
                        setState(() {
                          _dragValue = 0.0;
                        });
                      }
                    },
                    child: Container(
                      width: handleSize,
                      height: handleSize,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.keyboard_double_arrow_right_rounded,
                          color: Color(0xFF047857),
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

