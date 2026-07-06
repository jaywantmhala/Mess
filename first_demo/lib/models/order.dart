// lib/models/order.dart

class OrderResult {
  final int orderId;
  final double grandTotal;
  final double walletDeducted;
  final double remainingPayable;
  final double newWalletBalance;
  final String status;

  const OrderResult({
    required this.orderId,
    required this.grandTotal,
    required this.walletDeducted,
    required this.remainingPayable,
    required this.newWalletBalance,
    required this.status,
  });

  factory OrderResult.fromJson(Map<String, dynamic> json) => OrderResult(
        orderId: int.parse(json['order_id'].toString()),
        grandTotal: double.parse(json['grand_total'].toString()),
        walletDeducted: double.parse(json['wallet_deducted'].toString()),
        remainingPayable: double.parse(json['remaining_payable'].toString()),
        newWalletBalance: double.parse(json['new_wallet_balance'].toString()),
        status: json['status'] as String? ?? 'PLACED',
      );
}

class OrderHistoryItem {
  final int orderId;
  final String hotelName;
  final String status;
  final double grandTotal;
  final double walletDeducted;
  final int itemCount;
  final DateTime createdAt;

  const OrderHistoryItem({
    required this.orderId,
    required this.hotelName,
    required this.status,
    required this.grandTotal,
    required this.walletDeducted,
    required this.itemCount,
    required this.createdAt,
  });

  factory OrderHistoryItem.fromJson(Map<String, dynamic> json) =>
      OrderHistoryItem(
        orderId: int.parse(json['order_id'].toString()),
        hotelName: json['hotel_name'] as String? ?? 'Unknown',
        status: json['status'] as String? ?? 'PLACED',
        grandTotal: double.parse(json['grand_total'].toString()),
        walletDeducted: double.parse(json['wallet_deducted'].toString()),
        itemCount: int.parse(json['item_count'].toString()),
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}
