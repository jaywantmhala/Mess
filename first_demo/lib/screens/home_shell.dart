import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    // Entry fade-in for the whole shell
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeIn);
    _entryCtrl.forward();

    // Establish WebSocket Connection
    WebSocketService.instance.connect();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _entryCtrl.dispose();
    WebSocketService.instance.disconnect();
    super.dispose();
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
        
        final double defaultX = screenW - 170.0;
        final double defaultY = screenH - 180.0;

        _dragX ??= defaultX;
        _dragY ??= defaultY;

        _dragX = _dragX!.clamp(16.0, screenW - 170.0);
        _dragY = _dragY!.clamp(80.0, screenH - 180.0);

        return Positioned(
          left: _dragX,
          top: _dragY,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _dragX = (_dragX! + details.delta.dx).clamp(16.0, screenW - 170.0);
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
            child: MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: Container(
                width: 155,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E1E2E), Color(0xFF2D2D3E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF07070).withOpacity(0.8), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF07070).withOpacity(0.2),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPulsingIndicator(activeOrder.status),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TRACK ORDER',
                            style: TextStyle(
                              color: Color(0xFFF07070),
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            activeOrder.hotelName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            _getShortStatusText(activeOrder.status),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: color,
        size: 18,
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
