// lib/screens/checkout_screen.dart
import 'package:flutter/material.dart';
import '../models/cart.dart';
import '../models/order.dart';
import '../models/wallet.dart';
import '../services/wallet_service.dart';
import '../services/order_service.dart';
import '../services/address_service.dart';
import '../services/active_order_service.dart';

class CheckoutScreen extends StatefulWidget {
  final CartSummary cart;
  final VoidCallback? onOrderPlaced;

  const CheckoutScreen({
    super.key,
    required this.cart,
    this.onOrderPlaced,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const _coral = Color(0xFFF07070);
  static const _green = Color(0xFF1DA462);
  static const _amber = Color(0xFFFFB300);
  static const _pageBg = Color(0xFFF9FAFB);
  static const _textDark = Color(0xFF1A1A2E);
  static const _textGrey = Color(0xFF6B7280);
  static const _divider = Color(0xFFE5E7EB);

  WalletBalance? _wallet;
  bool _isLoadingWallet = true;
  bool _isPlacingOrder = false;

  String _selectedPayment = 'COD'; // 'COD' | 'UPI'
  String _deliveryAddress = 'Fetching address...';

  @override
  void initState() {
    super.initState();
    _fetchWallet();
    _loadAddress();
  }

  Future<void> _fetchWallet() async {
    try {
      final w = await WalletService.instance.getBalance();
      if (mounted) setState(() { _wallet = w; _isLoadingWallet = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoadingWallet = false);
    }
  }

  Future<void> _loadAddress() async {
    try {
      final addr = await AddressService.instance.getAddress();
      if (mounted && addr != null) {
        setState(() => _deliveryAddress = addr.fullAddress);
      } else if (mounted) {
        setState(() => _deliveryAddress = 'No address saved');
      }
    } catch (_) {
      if (mounted) setState(() => _deliveryAddress = 'No address saved');
    }
  }

  // ── Math helpers ─────────────────────────────────────────────────────────────

  double get _walletBalance => _wallet?.balance ?? 0;
  double get _grandTotal => widget.cart.grandTotal;

  double get _walletDeduction {
    if (_walletBalance <= 0) return 0;
    return _walletBalance >= _grandTotal ? _grandTotal : _walletBalance;
  }

  double get _remainingPayable => (_grandTotal - _walletDeduction).clamp(0, double.infinity);

  bool get _fullyPaidByWallet => _remainingPayable <= 0;

  // ── Place order ──────────────────────────────────────────────────────────────

  Future<void> _placeOrder() async {
    setState(() => _isPlacingOrder = true);
    try {
      final result = await OrderService.instance.placeOrder(
        paymentMethod: _fullyPaidByWallet ? 'WALLET' : _selectedPayment,
        deliveryAddress: _deliveryAddress,
      );
      if (mounted) {
        setState(() => _isPlacingOrder = false);
        WalletService.instance.balanceNotifier.value = result.newWalletBalance;

        // Track the order globally in ActiveOrderService
        final orderItem = OrderHistoryItem(
          orderId: result.orderId,
          hotelName: widget.cart.hotel?.name ?? 'Hotel',
          status: result.status,
          grandTotal: result.grandTotal,
          walletDeducted: result.walletDeducted,
          itemCount: widget.cart.totalQuantity,
          createdAt: DateTime.now(),
        );
        ActiveOrderService.instance.trackOrder(orderItem);

        await _showSuccessDialog(result);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _showSuccessDialog(OrderResult result) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: _green, size: 44),
              ),
              const SizedBox(height: 20),
              const Text(
                'Order Placed! 🎉',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Order #${result.orderId}',
                style: const TextStyle(fontSize: 13, color: _textGrey),
              ),
              const SizedBox(height: 20),
              _receiptRow('Order Total',
                  '₹${result.grandTotal.toStringAsFixed(2)}'),
              if (result.walletDeducted > 0) ...[
                const SizedBox(height: 8),
                _receiptRow(
                  'Wallet Paid',
                  '- ₹${result.walletDeducted.toStringAsFixed(2)}',
                  valueColor: _green,
                ),
              ],
              if (result.remainingPayable > 0) ...[
                const SizedBox(height: 8),
                _receiptRow(
                  'To Pay (${_selectedPayment})',
                  '₹${result.remainingPayable.toStringAsFixed(2)}',
                  valueColor: _coral,
                ),
              ],
              const SizedBox(height: 8),
              _receiptRow(
                'New Wallet Balance',
                '₹${result.newWalletBalance.toStringAsFixed(2)}',
                valueColor: _textDark,
                bold: true,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    widget.onOrderPlaced?.call();
                  },
                  child: const Text('Track Order',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value,
      {Color? valueColor, bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: _textGrey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ?? _textDark,
          ),
        ),
      ],
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: _textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
              fontSize: 19, fontWeight: FontWeight.w800, color: _textDark),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDeliveryAddress(),
            const SizedBox(height: 16),
            _buildOrderItems(),
            const SizedBox(height: 16),
            _buildPaymentSummary(),
            const SizedBox(height: 16),
            _buildWalletSection(),
            if (!_fullyPaidByWallet && _remainingPayable > 0) ...[
              const SizedBox(height: 16),
              _buildPaymentMethod(),
            ],
            const SizedBox(height: 16),
            _buildGrandTotalCard(),
          ],
        ),
      ),
      bottomNavigationBar: _buildPlaceOrderBar(),
    );
  }

  // ── Delivery Address ──────────────────────────────────────────────────────────

  Widget _buildDeliveryAddress() {
    return _card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: _coral.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.location_on_rounded,
                color: _coral, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Delivery Address',
                    style: TextStyle(
                        fontSize: 12,
                        color: _textGrey,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  _deliveryAddress,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Order Items ───────────────────────────────────────────────────────────────

  Widget _buildOrderItems() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.cart.hotel != null)
            Text(
              widget.cart.hotel!.name,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _textGrey),
            ),
          if (widget.cart.hotel != null) const SizedBox(height: 10),
          ...widget.cart.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: item.isVeg
                                ? const Color(0xFF118C4F)
                                : Colors.red,
                            width: 1.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: item.isVeg
                              ? const Color(0xFF118C4F)
                              : Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(item.name,
                          style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: _textDark)),
                    ),
                    Text('x${item.quantity}',
                        style: const TextStyle(
                            fontSize: 13, color: _textGrey)),
                    const SizedBox(width: 10),
                    Text('₹${item.subtotal.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: _textDark)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ── Payment Summary ───────────────────────────────────────────────────────────

  Widget _buildPaymentSummary() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Summary',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800, color: _textDark)),
          const SizedBox(height: 12),
          _summaryRow('Item Total',
              '₹${widget.cart.subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _summaryRow('Delivery Fee',
              '₹${widget.cart.deliveryFee.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _summaryRow(
              'Taxes', '₹${widget.cart.taxAmount.toStringAsFixed(2)}'),
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1)),
          _summaryRow('Order Total', '₹${_grandTotal.toStringAsFixed(2)}',
              bold: true),
        ],
      ),
    );
  }

  // ── Wallet Section ────────────────────────────────────────────────────────────

  Widget _buildWalletSection() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded,
                  color: _coral, size: 20),
              const SizedBox(width: 10),
              const Text('ZenQube Wallet',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _textDark)),
              const Spacer(),
              if (_isLoadingWallet)
                const SizedBox(
                    width: 16,
                    height: 16,
                    child:
                        CircularProgressIndicator(strokeWidth: 2, color: _coral))
              else
                Text(
                  '₹${_walletBalance.toStringAsFixed(2)} available',
                  style: const TextStyle(
                      fontSize: 13, color: _green, fontWeight: FontWeight.w700),
                ),
            ],
          ),
          if (!_isLoadingWallet) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _walletDeduction > 0
                    ? _green.withOpacity(0.06)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: _walletDeduction > 0
                        ? _green.withOpacity(0.3)
                        : _divider),
              ),
              child: Row(
                children: [
                  Icon(
                    _walletDeduction > 0
                        ? Icons.check_circle_rounded
                        : Icons.info_outline_rounded,
                    color: _walletDeduction > 0 ? _green : _textGrey,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _walletDeduction > 0
                          ? '₹${_walletDeduction.toStringAsFixed(2)} will be deducted from wallet'
                          : 'Wallet balance is ₹0. No wallet deduction.',
                      style: TextStyle(
                        fontSize: 13,
                        color: _walletDeduction > 0 ? _green : _textGrey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_walletDeduction > 0 && _remainingPayable > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _amber.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _amber.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wallet_rounded,
                        color: _amber, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'Remaining ₹${_remainingPayable.toStringAsFixed(2)} via ${_selectedPayment}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: _amber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ── Payment Method ────────────────────────────────────────────────────────────

  Widget _buildPaymentMethod() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Payment Method',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800, color: _textDark)),
          const SizedBox(height: 12),
          _paymentOption('COD', Icons.money_rounded, 'Cash on Delivery'),
          const Divider(height: 1),
          _paymentOption('UPI', Icons.payment_rounded, 'UPI / Online Payment'),
        ],
      ),
    );
  }

  Widget _paymentOption(String value, IconData icon, String label) {
    final isSelected = _selectedPayment == value;
    return InkWell(
      onTap: () => setState(() => _selectedPayment = value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected ? _coral : _textGrey, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? _textDark : _textGrey,
                ),
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _selectedPayment,
              activeColor: _coral,
              onChanged: (v) => setState(() => _selectedPayment = v!),
            ),
          ],
        ),
      ),
    );
  }

  // ── Grand Total Card ──────────────────────────────────────────────────────────

  Widget _buildGrandTotalCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_textDark, const Color(0xFF2D2D3E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _darkRow('Order Total', '₹${_grandTotal.toStringAsFixed(2)}'),
          if (_walletDeduction > 0) ...[
            const SizedBox(height: 8),
            _darkRow(
              'Wallet Deduction',
              '- ₹${_walletDeduction.toStringAsFixed(2)}',
              valueColor: _green,
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Colors.white12),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('You Pay',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              Text(
                '₹${_remainingPayable.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          if (_fullyPaidByWallet) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: _green, size: 16),
                const SizedBox(width: 6),
                const Text(
                  'Fully paid via Wallet — No extra payment needed!',
                  style: TextStyle(color: _green, fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _darkRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.6), fontSize: 13)),
        Text(value,
            style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700)),
      ],
    );
  }

  // ── Place Order Bar ───────────────────────────────────────────────────────────

  Widget _buildPlaceOrderBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          height: 56,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isPlacingOrder ? null : _placeOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              disabledBackgroundColor: _green.withOpacity(0.6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _isPlacingOrder
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_bag_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        _fullyPaidByWallet
                            ? 'Place Order (Wallet)'
                            : 'Place Order • ₹${_remainingPayable.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: child,
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13.5, color: _textGrey)),
        Text(value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: _textDark,
            )),
      ],
    );
  }
}
