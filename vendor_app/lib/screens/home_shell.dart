// lib/screens/home_shell.dart
import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'orders_screen.dart';
import 'tabs/menu_tab.dart';
import 'tabs/profile_tab.dart';
import '../services/websocket_service.dart';
import '../services/order_service.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late List<Widget> _tabs;
  OverlayEntry? _newOrderOverlay;
  StreamSubscription? _wsSubscription;

  // Per-tab animation controllers for icon bounce
  late List<AnimationController> _iconControllers;
  late List<Animation<double>> _iconScales;

  static const _navItems = [
    _NavItem(icon: Icons.grid_view_rounded, activeIcon: Icons.grid_view_rounded, label: 'Dashboard'),
    _NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded, label: 'Orders'),
    _NavItem(icon: Icons.restaurant_menu_outlined, activeIcon: Icons.restaurant_menu_rounded, label: 'Menu'),
    _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _tabs = const [DashboardScreen(), OrdersScreen(), MenuTab(), ProfileTab()];

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

    // Establish WebSocket Connection
    WebSocketService.instance.connect(role: 'vendor');
    _startWSListener();
  }

  void _startWSListener() {
    _wsSubscription = WebSocketService.instance.messages.listen((msg) {
      final event = msg['event'] as String?;
      final eventData = msg['data'];
      if (eventData == null) return;

      if (event == 'NEW_ORDER') {
        _showNewOrderNotification(eventData);
      }
    });
  }

  void _showNewOrderNotification(dynamic orderData) {
    if (!mounted) return;
    // Dismiss any existing overlay
    if (_newOrderOverlay != null) {
      WebSocketService.instance.stopAlertSound();
      _newOrderOverlay?.remove();
      _newOrderOverlay = null;
    }
    
    final orderId = orderData['order_id'] ?? 0;
    final hotelName = orderData['hotel_name'] ?? 'Hotel';
    final grandTotal = double.tryParse((orderData['grand_total'] ?? 0).toString()) ?? 0.0;
    final itemsList = orderData['items'] as List? ?? [];

    _newOrderOverlay = OverlayEntry(
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
                    child: _NewOrderOverlayContent(
                      orderId: orderId,
                      hotelName: hotelName,
                      grandTotal: grandTotal,
                      itemsList: itemsList,
                      onClose: () {
                        WebSocketService.instance.stopAlertSound();
                        _newOrderOverlay?.remove();
                        _newOrderOverlay = null;
                      },
                      onViewDetails: () {
                        WebSocketService.instance.stopAlertSound();
                        _newOrderOverlay?.remove();
                        _newOrderOverlay = null;
                        // Switch to Orders tab (index 1)
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

    // Insert overlay safely into the Navigator/Overlay state
    final overlayState = Overlay.of(context);
    overlayState.insert(_newOrderOverlay!);

    // Auto-remove after 30 seconds
    Timer(const Duration(seconds: 30), () {
      if (_newOrderOverlay != null) {
        WebSocketService.instance.stopAlertSound();
        _newOrderOverlay?.remove();
        _newOrderOverlay = null;
      }
    });
  }

  @override
  void dispose() {
    WebSocketService.instance.stopAlertSound();
    _newOrderOverlay?.remove();
    _newOrderOverlay = null;
    _wsSubscription?.cancel();
    _pageController.dispose();
    for (final c in _iconControllers) {
      c.dispose();
    }
    WebSocketService.instance.disconnect();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOutCubic,
    );
    _iconControllers[index].forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenW = mq.size.width;
    final isWide = screenW >= 600;

    // On wide screens, constrain the navbar items; on phone, let them stretch
    final navbarHPad = isWide ? screenW * 0.2 : 0.0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      extendBody: true,
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (i) => setState(() => _currentIndex = i),
        children: _tabs,
      ),
      bottomNavigationBar: _buildNavbar(navbarHPad, mq),
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
            children: List.generate(_navItems.length, (i) {
              return _buildNavItem(i, _navItems[i]);
            }),
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
  final VoidCallback onClose;
  final VoidCallback onViewDetails;

  const _NewOrderOverlayContent({
    required this.orderId,
    required this.hotelName,
    required this.grandTotal,
    required this.itemsList,
    required this.onClose,
    required this.onViewDetails,
  });

  @override
  State<_NewOrderOverlayContent> createState() => _NewOrderOverlayContentState();
}

class _NewOrderOverlayContentState extends State<_NewOrderOverlayContent> with TickerProviderStateMixin {
  bool _isAccepting = false;
  bool _isRejecting = false;

  late AnimationController _entryController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late AnimationController _timerController;

  Future<void> _handleAction(String status) async {
    if (_isAccepting || _isRejecting) return;
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
      widget.onClose();
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
    final itemsList = widget.itemsList;
    
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
                      Icons.restaurant_menu_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Spaced Badge Title
              const Text(
                'NEW ORDER RECEIVED',
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
              const SizedBox(height: 16),
              
              // Items List Container
              if (itemsList.isNotEmpty) ...[
                Container(
                  constraints: const BoxConstraints(maxHeight: 110),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.05),
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: itemsList.map<Widget>((item) {
                        final qty = item['quantity'] ?? 1;
                        final name = item['food_name'] ?? 'Item';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${qty}x',
                                  style: const TextStyle(
                                    color: AppColors.primaryLight,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Total Section & View Details Link
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL AMOUNT',
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
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: widget.onViewDetails,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white,
                            size: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _isAccepting || _isRejecting ? null : () => _handleAction('rejected'),
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
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      onPressed: _isAccepting || _isRejecting ? null : () => _handleAction('accepted'),
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
