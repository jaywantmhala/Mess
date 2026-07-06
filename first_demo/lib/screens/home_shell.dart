import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'tabs/dashboard_tab.dart';
import 'tabs/menu_tab.dart';
import 'tabs/analytics_tab.dart';
import 'tabs/profile_tab.dart';
import '../services/websocket_service.dart';
import '../services/active_order_service.dart';
import 'order_status_screen.dart';
import '../models/order.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kCoralPrimary   = Color(0xFFF07070);
const _kCoralDark      = Color(0xFFE05555);
const _kBgPage         = Color(0xFFF9FAFB);
const _kNavBg          = Color(0xFFFFFFFF);
const _kInactiveIcon   = Color(0xFFB0B7C3);
const _kInactiveLabel  = Color(0xFFB0B7C3);
const _kNavBorder      = Color(0xFFEEF0F4);

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _entryCtrl;
  late Animation<double> _entryFade;
  double? _dragX;
  double? _dragY;

  // Driver assignment overlay
  OverlayEntry? _assignmentOverlay;
  StreamSubscription? _wsSubscription;

  static const _navItems = [
    _NavItem(icon: Icons.home_rounded,              label: 'Home'),
    _NavItem(icon: Icons.restaurant_menu_rounded,   label: 'Menu'),
    _NavItem(icon: Icons.receipt_long_rounded,      label: 'Ledger'),
    _NavItem(icon: Icons.account_circle_rounded,    label: 'Profile'),
  ];

  static const _tabs = [
    HotelLocatorDashboard(),
    MenuTab(),
    AnalyticsTab(),
    ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeIn);
    _entryCtrl.forward();

    // Establish WebSocket Connection
    WebSocketService.instance.connect();

    // Listen for ORDER_ASSIGNED events to show driver notification overlay
    _wsSubscription = WebSocketService.instance.messages.listen((msg) {
      final event = msg['event'] as String?;
      if (event == 'ORDER_ASSIGNED') {
        final data = msg['data'];
        if (data != null && mounted) {
          _showAssignmentOverlay(data);
        }
      }
    });
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    WebSocketService.instance.stopAlertSound();
    _assignmentOverlay?.remove();
    _assignmentOverlay = null;
    _pageController.dispose();
    _entryCtrl.dispose();
    WebSocketService.instance.disconnect();
    super.dispose();
  }

  void _showAssignmentOverlay(dynamic data) {
    if (!mounted) return;
    if (_assignmentOverlay != null) {
      _assignmentOverlay?.remove();
      _assignmentOverlay = null;
    }

    final orderId = data['order_id'] ?? 0;
    final hotelName = data['hotel_name']?.toString() ?? 'Restaurant';
    final grandTotal = double.tryParse(data['grand_total']?.toString() ?? '0') ?? 0.0;

    _assignmentOverlay = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: _DriverAssignmentOverlayContent(
              orderId: orderId,
              hotelName: hotelName,
              grandTotal: grandTotal,
              onDismiss: () {
                WebSocketService.instance.stopAlertSound();
                _assignmentOverlay?.remove();
                _assignmentOverlay = null;
              },
              onViewOrder: () {
                WebSocketService.instance.stopAlertSound();
                _assignmentOverlay?.remove();
                _assignmentOverlay = null;
                _onTabTapped(0);
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

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    // Light haptic feedback on tab change
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Enforce light status bar icons (dark icons on light header)
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return FadeTransition(
      opacity: _entryFade,
      child: Scaffold(
        backgroundColor: _kBgPage,
        extendBody: false,
        body: Stack(
          children: [
            PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentIndex = i),
              children: _tabs,
            ),
            _buildDraggableFloatingTracker(),
          ],
        ),
        bottomNavigationBar: _LightBottomNav(
          currentIndex: _currentIndex,
          items: _navItems,
          onTap: _onTabTapped,
        ),
      ),
    );
  }

  Widget _buildDraggableFloatingTracker() {
    return ValueListenableBuilder<OrderHistoryItem?>(
      valueListenable: ActiveOrderService.instance.activeOrderNotifier,
      builder: (context, activeOrder, child) {
        if (activeOrder == null) return const SizedBox.shrink();

        final mediaQuery = MediaQuery.of(context);
        final screenW = mediaQuery.size.width;
        final screenH = mediaQuery.size.height;
        
        final double defaultX = screenW - 190.0;
        final double defaultY = screenH - 180.0;

        _dragX ??= defaultX;
        _dragY ??= defaultY;

        _dragX = _dragX!.clamp(16.0, screenW - 190.0);
        _dragY = _dragY!.clamp(80.0, screenH - 180.0);

        return Positioned(
          left: _dragX,
          top: _dragY,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _dragX = (_dragX! + details.delta.dx).clamp(16.0, screenW - 190.0);
                _dragY = (_dragY! + details.delta.dy).clamp(80.0, screenH - 180.0);
              });
            },
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderStatusScreen(initialOrder: activeOrder),
                ),
              );
            },
            child: Container(
              width: 175,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E355A).withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D2E4E).withOpacity(0.96),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFFFFD700).withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildPulsingIndicator(activeOrder.status),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.radar, size: 10, color: Color(0xFFFFD700)),
                                SizedBox(width: 3),
                                Text(
                                  'LIVE TRACKING',
                                  style: TextStyle(
                                    color: Color(0xFFFFD700),
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              activeOrder.hotelName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _getShortStatusText(activeOrder.status),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.greenAccent.shade400,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPulsingIndicator(String status) {
    IconData icon;
    Color color;
    switch (status) {
      case 'created_order':
        icon = Icons.receipt_long_rounded;
        color = Colors.amber;
        break;
      case 'accepted':
      case 'preparing':
        icon = Icons.flatware_rounded;
        color = const Color(0xFFF07070);
        break;
      case 'ready':
        icon = Icons.inventory_2_rounded;
        color = Colors.green;
        break;
      default:
        icon = Icons.delivery_dining_rounded;
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Icon(
        icon,
        color: color,
        size: 16,
      ),
    );
  }

  String _getShortStatusText(String status) {
    switch (status) {
      case 'created_order':
        return 'Placed';
      case 'accepted':
        return 'Accepted';
      case 'preparing':
        return 'Cooking';
      case 'ready':
        return 'Ready!';
      default:
        return status.toUpperCase();
    }
  }
}

// ── Bottom Nav ────────────────────────────────────────────────────────────────
class _LightBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _LightBottomNav({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: _kNavBg,
        border: Border(
          top: BorderSide(color: _kNavBorder, width: 1.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60 + (bottomInset > 0 ? 0 : 4),
          child: Row(
            children: List.generate(items.length, (i) {
              return Expanded(
                child: _NavButton(
                  item: items[i],
                  isSelected: i == currentIndex,
                  onTap: () => onTap(i),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Single Nav Button ─────────────────────────────────────────────────────────
class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with animated coral indicator dot above
            Stack(
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              children: [
                // Animated icon container
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutBack,
                  width: isSelected ? 44 : 38,
                  height: isSelected ? 32 : 28,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _kCoralPrimary.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: AnimatedScale(
                      scale: isSelected ? 1.1 : 1.0,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutBack,
                      child: Icon(
                        item.icon,
                        size: 22,
                        color: isSelected ? _kCoralPrimary : _kInactiveIcon,
                      ),
                    ),
                  ),
                ),
                // Active indicator dot above icon
                Positioned(
                  top: -6,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isSelected ? 1.0 : 0.0,
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: _kCoralDark,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            // Label
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? _kCoralPrimary : _kInactiveLabel,
                letterSpacing: 0.1,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

// ── Driver Assignment Alert Overlay ───────────────────────────────────────────
class _DriverAssignmentOverlayContent extends StatefulWidget {
  final int orderId;
  final String hotelName;
  final double grandTotal;
  final VoidCallback onDismiss;
  final VoidCallback onViewOrder;

  const _DriverAssignmentOverlayContent({
    required this.orderId,
    required this.hotelName,
    required this.grandTotal,
    required this.onDismiss,
    required this.onViewOrder,
  });

  @override
  State<_DriverAssignmentOverlayContent> createState() =>
      _DriverAssignmentOverlayContentState();
}

class _DriverAssignmentOverlayContentState
    extends State<_DriverAssignmentOverlayContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFB300).withOpacity(0.7), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB300).withOpacity(0.25),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Pulsing icon
              ScaleTransition(
                scale: _pulseAnim,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB300).withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFB300).withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.delivery_dining_rounded,
                    color: Color(0xFFFFB300),
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🚀 NEW DELIVERY ASSIGNED!',
                      style: TextStyle(
                        color: Color(0xFFFFB300),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Order #${widget.orderId}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.hotelName} • ₹${widget.grandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white38, size: 20),
                onPressed: widget.onDismiss,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white60,
                    side: const BorderSide(color: Colors.white24, width: 1.2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: widget.onDismiss,
                  child: const Text(
                    'Dismiss',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB300),
                    foregroundColor: const Color(0xFF0F1A2E),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: widget.onViewOrder,
                  icon: const Icon(Icons.directions_bike_rounded, size: 18),
                  label: const Text(
                    'Go to Order',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
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
