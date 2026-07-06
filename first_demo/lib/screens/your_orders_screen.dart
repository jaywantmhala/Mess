// lib/screens/your_orders_screen.dart
import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import 'order_status_screen.dart';

class YourOrdersScreen extends StatefulWidget {
  const YourOrdersScreen({super.key});

  @override
  State<YourOrdersScreen> createState() => _YourOrdersScreenState();
}

class _YourOrdersScreenState extends State<YourOrdersScreen> {
  static const Color textDark = Color(0xFF1C1C1C);
  static const Color textGrey = Color(0xFF696969);
  static const Color coralPrimary = Color(0xFFFF6F5E);
  static const Color coralSoft = Color(0xFFFFEDE9);

  final List<OrderHistoryItem> _orders = [];
  int _currentPage = 1;
  final int _limit = 5;
  bool _isFirstLoad = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders({bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 1;
      _hasMore = true;
      _orders.clear();
      if (mounted) {
        setState(() {
          _isFirstLoad = true;
        });
      }
    } else {
      if (!_hasMore) return;
      if (mounted) {
        setState(() {
          if (_currentPage > 1) {
            _isLoadingMore = true;
          } else {
            _isFirstLoad = true;
          }
        });
      }
    }

    try {
      final newOrders = await OrderService.instance.getHistory(
        page: _currentPage,
        limit: _limit,
      );

      if (mounted) {
        setState(() {
          _orders.addAll(newOrders);
          _isFirstLoad = false;
          _isLoadingMore = false;
          if (newOrders.length < _limit) {
            _hasMore = false;
          } else {
            _currentPage++;
          }
        });
      }
    } catch (e) {
      debugPrint('Failed to load orders: $e');
      if (mounted) {
        setState(() {
          _isFirstLoad = false;
          _isLoadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load orders. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'delivered':
        return const Color(0xFF10B981); // Emerald Green
      case 'cancelled':
      case 'rejected':
      case 'rejected_by_driver':
        return Colors.redAccent;
      case 'created_order':
      case 'assigned':
      case 'accepted':
      case 'preparing':
      case 'ready':
      case 'accepted_by_driver':
      case 'picked_up':
      default:
        return const Color(0xFFF59E0B); // Amber Yellow
    }
  }

  String _formatStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'created_order':
        return 'Order Created';
      case 'rejected_by_driver':
        return 'Driver Rejected';
      case 'accepted_by_driver':
        return 'Driver Accepted';
      case 'picked_up':
        return 'Out for Delivery';
      case 'completed':
        return 'Delivered';
      default:
        if (status.isEmpty) return 'Pending';
        return status[0].toUpperCase() + status.substring(1);
    }
  }

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final year = dt.year;
    
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final hourVal = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final hour = hourVal.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');

    return '$day $month $year • $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Your Orders',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: textDark,
          ),
        ),
        centerTitle: true,
      ),
      body: _isFirstLoad
          ? const Center(
              child: CircularProgressIndicator(
                color: coralPrimary,
              ),
            )
          : RefreshIndicator(
              color: coralPrimary,
              onRefresh: () => _fetchOrders(isRefresh: true),
              child: _orders.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.7,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: const BoxDecoration(
                                color: coralSoft,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.receipt_long_rounded,
                                color: coralPrimary,
                                size: 48,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'No Orders Yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Looks like you haven\'t placed any orders. Go ahead and order some delicious food!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: _orders.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _orders.length) {
                          // Show load more or loading indicators
                          if (_isLoadingMore) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24.0),
                              child: Center(
                                child: CircularProgressIndicator(color: coralPrimary),
                              ),
                            );
                          }
                          
                          if (_hasMore) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              child: Center(
                                child: TextButton(
                                  onPressed: () => _fetchOrders(),
                                  style: TextButton.styleFrom(
                                    backgroundColor: coralSoft,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Show More',
                                    style: TextStyle(
                                      color: coralPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                          
                          // No more items indicator
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.0),
                            child: Center(
                              child: Text(
                                'Showing all your orders',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textGrey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }

                        final order = _orders[index];
                        final statusColor = _getStatusColor(order.status);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Color(0xFFEEF0F4)),
                          ),
                          color: Colors.white,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OrderStatusScreen(initialOrder: order),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: coralSoft.withOpacity(0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.storefront_rounded,
                                          color: coralPrimary,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              order.hotelName,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                                color: textDark,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _formatDateTime(order.createdAt),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: textGrey,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${order.itemCount} ${order.itemCount == 1 ? 'item' : 'items'}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: textGrey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '₹${order.grandTotal}',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w900,
                                              color: textDark,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: statusColor.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(30),
                                            ),
                                            child: Text(
                                              _formatStatusText(order.status),
                                              style: TextStyle(
                                                color: statusColor,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
