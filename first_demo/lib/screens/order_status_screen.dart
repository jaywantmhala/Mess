// lib/screens/order_status_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/websocket_service.dart';
import '../services/order_service.dart';

class OrderStatusScreen extends StatefulWidget {
  final OrderHistoryItem initialOrder;

  const OrderStatusScreen({super.key, required this.initialOrder});

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  late OrderHistoryItem _order;
  StreamSubscription? _wsSubscription;

  @override
  void initState() {
    super.initState();
    _order = widget.initialOrder;
    _startWebSocketListener();
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    super.dispose();
  }

  void _startWebSocketListener() {
    // Ensure customer WS is connected
    WebSocketService.instance.connect();

    _wsSubscription = WebSocketService.instance.messages.listen((msg) {
      final event = msg['event'] as String?;
      final eventData = msg['data'];
      if (eventData == null) return;

      if (event == 'ORDER_STATUS_UPDATED') {
        try {
          final orderId = eventData['order_id'] as int?;
          final status = eventData['status'] as String?;
          
          if (orderId == _order.orderId && status != null) {
            if (mounted) {
              setState(() {
                _order = OrderHistoryItem(
                  orderId: _order.orderId,
                  hotelName: _order.hotelName,
                  status: status,
                  grandTotal: _order.grandTotal,
                  walletDeducted: _order.walletDeducted,
                  itemCount: _order.itemCount,
                  createdAt: _order.createdAt,
                );
              });
            }
          }
        } catch (e) {
          debugPrint('Error parsing status update in screen: $e');
        }
      }
    });
  }

  int _getCurrentStep(String status) {
    switch (status) {
      case 'created_order':
        return 0;
      case 'accepted':
      case 'preparing':
        return 1;
      case 'ready':
        return 2;
      case 'completed':
        return 3;
      default:
        return 0;
    }
  }

  String _getStatusTitle(String status) {
    switch (status) {
      case 'created_order':
        return 'Order Placed';
      case 'accepted':
        return 'Order Accepted';
      case 'preparing':
        return 'Preparing Your Meal';
      case 'ready':
        return 'Ready for Pickup';
      case 'completed':
        return 'Order Delivered';
      case 'rejected':
        return 'Order Rejected';
      case 'cancelled':
        return 'Order Cancelled';
      default:
        return status.toUpperCase();
    }
  }

  String _getStatusSubtitle(String status) {
    switch (status) {
      case 'created_order':
        return 'Waiting for canteen confirmation...';
      case 'accepted':
        return 'Canteen accepted your order!';
      case 'preparing':
        return 'Chef is preparing your fresh meal...';
      case 'ready':
        return 'Your food is ready! Please collect it.';
      case 'completed':
        return 'Delivered successfully. Enjoy!';
      case 'rejected':
        return 'Canteen rejected this order. Money refunded.';
      case 'cancelled':
        return 'This order has been cancelled.';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = _getCurrentStep(_order.status);
    final isCancelled = _order.status == 'rejected' || _order.status == 'cancelled';
    final isCompleted = _order.status == 'completed';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Track Order',
          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1F2937)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Canteen & Header info
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _order.hotelName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Text(
                        'Order #${_order.orderId}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getStatusTitle(_order.status),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isCancelled ? Colors.red : const Color(0xFFF07070),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getStatusSubtitle(_order.status),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stepper Tracking list
            if (!isCancelled && !isCompleted)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildTrackingStep(
                      stepIndex: 0,
                      currentStep: currentStep,
                      title: 'Order Placed',
                      subtitle: 'We received your order successfully',
                      icon: Icons.check_circle_outline_rounded,
                    ),
                    _buildStepDivider(0, currentStep),
                    _buildTrackingStep(
                      stepIndex: 1,
                      currentStep: currentStep,
                      title: 'Cooking',
                      subtitle: 'The kitchen is preparing your meal',
                      icon: Icons.flatware_rounded,
                    ),
                    _buildStepDivider(1, currentStep),
                    _buildTrackingStep(
                      stepIndex: 2,
                      currentStep: currentStep,
                      title: 'Ready for Pickup',
                      subtitle: 'Please head to the counter',
                      icon: Icons.inventory_2_rounded,
                    ),
                    _buildStepDivider(2, currentStep),
                    _buildTrackingStep(
                      stepIndex: 3,
                      currentStep: currentStep,
                      title: 'Enjoy!',
                      subtitle: 'Order completed successfully',
                      icon: Icons.celebration_rounded,
                    ),
                  ],
                ),
              ),

            // Success Delivered Panel
            if (isCompleted)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Color(0xFFECFDF5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF10B981),
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Order Delivered! 🎉',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your fresh meal has been served. We hope you enjoy it!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

            // Cancellation Panel
            if (isCancelled)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEF2F2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cancel_rounded,
                        color: Colors.red,
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Order Unsuccessful',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _order.status == 'rejected'
                          ? 'This order was rejected by the canteen. Any deducted wallet balance has been refunded.'
                          : 'This order was cancelled.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

            // Receipt & Bill details
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.01),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BILL DETAILS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF9CA3AF),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total items', style: TextStyle(color: Color(0xFF4B5563))),
                      Text('${_order.itemCount} items', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Wallet payment', style: TextStyle(color: Color(0xFF4B5563))),
                      Text('₹${_order.walletDeducted.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total paid',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Text(
                        '₹${_order.grandTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFF07070),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Back to Home Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF07070),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingStep({
    required int stepIndex,
    required int currentStep,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isDone = currentStep >= stepIndex;
    final isCurrent = currentStep == stepIndex;

    Color stepColor = isDone ? const Color(0xFFF07070) : const Color(0xFFE5E7EB);
    Color textColor = isDone ? const Color(0xFF111827) : const Color(0xFF9CA3AF);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: stepColor.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: isCurrent ? const Color(0xFFF07070) : Colors.transparent,
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            color: stepColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDone ? const Color(0xFF4B5563) : const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider(int stepIndex, int currentStep) {
    final isDone = currentStep > stepIndex;
    return Container(
      height: 32,
      margin: const EdgeInsets.only(left: 20),
      child: VerticalDivider(
        color: isDone ? const Color(0xFFF07070) : const Color(0xFFE5E7EB),
        thickness: 2,
      ),
    );
  }
}
