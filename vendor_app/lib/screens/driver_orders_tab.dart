// lib/screens/driver_orders_tab.dart
import 'package:flutter/material.dart';
import '../services/driver_order_service.dart';
import '../theme/app_theme.dart';

class DriverOrdersTab extends StatefulWidget {
  const DriverOrdersTab({super.key});

  @override
  State<DriverOrdersTab> createState() => _DriverOrdersTabState();
}

class _DriverOrdersTabState extends State<DriverOrdersTab> {
  bool _isLoading = true;
  List<DriverOrder> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final list = await DriverOrderService.instance.fetchOrders();
    if (mounted) {
      setState(() {
        _orders = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(int orderId, String newStatus) async {
    final success = await DriverOrderService.instance.updateOrderStatus(
      orderId: orderId,
      status: newStatus,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order status updated to ${newStatus.replaceAll('_', ' ').toUpperCase()}'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update order status. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text(
          'My Deliveries',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _orders.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      return _buildOrderCard(order);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text(
            'No assigned deliveries yet.',
            style: TextStyle(fontSize: 16, color: AppColors.textHint, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(DriverOrder order) {
    Color statusColor;
    switch (order.status) {
      case 'assigned':
        statusColor = Colors.orange;
        break;
      case 'accepted_by_driver':
        statusColor = Colors.blue;
        break;
      case 'picked_up':
        statusColor = AppColors.primary;
        break;
      case 'completed':
        statusColor = AppColors.success;
        break;
      default:
        statusColor = AppColors.textHint;
    }

    final isHistory = order.status == 'completed';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Order ID & Status tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${order.orderId}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.ink),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.status.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // Addresses
          Row(
            children: [
              const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${order.hotelName} • ${order.hotelAddress}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: AppColors.error, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${order.customerName} • ${order.deliveryAddress}',
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Bill Total / Payment Method
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Grand Total: ₹${order.grandTotal.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.ink),
              ),
              Text(
                'Payment: ${order.paymentMethod}',
                style: const TextStyle(fontSize: 13, color: AppColors.textHint),
              ),
            ],
          ),

          // Action buttons if active
          if (!isHistory) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: _buildActionButton(order),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(DriverOrder order) {
    if (order.status == 'assigned') {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          elevation: 0,
        ),
        onPressed: () => _updateStatus(order.orderId, 'accepted_by_driver'),
        icon: const Icon(Icons.check_circle_outline, size: 18),
        label: const Text('Accept Delivery', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    } else if (order.status == 'accepted_by_driver') {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          elevation: 0,
        ),
        onPressed: () => _updateStatus(order.orderId, 'picked_up'),
        icon: const Icon(Icons.sports_motorsports_outlined, size: 18),
        label: const Text('Pick Up Order', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    } else if (order.status == 'picked_up') {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          elevation: 0,
        ),
        onPressed: () => _updateStatus(order.orderId, 'completed'),
        icon: const Icon(Icons.task_alt, size: 18),
        label: const Text('Complete Delivery', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    }
    return const SizedBox.shrink();
  }
}
