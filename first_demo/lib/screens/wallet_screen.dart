// lib/screens/wallet_screen.dart
import 'package:flutter/material.dart';
import '../models/wallet.dart';
import '../services/wallet_service.dart';

class WalletScreen extends StatefulWidget {
  /// Optionally pass current balance so the hero card shows immediately
  final double? initialBalance;
  final VoidCallback? onBalanceChanged;

  const WalletScreen({
    super.key,
    this.initialBalance,
    this.onBalanceChanged,
  });

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  static const _coral = Color(0xFFF07070);
  static const _green = Color(0xFF1DA462);
  static const _pageBg = Color(0xFFF9FAFB);
  static const _textDark = Color(0xFF1A1A2E);
  static const _textGrey = Color(0xFF6B7280);

  double _balance = 0;
  bool _isLoading = true;
  bool _isRecharging = false;
  List<WalletTransaction> _transactions = [];
  bool _loadingTx = true;

  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  static const _quickAmounts = [100.0, 500.0, 1000.0, 2000.0];

  @override
  void initState() {
    super.initState();
    if (widget.initialBalance != null) {
      _balance = widget.initialBalance!;
      _isLoading = false;
    }
    _fetchBalance();
    _fetchTransactions();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _fetchBalance() async {
    try {
      final wallet = await WalletService.instance.getBalance();
      if (mounted) {
        setState(() {
          _balance = wallet.balance;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchTransactions() async {
    try {
      final txs = await WalletService.instance.getTransactions();
      if (mounted) {
        setState(() {
          _transactions = txs;
          _loadingTx = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingTx = false);
    }
  }

  Future<void> _recharge(double amount) async {
    if (amount <= 0) return;
    setState(() => _isRecharging = true);
    try {
      final result = await WalletService.instance.recharge(amount);
      if (mounted) {
        setState(() {
          _balance = result.balance;
          _isRecharging = false;
          _amountController.clear();
        });
        widget.onBalanceChanged?.call();
        _fetchTransactions();
        _showSnack('₹${amount.toStringAsFixed(0)} added to wallet! 🎉', _green);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRecharging = false);
        _showSnack(e.toString(), Colors.red);
      }
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _pageBg,
        elevation: 0,
        title: const Text(
          'My Wallet',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: _textDark,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchBalance();
          await _fetchTransactions();
        },
        color: _coral,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBalanceCard(),
              const SizedBox(height: 24),
              _buildRechargeSection(),
              const SizedBox(height: 24),
              _buildTransactionHistory(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ── Balance Hero Card ──────────────────────────────────────────────────────

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF07070), Color(0xFFE05555)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _coral.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'ZenQube Wallet',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Available Balance',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          _isLoading
              ? const SizedBox(
                  height: 44,
                  width: 44,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  '₹${_balance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
          const SizedBox(height: 4),
          Text(
            'Secure • Instant • No Expiry',
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ── Recharge Section ────────────────────────────────────────────────────────

  Widget _buildRechargeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Money',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 14),

          // Quick amount chips
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _quickAmounts.map((amt) {
              return GestureDetector(
                onTap: () => _recharge(amt),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: _coral.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _coral.withOpacity(0.3)),
                  ),
                  child: Text(
                    '+ ₹${amt.toInt()}',
                    style: const TextStyle(
                      color: _coral,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // Custom amount input
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Custom amount',
                    hintText: 'Enter amount (₹)',
                    prefixIcon: Icon(Icons.currency_rupee_rounded),
                  ),
                  validator: (v) {
                    final amt = double.tryParse(v ?? '');
                    if (amt == null || amt <= 0) return 'Enter a valid amount';
                    if (amt > 50000) return 'Maximum ₹50,000 per transaction';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isRecharging
                        ? null
                        : () {
                            if (_formKey.currentState!.validate()) {
                              _recharge(double.parse(
                                  _amountController.text.trim()));
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _coral,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isRecharging
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text(
                            'Add Money',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Transaction History ─────────────────────────────────────────────────────

  Widget _buildTransactionHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transaction History',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 14),
        if (_loadingTx)
          const Center(
              child: CircularProgressIndicator(color: _coral))
        else if (_transactions.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.receipt_long_rounded,
                    size: 48, color: _textGrey.withOpacity(0.4)),
                const SizedBox(height: 12),
                Text(
                  'No transactions yet',
                  style: TextStyle(
                      color: _textGrey, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _transactions.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 70),
              itemBuilder: (context, index) {
                final tx = _transactions[index];
                final isCredit = tx.isCredit;
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isCredit
                          ? _green.withOpacity(0.1)
                          : _coral.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isCredit
                          ? Icons.add_circle_outline_rounded
                          : Icons.remove_circle_outline_rounded,
                      color: isCredit ? _green : _coral,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    tx.description,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      color: _textDark,
                    ),
                  ),
                  subtitle: Text(
                    _formatDate(tx.createdAt),
                    style:
                        const TextStyle(fontSize: 11.5, color: _textGrey),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isCredit ? '+' : '-'} ₹${tx.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: isCredit ? _green : _coral,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Bal: ₹${tx.balanceAfter.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 10.5, color: _textGrey),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final amPm = dt.hour < 12 ? 'AM' : 'PM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}  •  $hour:$min $amPm';
  }
}
