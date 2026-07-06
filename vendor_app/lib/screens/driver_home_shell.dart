// lib/screens/driver_home_shell.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'driver_dashboard_tab.dart';
import 'driver_orders_tab.dart';
import 'driver_profile_tab.dart';
import '../services/websocket_service.dart';
import '../services/driver_order_service.dart';

class DriverHomeShell extends StatefulWidget {
  const DriverHomeShell({super.key});

  @override
  State<DriverHomeShell> createState() => _DriverHomeShellState();
}

class _DriverHomeShellState extends State<DriverHomeShell> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late List<Widget> _tabs;
  OverlayEntry? _assignmentOverlay;
  StreamSubscription? _wsSubscription;

  // GlobalKey so we can call reload() on DriverOrdersTab when a new order arrives
  final GlobalKey<DriverOrdersTabState> _ordersTabKey = GlobalKey<DriverOrdersTabState>();

  late List<AnimationController> _iconControllers;
  late List<Animation<double>> _iconScales;

  static const _navItems = [
    _NavItem(icon: Icons.delivery_dining_rounded, activeIcon: Icons.delivery_dining_rounded, label: 'Home'),
    _NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded, label: 'Orders'),
    _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Pass the GlobalKey so we can call reload() from outside
    _tabs = [
      const DriverDashboardTab(),
      DriverOrdersTab(key: _ordersTabKey),
      const DriverProfileTab(),
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
            tween: Tween(begin: 1.0, end: 1.28).chain(CurveTween(curve: Curves.easeOut)),
            weight: 40),
        TweenSequenceItem(
            tween: Tween(begin: 1.28, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)),
            weight: 60),
      ]).animate(ctrl);
    }).toList();

    _iconControllers[0].forward(from: 0);

    // Connect WebSocket and listen for notifications
    WebSocketService.instance.connect(role: 'driver');
    _startWSListener();
  }

  void _startWSListener() {
    _wsSubscription = WebSocketService.instance.messages.listen((msg) {
      final event = msg['event'] as String?;
      final eventData = msg['data'];
      if (eventData == null) return;

      if (event == 'ORDER_ASSIGNED') {
        _showAssignmentNotification(eventData);
      }
    });
  }

  void _showAssignmentNotification(dynamic orderData) {
    if (!mounted) return;
    // Dismiss any existing overlay
    if (_assignmentOverlay != null) {
      WebSocketService.instance.stopAlertSound();
      _assignmentOverlay?.remove();
      _assignmentOverlay = null;
    }

    final orderId = orderData['order_id'] ?? 0;
    final hotelName = (orderData['hotel_name'] ?? 'Restaurant') as String;
    final grandTotal = double.tryParse((orderData['grand_total'] ?? 0).toString()) ?? 0.0;

    // Note: WebSocketService._handleMessage() already calls _playAlertSound()
    // automatically when ORDER_ASSIGNED event is received, so no need to call it here.

    _assignmentOverlay = OverlayEntry(
      builder: (context) {
        return Positioned.fill(
          child: Stack(
            children: [
              // Full-screen blurred backdrop
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  color: Colors.black.withOpacity(0.55),
                ),
              ),
              // Centered Popup Card
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Material(
                    color: Colors.transparent,
                    child: _DriverNotificationOverlayContent(
                      orderId: orderId,
                      hotelName: hotelName,
                      grandTotal: grandTotal,
                      onClose: () {
                        WebSocketService.instance.stopAlertSound();
                        _assignmentOverlay?.remove();
                        _assignmentOverlay = null;
                      },
                      onReject: () async {
                        WebSocketService.instance.stopAlertSound();
                        _assignmentOverlay?.remove();
                        _assignmentOverlay = null;
                        // Reject the order
                        await DriverOrderService.instance.updateOrderStatus(
                          orderId: orderId,
                          status: 'rejected_by_driver',
                        );
                        // Refresh orders tab
                        _ordersTabKey.currentState?.reload();
                      },
                      onAccept: () async {
                        WebSocketService.instance.stopAlertSound();
                        _assignmentOverlay?.remove();
                        _assignmentOverlay = null;
                        // Accept the order
                        await DriverOrderService.instance.updateOrderStatus(
                          orderId: orderId,
                          status: 'accepted_by_driver',
                        );
                        // Refresh orders tab first, then navigate there
                        _ordersTabKey.currentState?.reload();
                        _onTabSelected(1); // Navigate to Orders Tab
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
    overlayState.insert(_assignmentOverlay!);

    // Auto-dismiss after 30 seconds
    Timer(const Duration(seconds: 30), () {
      if (_assignmentOverlay != null) {
        WebSocketService.instance.stopAlertSound();
        _assignmentOverlay?.remove();
        _assignmentOverlay = null;
      }
    });
  }

  @override
  void dispose() {
    WebSocketService.instance.stopAlertSound();
    _assignmentOverlay?.remove();
    _assignmentOverlay = null;
    _wsSubscription?.cancel();
    _pageController.dispose();
    for (final c in _iconControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutQuad,
    );
    _iconControllers[index].forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_navItems.length, (index) {
                final item = _navItems[index];
                final isSelected = index == _currentIndex;
                return GestureDetector(
                  onTap: () => _onTabSelected(index),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 72,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ScaleTransition(
                          scale: _iconScales[index],
                          child: Icon(
                            isSelected ? item.activeIcon : item.icon,
                            color: isSelected ? AppColors.primary : AppColors.textHint,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                            color: isSelected ? AppColors.primary : AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Overlay popup — shown when vendor assigns an order to this driver.
// Matches the vendor's NEW_ORDER popup: danger_alert.mp3 sound + Accept + Reject
// ─────────────────────────────────────────────────────────────────────────────

class _DriverNotificationOverlayContent extends StatefulWidget {
  final int orderId;
  final String hotelName;
  final double grandTotal;
  final VoidCallback onClose;
  final VoidCallback onReject;
  final VoidCallback onAccept;

  const _DriverNotificationOverlayContent({
    required this.orderId,
    required this.hotelName,
    required this.grandTotal,
    required this.onClose,
    required this.onReject,
    required this.onAccept,
  });

  @override
  State<_DriverNotificationOverlayContent> createState() =>
      _DriverNotificationOverlayContentState();
}

class _DriverNotificationOverlayContentState
    extends State<_DriverNotificationOverlayContent>
    with TickerProviderStateMixin {
  bool _isAccepting = false;
  bool _isRejecting = false;

  late AnimationController _entryController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late AnimationController _timerController;

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
    _timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          decoration: BoxDecoration(
            color: const Color(0xFF151522), // Premium dark theme
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.18),
                blurRadius: 36,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 16,
                spreadRadius: -4,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pulsing Icon Header
              Center(
                child: ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.delivery_dining_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Spaced Badge Title
              const Text(
                'NEW DELIVERY ASSIGNED',
                style: TextStyle(
                  color: AppColors.primaryLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),

              // Order Number
              Text(
                'Order #${widget.orderId}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),

              // Hotel Name
              Text(
                widget.hotelName,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Countdown Timer Bar
              AnimatedBuilder(
                animation: _timerController,
                builder: (context, child) {
                  return Container(
                    height: 4,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: 1.0 - _timerController.value,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.primaryLight],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Restaurant details info container
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.05),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: AppColors.primaryLight,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PICKUP FROM',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.hotelName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Earnings Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ESTIMATED EARNINGS',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹${widget.grandTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.primaryLight,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white38, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.05),
                      padding: const EdgeInsets.all(10),
                    ),
                    onPressed: (_isAccepting || _isRejecting) ? null : widget.onClose,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  // Reject button
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: (_isAccepting || _isRejecting)
                          ? null
                          : () async {
                              setState(() => _isRejecting = true);
                              widget.onReject();
                            },
                      child: _isRejecting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: AppColors.error, strokeWidth: 2),
                            )
                          : const Text(
                              'Reject',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Accept button
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      onPressed: (_isAccepting || _isRejecting)
                          ? null
                          : () async {
                              setState(() => _isAccepting = true);
                              widget.onAccept();
                            },
                      child: _isAccepting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Accept',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
