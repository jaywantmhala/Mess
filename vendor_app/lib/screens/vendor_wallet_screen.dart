import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'bank_details_screen.dart';
import '../services/vendor_wallet_service.dart';
import '../services/websocket_service.dart';
import '../theme/app_theme.dart';

class VendorWalletScreen extends StatefulWidget {
  const VendorWalletScreen({super.key});

  @override
  State<VendorWalletScreen> createState() => _VendorWalletScreenState();
}

class _VendorWalletScreenState extends State<VendorWalletScreen> {
  VendorWalletInfo? _walletInfo;
  bool _isLoadingBalance = true;
  List<VendorWalletTransaction> _transactions = [];
  List<VendorPayoutItem> _payouts = [];
  bool _isLoadingTx = true;
  StreamSubscription? _wsSubscription;
  Timer? _webRefreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _startAblyListener();
    if (kIsWeb) {
      _webRefreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        _fetchWalletInfo();
      });
    }
  }

  String _formatCharge(double val) {
    if (val == val.roundToDouble()) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(2);
  }

  void _startAblyListener() {
    _wsSubscription = WebSocketService.instance.messages.listen((msg) {
      final event = msg['event'] as String?;
      final data = msg['data'];

      if (event == 'VENDOR_WALLET_UPDATED') {
        _handleRealtimeOrderCompletion(data);
      } else if (event == 'ORDER_STATUS_UPDATED') {
        final status = (data is Map ? data['status'] : null)?.toString();
        if (status == 'completed') {
          _handleRealtimeOrderCompletion(data);
        }
      }
    });
  }

  void _handleRealtimeOrderCompletion([dynamic eventData]) {
    if (!mounted) return;
    setState(() {
      if (_walletInfo != null) {
        double credit = _walletInfo!.areaTiffinCharge;
        if (eventData is Map && eventData['credit_amount'] != null) {
          credit = double.tryParse(eventData['credit_amount'].toString()) ?? credit;
        }
        final newBal = _walletInfo!.balance + credit;
        final newToday = _walletInfo!.todayEarnings + credit;
        final newTodayOrders = _walletInfo!.todayOrdersCount + 1;
        _walletInfo = VendorWalletInfo(
          balance: newBal,
          todayEarnings: newToday,
          todayOrdersCount: newTodayOrders,
          dailyBreakdown: _walletInfo!.dailyBreakdown,
          areaTiffinCharge: _walletInfo!.areaTiffinCharge,
          areaName: _walletInfo!.areaName,
        );
      }
    });

    // Silent background fetch
    _fetchWalletInfo();
    _fetchTransactions();
    _fetchPayouts();
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _webRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    _fetchWalletInfo();
    _fetchTransactions();
    _fetchPayouts();
  }

  Future<void> _fetchWalletInfo() async {
    try {
      final info = await VendorWalletService.instance.getWalletInfo();
      if (mounted) {
        setState(() {
          _walletInfo = info;
          _isLoadingBalance = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingBalance = false);
    }
  }

  Future<void> _fetchTransactions() async {
    try {
      final txs = await VendorWalletService.instance.getTransactions();
      if (mounted) {
        setState(() {
          _transactions = txs;
          _isLoadingTx = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingTx = false);
    }
  }

  Future<void> _fetchPayouts() async {
    try {
      final list = await VendorWalletService.instance.getPayoutHistory();
      if (mounted) {
        setState(() {
          _payouts = list;
        });
      }
    } catch (_) {}
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0 && now.day == dt.day) {
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute < 10 ? '0${dt.minute}' : '${dt.minute}';
      return 'Today, $hour:$min $ampm';
    } else if (diff.inDays == 1 || (now.day - dt.day == 1 && diff.inDays < 2)) {
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute < 10 ? '0${dt.minute}' : '${dt.minute}';
      return 'Yesterday, $hour:$min $ampm';
    } else {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final month = months[dt.month - 1];
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute < 10 ? '0${dt.minute}' : '${dt.minute}';
      return '${dt.day} $month, $hour:$min $ampm';
    }
  }

  String _formatDayLabel(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      final now = DateTime.now();
      if (now.year == dt.year && now.month == dt.month && now.day == dt.day) {
        return 'Today';
      }
      final yesterday = now.subtract(const Duration(days: 1));
      if (yesterday.year == dt.year && yesterday.month == dt.month && yesterday.day == dt.day) {
        return 'Yesterday';
      }
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month - 1]}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayEarnings = _walletInfo?.todayEarnings ?? 0.0;
    final todayOrders = _walletInfo?.todayOrdersCount ?? 0;
    final totalBalance = _walletInfo?.balance ?? 0.0;
    final dailyBreakdown = _walletInfo?.dailyBreakdown ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.ink, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Vendor Wallet',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_outlined, color: AppColors.ink),
            tooltip: 'Bank Account Details',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BankDetailsScreen()),
              );
            },
          ),
        ],
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Earnings & Balance Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_rounded,
                                color: Color(0xFF10B981),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Vendor Wallet',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            '₹${_formatCharge(_walletInfo?.areaTiffinCharge ?? 50.0)}/order',
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 2-Column Row: Today's Earnings vs Total Balance
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "TODAY'S EARNINGS",
                                style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _isLoadingBalance
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(
                                      '₹${todayEarnings.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                              const SizedBox(height: 2),
                              Text(
                                '$todayOrders orders delivered today\n(Auto-settled daily via PayU)',
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 48, color: Colors.white24),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TOTAL BALANCE',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _isLoadingBalance
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(
                                      '₹${totalBalance.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                              const SizedBox(height: 2),
                              const Text(
                                'Accumulated savings',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Daily Earnings Breakdown Section
              if (dailyBreakdown.isNotEmpty) ...[
                const Text(
                  'Daily Earnings Breakdown',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    itemCount: dailyBreakdown.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final item = dailyBreakdown[index];
                      final isToday = index == 0;
                      return Container(
                        width: 130,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isToday ? const Color(0xFFECFDF5) : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isToday ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
                            width: isToday ? 1.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _formatDayLabel(item.date),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isToday ? const Color(0xFF059669) : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '₹${item.dailyTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.ordersCount} orders delivered',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Transaction Ledger Section
              const Text(
                'Recent Orders Credited',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 14),

              if (_isLoadingTx)
                const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))
              else if (_transactions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.receipt_long_rounded, size: 48, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 12),
                      const Text(
                        'No earnings recorded yet',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${_formatCharge(_walletInfo?.areaTiffinCharge ?? 50.0)} will be credited here automatically on a daily basis as orders get delivered.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _transactions.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final tx = _transactions[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.add_task_rounded,
                              color: Color(0xFF10B981),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx.description,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDate(tx.createdAt),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '+₹${tx.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Bal: ₹${tx.balanceAfter.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

              // Payout Settlement History Section (Always Visible)
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bank Settlement Payouts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BankDetailsScreen()),
                      );
                    },
                    icon: const Icon(Icons.account_balance_rounded, size: 16, color: AppColors.primary),
                    label: const Text(
                      'Bank Account',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (_payouts.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.account_balance_outlined, size: 44, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 12),
                      const Text(
                        'No bank settlements initiated yet',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Automatic payouts via PayU will appear here as soon as daily settlements are processed to your bank account.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const BankDetailsScreen()),
                          );
                        },
                        icon: const Icon(Icons.edit_note_rounded, size: 18),
                        label: const Text('Setup / View Bank Details'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _payouts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final po = _payouts[index];
                    final isSuccess = po.status == 'SUCCESS';
                    final isFailed  = po.status == 'FAILED';
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSuccess
                                  ? const Color(0xFFECFDF5)
                                  : (isFailed ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB)),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              isSuccess
                                  ? Icons.account_balance_rounded
                                  : (isFailed ? Icons.error_outline_rounded : Icons.hourglass_empty_rounded),
                              color: isSuccess
                                  ? const Color(0xFF10B981)
                                  : (isFailed ? const Color(0xFFEF4444) : const Color(0xFFD97706)),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Payout to Bank (••• ${po.bankAccountLast4})',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Ref: ${po.payuReference}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '-₹${po.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: isSuccess ? const Color(0xFF059669) : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isSuccess
                                      ? const Color(0xFFDCFCE7)
                                      : (isFailed ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7)),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  po.status,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: isSuccess
                                        ? const Color(0xFF166534)
                                        : (isFailed ? const Color(0xFF991B1B) : const Color(0xFF92400E)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
