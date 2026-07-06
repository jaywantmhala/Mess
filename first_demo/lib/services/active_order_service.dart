// lib/services/active_order_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/order.dart';
import 'websocket_service.dart';

class ActiveOrderService {
  ActiveOrderService._() {
    _startWSListener();
  }
  static final ActiveOrderService instance = ActiveOrderService._();

  final ValueNotifier<OrderHistoryItem?> activeOrderNotifier =
      ValueNotifier<OrderHistoryItem?>(null);

  StreamSubscription? _wsSubscription;

  void trackOrder(OrderHistoryItem order) {
    // If the order status is already terminal, don't track it
    if (order.status == 'completed' ||
        order.status == 'rejected' ||
        order.status == 'cancelled') {
      activeOrderNotifier.value = null;
      return;
    }
    activeOrderNotifier.value = order;
  }

  void clearTracking() {
    activeOrderNotifier.value = null;
  }

  void _startWSListener() {
    _wsSubscription = WebSocketService.instance.messages.listen((msg) {
      final event = msg['event'] as String?;
      final eventData = msg['data'];
      if (eventData == null || activeOrderNotifier.value == null) return;

      if (event == 'ORDER_STATUS_UPDATED') {
        try {
          final orderId = eventData['order_id'] as int?;
          final status = eventData['status'] as String?;
          final currentActive = activeOrderNotifier.value;

          if (orderId != null && status != null && currentActive != null) {
            if (currentActive.orderId == orderId) {
              // Create updated order item
              final updatedOrder = OrderHistoryItem(
                orderId: currentActive.orderId,
                hotelName: currentActive.hotelName,
                status: status,
                grandTotal: currentActive.grandTotal,
                walletDeducted: currentActive.walletDeducted,
                itemCount: currentActive.itemCount,
                createdAt: currentActive.createdAt,
              );

              // Update the notifier
              if (status == 'completed' ||
                  status == 'rejected' ||
                  status == 'cancelled') {
                // Keep it briefly or clear immediately. Let's clear it so the floating widget closes.
                activeOrderNotifier.value = null;
              } else {
                activeOrderNotifier.value = updatedOrder;
              }
            }
          }
        } catch (e) {
          debugPrint('Error updating active order in tracker: $e');
        }
      }
    });
  }

  void dispose() {
    _wsSubscription?.cancel();
  }
}
