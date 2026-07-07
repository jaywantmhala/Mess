import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../order_status_screen.dart';

class MenuTab extends StatefulWidget {
  const MenuTab({super.key});

  @override
  State<MenuTab> createState() => MenuTabState();
}

class MenuTabState extends State<MenuTab> {
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textGrey = Color(0xFF6B7280);
  static const Color coralPrimary = Color(0xFFE8614A);
  static const Color coralSoft = Color(0xFFFFEDE9);
  static const Color emeraldGreen = Color(0xFF10B981);
  static const Color amberYellow = Color(0xFFF59E0B);

  final List<OrderHistoryItem> _orders = [];
  int _currentPage = 1;
  final int _limit = 10;
  bool _isFirstLoad = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String _filter = 'All'; // 'All', 'Pending', 'Returned'

  @override
  void initState() {
    super.initState();
    fetchOrders(isRefresh: true);
  }

  Future<void> fetchOrders({bool isRefresh = false}) async {
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
      if (!_hasMore || _isLoadingMore) return;
      if (mounted) {
        setState(() {
          _isLoadingMore = true;
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
      }
    }
  }

  List<OrderHistoryItem> get _filteredOrders {
    if (_filter == 'All') return _orders;
    return _orders.where((order) {
      final isDelivered = order.status.toLowerCase() == 'completed' || order.status.toLowerCase() == 'delivered';
      if (_filter == 'Pending') {
        return isDelivered && order.tiffinReceivedToHotel == 'pending';
      } else {
        return isDelivered && order.tiffinReceivedToHotel == 'received';
      }
    }).toList();
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
    final displayList = _filteredOrders;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Title
              const Text(
                'Tiffin Return History',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: textDark,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Track returns of tiffin boxes to your mess/hotels.',
                style: TextStyle(
                  fontSize: 13,
                  color: textGrey,
                ),
              ),
              const SizedBox(height: 20),

              // Filter Chips
              Row(
                children: ['All', 'Pending', 'Returned'].map((f) {
                  final isSelected = _filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _filter = f;
                          });
                        }
                      },
                      selectedColor: coralPrimary.withOpacity(0.12),
                      checkmarkColor: coralPrimary,
                      labelStyle: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? coralPrimary : textGrey,
                      ),
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: isSelected ? coralPrimary : const Color(0xFFE5E7EB),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Orders List
              Expanded(
                child: _isFirstLoad
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: coralPrimary,
                        ),
                      )
                    : RefreshIndicator(
                        color: coralPrimary,
                        onRefresh: () => fetchOrders(isRefresh: true),
                        child: displayList.isEmpty
                            ? ListView(
                                children: [
                                  Container(
                                    height: MediaQuery.of(context).size.height * 0.5,
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: coralPrimary.withOpacity(0.08),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.assignment_return_outlined,
                                            color: coralPrimary,
                                            size: 40,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No $_filter Returns found',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        const Text(
                                          'Orders show tiffin return status once delivered.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: textGrey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: displayList.length + 1,
                                padding: const EdgeInsets.only(bottom: 90),
                                itemBuilder: (context, index) {
                                  if (index == displayList.length) {
                                    if (_isLoadingMore) {
                                      return const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 16.0),
                                        child: Center(
                                          child: CircularProgressIndicator(color: coralPrimary),
                                        ),
                                      );
                                    }
                                    if (_hasMore) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                                        child: Center(
                                          child: TextButton(
                                            onPressed: () => fetchOrders(),
                                            style: TextButton.styleFrom(
                                              backgroundColor: coralSoft,
                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: const Text(
                                              'Load More',
                                              style: TextStyle(
                                                color: coralPrimary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 24.0),
                                      child: Center(
                                        child: Text(
                                          'Showing all orders',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: textGrey,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  final order = displayList[index];
                                  final isDelivered = order.status.toLowerCase() == 'completed' || order.status.toLowerCase() == 'delivered';
                                  final tiffinReceived = order.tiffinReceivedToHotel == 'received';

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 14),
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
                                            builder: (_) => OrderStatusScreen(initialOrder: order),
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
                                                    color: coralPrimary.withOpacity(0.08),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.storefront_rounded,
                                                    color: coralPrimary,
                                                    size: 18,
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
                                                          fontSize: 14.5,
                                                          fontWeight: FontWeight.bold,
                                                          color: textDark,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      const SizedBox(height: 3),
                                                      Text(
                                                        _formatDateTime(order.createdAt),
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color: textGrey,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 1),
                                                      Text(
                                                        'Order #${order.orderId} • ${order.itemCount} items',
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
                                                        fontSize: 14.5,
                                                        fontWeight: FontWeight.w900,
                                                        color: textDark,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    _buildTiffinStatusBadge(isDelivered, tiffinReceived),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTiffinStatusBadge(bool isDelivered, bool tiffinReceived) {
    if (!isDelivered) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          'Order Active',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (tiffinReceived) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: emeraldGreen.withOpacity(0.12),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_circle_outline_rounded, size: 11, color: emeraldGreen),
            SizedBox(width: 4),
            Text(
              'Returned',
              style: TextStyle(
                color: emeraldGreen,
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: amberYellow.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.warning_amber_rounded, size: 11, color: amberYellow),
          SizedBox(width: 4),
          Text(
            'Pending',
            style: TextStyle(
              color: amberYellow,
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
