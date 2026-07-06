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
    WebSocketService.instance.connect();
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
      _newOrderOverlay?.remove();
      _newOrderOverlay = null;
    }
    
    final orderId = orderData['order_id'] ?? 0;
    final hotelName = orderData['hotel_name'] ?? 'Hotel';
    final grandTotal = double.tryParse((orderData['grand_total'] ?? 0).toString()) ?? 0.0;
    final itemsList = orderData['items'] as List? ?? [];

    _newOrderOverlay = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: _NewOrderOverlayContent(
              orderId: orderId,
              hotelName: hotelName,
              grandTotal: grandTotal,
              itemsList: itemsList,
              onClose: () {
                _newOrderOverlay?.remove();
                _newOrderOverlay = null;
              },
              onViewDetails: () {
                _newOrderOverlay?.remove();
                _newOrderOverlay = null;
                // Switch to Orders tab (index 1)
                _onTabSelected(1);
              },
            ),
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
        _newOrderOverlay?.remove();
        _newOrderOverlay = null;
      }
    });
  }

  @override
  void dispose() {
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 65,
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              // Pill indicator + icon
              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                width: isSelected ? 56 : 40,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primarySurface
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: anim,
                      child: child,
                    ),
                    child: Icon(
                      isSelected ? item.activeIcon : item.icon,
                      key: ValueKey('${item.label}_$isSelected'),
                      size: isSelected ? 24 : 24,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textHint,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Label
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: isSelected ? 11 : 10,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textHint,
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

class _NewOrderOverlayContentState extends State<_NewOrderOverlayContent> {
  bool _isAccepting = false;
  bool _isRejecting = false;

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
  Widget build(BuildContext context) {
    final itemsList = widget.itemsList;
    Widget itemsContainer = const SizedBox.shrink();
    if (itemsList.isNotEmpty) {
      itemsContainer = Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 90),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: itemsList.map<Widget>((item) {
                final qty = item['quantity'] ?? 1;
                final name = item['food_name'] ?? 'Item';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    children: [
                      Text(
                        '${qty}x ',
                        style: const TextStyle(
                          color: AppColors.primaryLight,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E), // Dark premium card
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.restaurant_menu_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🎉 NEW ORDER RECEIVED!',
                      style: TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Order #${widget.orderId} • ${widget.hotelName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white60, size: 18),
                onPressed: widget.onClose,
              ),
            ],
          ),
          const SizedBox(height: 4),
          itemsContainer,
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: ₹${widget.grandTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: widget.onViewDetails,
                child: const Text(
                  'View Details',
                  style: TextStyle(
                    color: AppColors.primaryLight,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: _isAccepting || _isRejecting ? null : () => _handleAction('rejected'),
                  child: _isRejecting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: AppColors.error, strokeWidth: 2),
                        )
                      : const Text(
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 0,
                  ),
                  onPressed: _isAccepting || _isRejecting ? null : () => _handleAction('accepted'),
                  child: _isAccepting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Accept',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
