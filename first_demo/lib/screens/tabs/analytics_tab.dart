// lib/screens/tabs/analytics_tab.dart
import 'package:flutter/material.dart';
import '../../services/wallet_service.dart';
import '../../models/wallet.dart';
import '../hotels_near_you_screen.dart';

class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  // ── Design Tokens matching reference photo 100% ────────────────────────────
  static const Color _brandOrange  = Color(0xFFF58220);
  static const Color _gradientEnd  = Color(0xFFE65100);
  static const Color _bgWarm       = Color(0xFFF6F8FA);
  static const Color _white        = Colors.white;
  static const Color _ink          = Color(0xFF1A1A2E);
  static const Color _greySub      = Color(0xFF6B7280);
  static const Color _cardBorder   = Color(0xFFF3F4F6);
  static const Color _greenText    = Color(0xFF10B981);
  static const Color _greenBg      = Color(0xFFE6F4EA);

  List<WalletTransaction> _walletTransactions = [];
  bool _isLoading = true;
  String _selectedFilter = 'This Week';

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
    WalletService.instance.transactionNotifier.addListener(_onTransactionUpdate);
  }

  @override
  void dispose() {
    WalletService.instance.transactionNotifier.removeListener(_onTransactionUpdate);
    super.dispose();
  }

  void _onTransactionUpdate() {
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final txs = await WalletService.instance.getTransactions();
      if (mounted) {
        setState(() {
          _walletTransactions = txs;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
      return '$month ${dt.day}, $hour:$min $ampm';
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isWide = mq.size.width > 600;

    return Scaffold(
      backgroundColor: _bgWarm,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandOrange))
          : SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isWide ? 540 : double.infinity),
                  child: Stack(
                    children: [
                      // ── 1. Top Orange Header Banner with Custom Organic S-Wave Curve ───
                      ClipPath(
                        clipper: HeaderCurveClipper(),
                        child: Container(
                          height: 165,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_brandOrange, _gradientEnd],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),

                      // ── 2. Header Top Bar Content (Ledger Title & Filter Pill) ────────
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left: Clipboard Icon & Title Stack
                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: _white.withOpacity(0.22),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(
                                        Icons.assignment_outlined,
                                        color: _white,
                                        size: 26,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Text(
                                            'Ledger',
                                            style: TextStyle(
                                              color: _white,
                                              fontSize: 26,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: -0.4,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            'Track your token usage and transactions',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w500,
                                              height: 1.15,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Right: "This Week ˅" Pill Dropdown
                              PopupMenuButton<String>(
                                initialValue: _selectedFilter,
                                onSelected: (val) => setState(() => _selectedFilter = val),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                itemBuilder: (ctx) => const [
                                  PopupMenuItem(value: 'This Week', child: Text('This Week')),
                                  PopupMenuItem(value: 'This Month', child: Text('This Month')),
                                  PopupMenuItem(value: 'All Time', child: Text('All Time')),
                                ],
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: _white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.calendar_today_rounded, color: _brandOrange, size: 14),
                                      const SizedBox(width: 6),
                                      Text(
                                        _selectedFilter,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: _ink,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.keyboard_arrow_down_rounded, color: _brandOrange, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── 3. Main Content Stack ────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.only(top: 155, left: 16, right: 16, bottom: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // "Recent Transactions" Section Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Recent Transactions',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: _ink,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {},
                                  child: Row(
                                    children: const [
                                      Text(
                                        'See All',
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                          color: _brandOrange,
                                        ),
                                      ),
                                      SizedBox(width: 2),
                                      Icon(Icons.chevron_right_rounded, color: _brandOrange, size: 16),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // ── 4. Transaction Cards List ────────────────────────────────
                            if (_walletTransactions.isNotEmpty)
                              ..._walletTransactions.map((tx) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildTransactionCard(
                                      title: tx.description,
                                      balanceAfter: tx.balanceAfter,
                                      timeStr: _formatDate(tx.createdAt),
                                      amount: tx.amount,
                                      isCredit: tx.isCredit,
                                    ),
                                  ))
                            else
                              Container(
                                padding: const EdgeInsets.all(24),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFF3F4F6)),
                                ),
                                child: const Column(
                                  children: [
                                    Icon(Icons.receipt_long_rounded, size: 40, color: Color(0xFF9CA3AF)),
                                    SizedBox(height: 8),
                                    Text(
                                      'No transactions yet',
                                      style: TextStyle(
                                        color: Color(0xFF6B7280),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 18),

                            // ── 5. Bottom "Enjoy hassle-free dining!" Banner ───────────────
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF5F0),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFFFE8DD), width: 1.2),
                              ),
                              child: Row(
                                children: [
                                  // Left Vibrant Orange Flatware Circle Badge
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: const BoxDecoration(
                                      color: _brandOrange,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.flatware_rounded, color: _white, size: 24),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Center Text Column
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: const [
                                        Text(
                                          'Enjoy hassle-free dining!',
                                          style: TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w900,
                                            color: _ink,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Use your tokens to order delicious meals from your favorite restaurants.',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: _greySub,
                                            fontWeight: FontWeight.w500,
                                            height: 1.18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Right Outline Pill Button: Browse Messes >
                                  GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const HotelsNearYouScreen()),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: _white,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(color: _brandOrange, width: 1.2),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Text(
                                            'Browse Messes',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w900,
                                              color: _brandOrange,
                                            ),
                                          ),
                                          SizedBox(width: 3),
                                          Icon(Icons.chevron_right_rounded, color: _brandOrange, size: 16),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // ── Helper: Transaction Card Widget ────────────────────────────────────────
  Widget _buildTransactionCard({
    required String title,
    required double balanceAfter,
    required String timeStr,
    required double amount,
    required bool isCredit,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Icon Box (Soft Mint Green Circle with Wallet Icon)
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: _greenBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Icons.account_balance_wallet_outlined : Icons.receipt_long_rounded,
              color: _greenText,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // Title & Subtitle Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Balance after: ₹${balanceAfter.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _greySub,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, color: _greySub, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      timeStr,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: _greySub,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Price & Status Badge Column
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '-'}₹${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: _greenText,
                ),
              ),
              const SizedBox(height: 6),

              // Mint Green "Success" Tag Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                decoration: BoxDecoration(
                  color: _greenBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Success',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _greenText,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Clipper for Header Orange Background Curve
// ─────────────────────────────────────────────────────────────────────────────

class HeaderCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 30);

    path.cubicTo(
      size.width * 0.35, size.height + 30,
      size.width * 0.65, size.height - 60,
      size.width, size.height - 40,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}
