// lib/screens/driver_orders_tab.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/driver_order_service.dart';
import '../services/websocket_service.dart';
import '../services/driver_auth_service.dart';
import 'driver_home_shell.dart';

class DriverOrdersTab extends StatefulWidget {
  const DriverOrdersTab({super.key});

  @override
  State<DriverOrdersTab> createState() => DriverOrdersTabState();
}

class DriverOrdersTabState extends State<DriverOrdersTab> {
  bool _isLoading = true;
  List<DriverOrder> _orders = [];
  String _selectedFilter = 'All Orders'; // 'All Orders', 'Active', 'Completed'
  StreamSubscription? _wsSubscription;
  StreamSubscription<Position>? _positionSubscription;
  Position? _currentDriverPosition;

  // Design Tokens matching 100% reference photo
  static const Color _brandOrange  = Color(0xFFF58220);
  static const Color _gradientEnd  = Color(0xFFE65100);
  static const Color _greenSuccess = Color(0xFF00A65A);
  static const Color _bgWarm       = Color(0xFFF6F8FA);
  static const Color _white        = Colors.white;
  static const Color _ink          = Color(0xFF1A1A2E);
  static const Color _greySub      = Color(0xFF8A8FA8);
  static const Color _cardBorder   = Color(0xFFEEEEEE);

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _startWebSocketListener();
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }

  /// Called externally (from DriverHomeShell) to trigger a reload
  void reload() => _loadOrders();

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final list = await DriverOrderService.instance.fetchOrders();
    if (mounted) {
      setState(() {
        _orders = list;
        _isLoading = false;
      });
      _checkAndManageLocationSharing();
    }
  }

  void _startWebSocketListener() {
    _wsSubscription = WebSocketService.instance.messages.listen((msg) {
      final event = msg['event'] as String?;
      final eventData = msg['data'];
      if (eventData == null) return;

      if (event == 'ORDER_ASSIGNED') {
        _handleOrderAssigned(eventData);
      } else if (event == 'ORDER_STATUS_UPDATED') {
        _handleStatusUpdated(eventData);
      }
    });
  }

  void _handleOrderAssigned(dynamic data) async {
    if (!mounted) return;
    try {
      final assignedDriverId = int.tryParse(data['driver_id']?.toString() ?? '') ?? 0;
      final currentDriver = await DriverAuthService.instance.getSavedDriver();
      if (currentDriver == null || assignedDriverId != currentDriver.id) return;

      final orderId = int.tryParse(data['order_id'].toString()) ?? 0;
      final existingIndex = _orders.indexWhere((o) => o.orderId == orderId);
      if (existingIndex >= 0) return;

      _loadOrders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📦 New delivery assigned: Order #$orderId!'),
            backgroundColor: _brandOrange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('DriverOrdersTab: Error handling ORDER_ASSIGNED: $e');
    }
  }

  void _handleStatusUpdated(dynamic data) {
    if (!mounted) return;
    try {
      final orderId = int.tryParse(data['order_id'].toString()) ?? 0;
      final status = data['status'] as String?;
      if (orderId <= 0 || status == null) return;

      setState(() {
        for (int i = 0; i < _orders.length; i++) {
          if (_orders[i].orderId == orderId) {
            final old = _orders[i];
            _orders[i] = DriverOrder(
              orderId: old.orderId,
              status: status,
              grandTotal: old.grandTotal,
              paymentMethod: old.paymentMethod,
              deliveryAddress: old.deliveryAddress,
              createdAt: old.createdAt,
              hotelName: old.hotelName,
              hotelAddress: old.hotelAddress,
              hotelLat: old.hotelLat,
              hotelLng: old.hotelLng,
              customerLat: old.customerLat,
              customerLng: old.customerLng,
              customerName: old.customerName,
              customerPhone: old.customerPhone,
            );
            break;
          }
        }
      });
      _checkAndManageLocationSharing();
    } catch (e) {
      debugPrint('DriverOrdersTab: Error handling ORDER_STATUS_UPDATED: $e');
    }
  }

  void _checkResponseForPendingTiffin(Map<String, dynamic> res) {
    try {
      final data = res['data'];
      if (data != null && data is Map) {
        if (data['has_pending_tiffin'] == true && data['pending_tiffin'] != null) {
          final parentState = context.findAncestorStateOfType<DriverHomeShellState>();
          if (parentState != null) {
            debugPrint('DriverOrdersTab: Pending tiffin detected in status update response! Triggering popup...');
            parentState.showTiffinReturnPopup(data['pending_tiffin']);
          }
        }
      }
    } catch (e) {
      debugPrint('DriverOrdersTab: Error checking response for pending tiffin: $e');
    }
  }

  Future<void> _updateStatus(int orderId, String newStatus, {String? otp}) async {
    final res = await DriverOrderService.instance.updateOrderStatus(
      orderId: orderId,
      status: newStatus,
      otp: otp,
    );
    final success = res['success'] == true;

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order #$orderId updated to ${newStatus.replaceAll('_', ' ').toUpperCase()}'),
            backgroundColor: _greenSuccess,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      _loadOrders();
      _checkResponseForPendingTiffin(res);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message']?.toString() ?? 'Failed to update order status. Please try again.'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _checkAndManageLocationSharing() async {
    bool hasActive = false;
    for (var o in _orders) {
      if (o.status == 'picked_up' || o.status == 'arrived_at_customer') {
        hasActive = true;
        break;
      }
    }

    if (hasActive) {
      if (_positionSubscription == null) {
        await _startLocationSharing();
      }
    } else {
      await _stopLocationSharing();
    }
  }

  Future<void> _startLocationSharing() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15,
      );

      _positionSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
        WebSocketService.instance.sendLocationUpdate(position.latitude, position.longitude);
        if (mounted) {
          setState(() {
            _currentDriverPosition = position;
          });
        }
      });

      final initialPos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() {
          _currentDriverPosition = initialPos;
        });
      }
    } catch (e) {
      debugPrint('Error starting location sharing: $e');
    }
  }

  Future<void> _stopLocationSharing() async {
    if (_positionSubscription != null) {
      await _positionSubscription!.cancel();
      _positionSubscription = null;
    }
    if (mounted) {
      setState(() {
        _currentDriverPosition = null;
      });
    }
  }

  void _showOtpSheet(BuildContext context, DriverOrder order) {
    final TextEditingController otpController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool isVerifying = false;
        String? errorMsg;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF151522),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Confirm Delivery OTP',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ask the customer for the 4-digit delivery OTP shown on their screen.',
                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.6)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 10, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: '0000',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), letterSpacing: 10),
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.06),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: _brandOrange, width: 2),
                      ),
                    ),
                  ),
                  if (errorMsg != null) ...[
                    const SizedBox(height: 10),
                    Text(errorMsg ?? '', style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _greenSuccess,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: isVerifying ? null : () async {
                        final enteredOtp = otpController.text.trim();
                        if (enteredOtp.length < 4) {
                          setModalState(() {
                            errorMsg = 'Please enter a 4-digit OTP.';
                          });
                          return;
                        }
                        setModalState(() {
                          isVerifying = true;
                          errorMsg = null;
                        });

                        final res = await DriverOrderService.instance.updateOrderStatus(
                          orderId: order.orderId,
                          status: 'completed',
                          otp: enteredOtp,
                        );

                        if (res['success'] == true) {
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                          _loadOrders();
                          _checkResponseForPendingTiffin(res);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('🎉 Delivery confirmed successfully!'),
                                backgroundColor: _greenSuccess,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                        } else {
                          setModalState(() {
                            isVerifying = false;
                            errorMsg = res['message']?.toString() ?? 'Invalid OTP. Please check and try again.';
                          });
                        }
                      },
                      child: isVerifying
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text('Verify & Complete Delivery', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  int get _activeCount => _orders.where((o) => o.status != 'completed' && o.status != 'rejected_by_driver' && o.status != 'rejected').length;
  int get _completedCount => _orders.where((o) => o.status == 'completed').length;

  List<DriverOrder> get _filteredOrders {
    if (_selectedFilter == 'Active') {
      return _orders.where((o) => o.status != 'completed' && o.status != 'rejected_by_driver' && o.status != 'rejected').toList();
    } else if (_selectedFilter == 'Completed') {
      return _orders.where((o) => o.status == 'completed').toList();
    }
    return _orders;
  }

  @override
  Widget build(BuildContext context) {
    final displayOrders = _filteredOrders;

    return Scaffold(
      backgroundColor: _bgWarm,
      body: SafeArea(
        child: Column(
          children: [
            // ── 1. Top Vibrant Orange Header Banner ──────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_brandOrange, _gradientEnd],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.menu_rounded, color: _white, size: 26),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'My Deliveries',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: _white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Track your all deliveries',
                        style: TextStyle(
                          fontSize: 12,
                          color: _white.withOpacity(0.85),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _loadOrders,
                    child: const Icon(Icons.refresh_rounded, color: _white, size: 24),
                  ),
                ],
              ),
            ),

            // ── 2. Top Underlined Filter Tabs Bar ────────────────────────────
            Container(
              color: _white,
              child: Row(
                children: [
                  _buildTopTab('All Orders', count: null),
                  _buildTopTab('Active', count: _activeCount, isGreenBadge: false),
                  _buildTopTab('Completed', count: _completedCount, isGreenBadge: true),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── 3. Orders List ───────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: _brandOrange))
                  : displayOrders.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          color: _brandOrange,
                          onRefresh: _loadOrders,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
                            itemCount: displayOrders.length,
                            itemBuilder: (context, index) {
                              final order = displayOrders[index];
                              return _buildOrderCard(order);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopTab(String title, {int? count, bool isGreenBadge = false}) {
    final isSelected = _selectedFilter == title;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = title;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? _brandOrange : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? _brandOrange : const Color(0xFF666666),
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isGreenBadge ? _greenSuccess : _brandOrange,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: _white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/no_orders_illustration.png',
              height: 160,
              fit: BoxFit.contain,
              errorBuilder: (ctx, _, __) => Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF0E6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.assignment_outlined, size: 50, color: _brandOrange),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _selectedFilter == 'Completed'
                  ? 'No completed deliveries'
                  : 'No active deliveries assigned',
              style: const TextStyle(fontSize: 18, color: _ink, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'When new orders are assigned to you,\nthey will appear here instantly.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _greySub, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(DriverOrder order) {
    final bool isCompleted = order.status == 'completed';
    final bool isHistory = isCompleted || order.status == 'rejected_by_driver' || order.status == 'rejected';

    final Color themeColor = isCompleted ? _greenSuccess : _brandOrange;
    final Color iconBoxBg  = isCompleted ? const Color(0xFFE8F8F0) : const Color(0xFFFFF0E6);
    final Color priceBoxBg = isCompleted ? const Color(0xFFF0FDF4) : const Color(0xFFFFF8F2);

    String statusLabel = order.status.replaceAll('_', ' ').toUpperCase();
    if (order.status == 'picked_up') statusLabel = 'PICKED UP';

    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row: Icon + Order # + Date + Status Pill Badge ──────────
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBoxBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.shopping_bag_rounded, color: themeColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.orderId}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16.5,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '11 May 2025 • 12:45 PM',
                      style: const TextStyle(
                        fontSize: 12,
                        color: _greySub,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Solid Filled Status Pill Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: themeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: const TextStyle(
                    color: _white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Horizontal Dashed Divider
          CustomPaint(
            size: const Size(double.infinity, 1),
            painter: HorizontalDashedLinePainter(color: const Color(0xFFE5E5E5)),
          ),
          const SizedBox(height: 14),

          // ── Timeline & Pricing Summary Box Row ──────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Timeline Address Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hotel Step Row
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: iconBoxBg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.restaurant_rounded, color: themeColor, size: 14),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.hotelName,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: _ink,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                order.hotelAddress,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: _greySub,
                                  fontWeight: FontWeight.w500,
                                  height: 1.25,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Dashed Vertical Line
                    Padding(
                      padding: const EdgeInsets.only(left: 13, top: 2, bottom: 2),
                      child: CustomPaint(
                        size: const Size(2, 22),
                        painter: VerticalDashedLinePainter(color: const Color(0xFFCCCCCC)),
                      ),
                    ),

                    // Customer Step Row
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: iconBoxBg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.location_on_rounded, color: themeColor, size: 14),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      order.customerName.isNotEmpty ? order.customerName : 'Customer',
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: _ink,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () async {
                                      final phone = order.customerPhone;
                                      if (phone.isNotEmpty) {
                                        final uri = Uri.parse('tel:$phone');
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(uri);
                                        } else {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Could not launch call to $phone')),
                                            );
                                          }
                                        }
                                      } else {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Customer phone number not available')),
                                          );
                                        }
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFFA5D6A7)),
                                      ),
                                      child: const Icon(
                                        Icons.phone_rounded,
                                        color: Color(0xFF2E7D32),
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                order.deliveryAddress,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: _greySub,
                                  fontWeight: FontWeight.w500,
                                  height: 1.25,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Right Pricing Summary Box
              Container(
                width: 115,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: priceBoxBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Payment',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: _greySub,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.paymentMethod.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        color: themeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Action buttons if active
          if (!isHistory) ...[
            const SizedBox(height: 14),
            _buildActionButton(order),
          ],
        ],
      ),
    );
  }

  void _navigateToAddress({required String address, required double lat, required double lng}) async {
    String cleanAddress = address.replaceAll(RegExp(r'^[^\w\s]+\s*\w+:\s*', unicode: true), '').trim();
    if (cleanAddress.isEmpty) cleanAddress = address.trim();

    final bool hasValidCoords = lat != 0.0 && lng != 0.0 && lat != 18.5204;
    final String navQuery = hasValidCoords
        ? '$lat,$lng'
        : Uri.encodeComponent(cleanAddress);

    final String googleNavUrl = 'google.navigation:q=$navQuery';
    final String mapsWebUrl = 'https://www.google.com/maps/dir/?api=1&destination=$navQuery';

    try {
      final navUri = Uri.parse(googleNavUrl);
      final webUri = Uri.parse(mapsWebUrl);

      if (await canLaunchUrl(navUri)) {
        await launchUrl(navUri);
      } else if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open map for address: $cleanAddress')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error launching map navigation: $e');
    }
  }

  Widget _buildActionButton(DriverOrder order) {
    if (order.status == 'assigned') {
      return Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _updateStatus(order.orderId, 'rejected_by_driver'),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF8B4B4), width: 1.2),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.close_rounded, color: Color(0xFFDC3545), size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Reject',
                      style: TextStyle(
                        color: Color(0xFFDC3545),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => _updateStatus(order.orderId, 'accepted_by_driver'),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: _brandOrange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, color: _white, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Accept',
                      style: TextStyle(
                        color: _white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    } else if (order.status == 'accepted_by_driver') {
      return Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _navigateToAddress(
                address: order.hotelAddress,
                lat: order.hotelLat,
                lng: order.hotelLng,
              ),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: _white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00A65A), width: 1.5),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.near_me_rounded, color: Color(0xFF00A65A), size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Navigate Mess',
                      style: TextStyle(
                        color: Color(0xFF00A65A),
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => _updateStatus(order.orderId, 'picked_up'),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: _brandOrange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.two_wheeler_rounded, color: _white, size: 20),
                    SizedBox(width: 6),
                    Text(
                      'Pick Up Order',
                      style: TextStyle(
                        color: _white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    } else if (order.status == 'picked_up') {
      double? distance;
      if (_currentDriverPosition != null && order.customerLat != 0.0) {
        distance = Geolocator.distanceBetween(
          _currentDriverPosition!.latitude,
          _currentDriverPosition!.longitude,
          order.customerLat,
          order.customerLng,
        );
      }
      final bool canConfirmArrival = distance != null && distance <= 50;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToAddress(
                    address: order.deliveryAddress,
                    lat: order.customerLat,
                    lng: order.customerLng,
                  ),
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: _white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF00A65A), width: 1.5),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.near_me_rounded, color: Color(0xFF00A65A), size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Navigate',
                          style: TextStyle(
                            color: Color(0xFF00A65A),
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: canConfirmArrival ? () => _updateStatus(order.orderId, 'arrived_at_customer') : null,
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: canConfirmArrival ? _brandOrange : _brandOrange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on_rounded, color: _white, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Confirm Arrival',
                          style: TextStyle(
                            color: _white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3F3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on_rounded, color: Color(0xFFE53935), size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    distance == null
                        ? 'Waiting for GPS location...'
                        : canConfirmArrival
                            ? 'Within delivery radius (50m). Tap Confirm Arrival.'
                            : 'Must be within 50m to confirm arrival. (${distance.toStringAsFixed(0)}m)',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFFE53935),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else if (order.status == 'arrived_at_customer') {
      return GestureDetector(
        onTap: () => _showOtpSheet(context, order),
        child: Container(
          height: 48,
          width: double.infinity,
          decoration: BoxDecoration(
            color: _greenSuccess,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.vpn_key_rounded, color: _white, size: 20),
              SizedBox(width: 8),
              Text(
                'Deliver Order',
                style: TextStyle(
                  color: _white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Painters for Dashed Lines (Horizontal and Vertical)
// ─────────────────────────────────────────────────────────────────────────────

class HorizontalDashedLinePainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashSpace;

  HorizontalDashedLinePainter({
    required this.color,
    this.dashWidth = 4,
    this.dashSpace = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class VerticalDashedLinePainter extends CustomPainter {
  final Color color;
  final double dashHeight;
  final double dashSpace;

  VerticalDashedLinePainter({
    required this.color,
    this.dashHeight = 3,
    this.dashSpace = 3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
