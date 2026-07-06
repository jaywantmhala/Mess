// lib/models/wallet.dart

class WalletBalance {
  final int walletId;
  final int customerId;
  final double balance;

  const WalletBalance({
    required this.walletId,
    required this.customerId,
    required this.balance,
  });

  factory WalletBalance.fromJson(Map<String, dynamic> json) => WalletBalance(
        walletId: int.parse(json['wallet_id'].toString()),
        customerId: int.parse(json['customer_id'].toString()),
        balance: double.parse(json['balance'].toString()),
      );

  WalletBalance copyWith({double? balance}) => WalletBalance(
        walletId: walletId,
        customerId: customerId,
        balance: balance ?? this.balance,
      );
}

class WalletTransaction {
  final int id;
  final String type; // 'CREDIT' or 'DEBIT'
  final double amount;
  final String description;
  final double balanceAfter;
  final DateTime createdAt;

  const WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.balanceAfter,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) =>
      WalletTransaction(
        id: int.parse(json['id'].toString()),
        type: json['type'] as String,
        amount: double.parse(json['amount'].toString()),
        description: json['description'] as String? ?? '',
        balanceAfter: double.parse(json['balance_after'].toString()),
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );

  bool get isCredit => type == 'CREDIT';
}
