// lib/screens/driver_dashboard_tab.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/driver.dart';
import '../services/driver_auth_service.dart';
import '../services/driver_order_service.dart';
import '../services/websocket_service.dart';
import '../theme/app_theme.dart';

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

  // Simulated GPS coordinates interpolation parameters
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
    
    // Check if there is any active order currently in "picked_up" state
    final pickedUpOrders = _activeOrders.where((o) => o.status == 'picked_up').toList();
    if (pickedUpOrders.isEmpty || !_isOnline) {
      _simulatedProgress = 0.0;
      return;
    }

    final activeOrder = pickedUpOrders.first;
    
    // Setup a 10-second periodic timer to simulate GPS coordinates movement
    _gpsTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!_isOnline || !mounted) {
        timer.cancel();
        return;
      }

      // Step ratio by 5% every 10 seconds
      if (_simulatedProgress < 1.0) {
        _simulatedProgress += 0.05;
        if (_simulatedProgress > 1.0) _simulatedProgress = 1.0;
      }

      // Interpolate coordinates from hotel to customer
      final double lat = activeOrder.hotelLat + (activeOrder.customerLat - activeOrder.hotelLat) * _simulatedProgress;
      final double lng = activeOrder.hotelLng + (activeOrder.customerLng - activeOrder.hotelLng) * _simulatedProgress;

      // Broadcast location via WebSocket
      WebSocketService.instance.sendLocationUpdate(lat, lng);

      // Also trigger the API fallback update
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
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text(
          'Driver Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadProfile();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Online Toggle Card
              Container(
                decoration: BoxDecoration(
                  gradient: _isOnline ? AppColors.primaryGradient : null,
                  color: _isOnline ? null : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: _isOnline ? AppShadows.elevated : null,
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isOnline ? 'YOU ARE ONLINE' : 'YOU ARE OFFLINE',
                            style: TextStyle(
                              color: _isOnline ? Colors.white : AppColors.textHint,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isOnline 
                                ? 'Available to accept and deliver orders' 
                                : 'Toggle online to receive orders',
                            style: TextStyle(
                              color: _isOnline ? Colors.white70 : AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _isOnline,
                      activeColor: Colors.white,
                      activeTrackColor: Colors.white.withOpacity(0.38),
                      onChanged: (val) => _toggleOnlineStatus(val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Welcome details card
              Text(
                'Welcome, ${_driver?.fullName ?? "Driver"}!',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              Text(
                'Vehicle: ${_driver?.vehicleNumber ?? "Motorcycle"}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textHint,
                ),
              ),
              const SizedBox(height: 24),

              // Active Orders summary card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.delivery_dining_rounded, color: AppColors.primary, size: 24),
                        SizedBox(width: 10),
                        Text(
                          'Delivery Activity',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat('Active Tasks', '${_activeOrders.length}'),
                        Container(height: 32, width: 1, color: Colors.grey.shade200),
                        _buildStat('Pickup Pending', '${_activeOrders.where((o) => o.status == 'accepted_by_driver').length}'),
                        Container(height: 32, width: 1, color: Colors.grey.shade200),
                        _buildStat('In Transit', '${_activeOrders.where((o) => o.status == 'picked_up').length}'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (_activeOrders.isNotEmpty) ...[
                const Text(
                  'Current Assigned Deliveries',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _activeOrders.length,
                  itemBuilder: (context, index) {
                    final order = _activeOrders[index];
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                      color: const Color(0xFFF8FAFC),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order.hotelName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Order #${order.orderId} • Status: ${order.status.replaceAll('_', ' ').toUpperCase()}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textHint),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ] else ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        const Text(
                          'No active deliveries.\nGo online and await assignments.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textHint, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textHint,
          ),
        ),
      ],
    );
  }
}
