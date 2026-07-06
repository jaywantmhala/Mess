// lib/screens/driver_home_shell.dart
import 'dart:async';
import 'dart:convert';
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
    _tabs = const [
      DriverDashboardTab(),
      DriverOrdersTab(),
      DriverProfileTab(),
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
    WebSocketService.instance.connect();
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
    if (_assignmentOverlay != null) {
      WebSocketService.instance.stopAlertSound();
      _assignmentOverlay?.remove();
      _assignmentOverlay = null;
    }

    final orderId = orderData['order_id'] ?? 0;

    _assignmentOverlay = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: _DriverNotificationOverlayContent(
              orderId: orderId,
              onClose: () {
                WebSocketService.instance.stopAlertSound();
                _assignmentOverlay?.remove();
                _assignmentOverlay = null;
              },
              onAccept: () async {
                WebSocketService.instance.stopAlertSound();
                _assignmentOverlay?.remove();
                _assignmentOverlay = null;
                // Accept order
                await DriverOrderService.instance.updateOrderStatus(orderId: orderId, status: 'accepted_by_driver');
                _onTabSelected(1); // Navigate to Orders Tab
              },
            ),
          ),
        );
      },
    );

    final overlayState = Overlay.of(context);
    overlayState.insert(_assignmentOverlay!);

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

class _DriverNotificationOverlayContent extends StatefulWidget {
  final int orderId;
  final VoidCallback onClose;
  final VoidCallback onAccept;

  const _DriverNotificationOverlayContent({
    required this.orderId,
    required this.onClose,
    required this.onAccept,
  });

  @override
  State<_DriverNotificationOverlayContent> createState() =>
      _DriverNotificationOverlayContentState();
}

class _DriverNotificationOverlayContentState extends State<_DriverNotificationOverlayContent> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
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
                  Icons.delivery_dining_rounded,
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
                      '🔔 NEW DELIVERY ASSIGNED!',
                      style: TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Order #${widget.orderId}',
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white60,
                    side: const BorderSide(color: Colors.white30, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: _isProcessing ? null : widget.onClose,
                  child: const Text(
                    'Close',
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
                  onPressed: _isProcessing
                      ? null
                      : () async {
                          setState(() => _isProcessing = true);
                          widget.onAccept();
                        },
                  child: _isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Accept Order',
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
