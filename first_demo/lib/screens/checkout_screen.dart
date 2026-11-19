import 'dart:async';
import 'package:flutter/material.dart';
import '../models/cart.dart';
import '../models/order.dart';
import '../models/wallet.dart';
import '../services/wallet_service.dart';
import '../services/order_service.dart';
import '../services/address_service.dart';
import '../services/active_order_service.dart';
import '../services/payment_service.dart';
import '../services/payu_service.dart';
import '../models/address_data.dart';
import 'saved_addresses_screen.dart';
import 'order_success_screen.dart';

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
    PaymentService.instance.init();
    _fetchWallet();
    _loadAddress();
  }

  @override
  void dispose() {
    PaymentService.instance.dispose();
    super.dispose();
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
        final tagEmoji = (addr.tag == 'OFFICE' || addr.tag == 'WORK') ? '🏢' : ((addr.tag == 'HOME') ? '🏠' : '📍');
        final tagText = addr.tag[0].toUpperCase() + addr.tag.substring(1).toLowerCase();
        final parts = <String>[];
        if (addr.houseNo.isNotEmpty) parts.add(addr.houseNo);
        if (addr.fullAddress.isNotEmpty) parts.add(addr.fullAddress);
        if (addr.landmark.isNotEmpty) parts.add('Landmark: ${addr.landmark}');

        setState(() {
          _deliveryAddress = '$tagEmoji $tagText: ${parts.join(', ')}';
        });
      } else if (mounted) {
        setState(() => _deliveryAddress = 'No address saved');
      }
    } catch (_) {
      if (mounted) setState(() => _deliveryAddress = 'No address saved');
    }
  }

  Future<void> _onChangeAddress() async {
    final selected = await Navigator.push<AddressData>(
      context,
      MaterialPageRoute(builder: (_) => const SavedAddressesScreen()),
    );
    if (selected != null) {
      final tagEmoji = (selected.tag == 'OFFICE' || selected.tag == 'WORK') ? '🏢' : ((selected.tag == 'HOME') ? '🏠' : '📍');
      final tagText = selected.tag[0].toUpperCase() + selected.tag.substring(1).toLowerCase();
      final parts = <String>[];
      if (selected.houseNo.isNotEmpty) parts.add(selected.houseNo);
      if (selected.fullAddress.isNotEmpty) parts.add(selected.fullAddress);
      if (selected.landmark.isNotEmpty) parts.add('Landmark: ${selected.landmark}');

      setState(() {
        _deliveryAddress = '$tagEmoji $tagText: ${parts.join(', ')}';
      });
    } else {
      _loadAddress();
    }
  }

  // ── Math helpers ─────────────────────────────────────────────────────────────

  double get _walletBalance => _wallet?.balance ?? 0;

  double get _tiffinCharge => widget.cart.tiffinCharge > 0 ? widget.cart.tiffinCharge : 50.0;

  double get _grandTotal => widget.cart.grandTotal > 0
      ? widget.cart.grandTotal
      : (widget.cart.subtotal + _tiffinCharge + widget.cart.deliveryFee + widget.cart.taxAmount);

  double get _walletDeduction {
    if (_walletBalance <= 0) return 0;
    return _walletBalance >= _tiffinCharge ? _tiffinCharge : _walletBalance;
  }

  double get _remainingPayable => (_grandTotal - _walletDeduction).clamp(0, double.infinity);

  bool get _fullyPaidByWallet => _remainingPayable <= 0;

  // ── Place order ──────────────────────────────────────────────────────────────

  Future<void> _placeOrder() async {
    if (_walletBalance < _tiffinCharge) {
      final areaSuffix = (widget.cart.areaName != null && widget.cart.areaName!.isNotEmpty) ? " (${widget.cart.areaName} Tiffin Charge)" : "";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Insufficient wallet balance. Minimum ₹${_tiffinCharge.toStringAsFixed(0)}$areaSuffix required in wallet to place an order."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (_selectedPayment == 'UPI' && !_fullyPaidByWallet && _remainingPayable > 0) {
      await _startPayUUpiPayment();
    } else {
      await _executeOrderPlacement();
    }
  }

  Future<void> _startPayUUpiPayment() async {
    setState(() => _isPlacingOrder = true);
    try {
      final orderResult = await PayUService.instance.createOrder(1);
      final options = PayUService.instance.buildCheckoutOptions(
        orderId: orderResult.orderId ?? 'order_ord_${DateTime.now().millisecondsSinceEpoch}',
        keyId: orderResult.keyId ?? PayUService.payuMerchantKey,
        amountPaise: (_remainingPayable * 100).toInt(),
        planName: 'Food Delivery Order',
        customerName: orderResult.customerName,
        customerEmail: orderResult.customerEmail,
        customerPhone: orderResult.customerPhone,
        hash: orderResult.hash,
        action: orderResult.action,
        surl: orderResult.surl,
        furl: orderResult.furl,
        udf1: orderResult.udf1,
        udf2: orderResult.udf2,
      );

      await PaymentService.instance.openCheckout(
        options: options,
        onSuccess: (verifyResult) {
          if (mounted) {
            setState(() => _isPlacingOrder = false);
            _executeOrderPlacement();
          }
        },
        onError: (errorMsg) {
          if (!mounted) return;
          setState(() => _isPlacingOrder = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg.contains('cancelled') ? 'Payment cancelled.' : 'Payment failed: $errorMsg'),
              backgroundColor: Colors.red,
            ),
          );
        },
        onCancelled: () {
          if (!mounted) return;
          setState(() => _isPlacingOrder = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment cancelled.'), backgroundColor: Colors.red),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPlacingOrder = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initiating PayU payment: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _executeOrderPlacement() async {
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
          hotelName: widget.cart.hotel?.name ?? 'Mess',
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _showSuccessDialog(OrderResult result) async {
    if (!mounted) return;
    widget.onOrderPlaced?.call();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => OrderSuccessScreen(
          orderId: result.orderId,
          addressDetails: _deliveryAddress,
        ),
      ),
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
                      color: _coral.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.location_on_rounded, color: _coral, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Delivery Address',
                    style: TextStyle(
                      fontSize: 13,
                      color: _textGrey,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _onChangeAddress,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _coral.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Change',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _coral,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _deliveryAddress,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: _textDark,
              height: 1.4,
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
          _summaryRow(
            'Tiffin Charge',
            '₹${_tiffinCharge.toStringAsFixed(2)}',
            badge: (widget.cart.hasDiscount || (widget.cart.areaName != null && widget.cart.areaName!.isNotEmpty))
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.cart.areaName != null && widget.cart.areaName!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.cart.areaName!,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      if (widget.cart.hasDiscount) ...[
                        if (widget.cart.areaName != null && widget.cart.areaName!.isNotEmpty)
                          const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                          ),
                          child: Text(
                            '${widget.cart.discountPercentage.toStringAsFixed(0)}% OFF',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ),
                      ],
                    ],
                  )
                : null,
            customValue: widget.cart.hasDiscount
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '₹${widget.cart.originalTiffinCharge.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '₹${_tiffinCharge.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: _green,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  )
                : null,
          ),
          const SizedBox(height: 8),
          _summaryRow(
            'Delivery Charge',
            widget.cart.deliveryFee <= 0 ? 'FREE' : '₹${widget.cart.deliveryFee.toStringAsFixed(2)}',
            customValue: widget.cart.deliveryFee <= 0
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        '₹40.00',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'FREE',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: _green,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  )
                : null,
          ),
          const SizedBox(height: 8),
          _summaryRow(
              'Taxes & Fees', '₹${widget.cart.taxAmount.toStringAsFixed(2)}'),
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
              const Text("Hungrily Food's Wallet",
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
                          ? '₹${_walletDeduction.toStringAsFixed(2)} ${widget.cart.areaName != null && widget.cart.areaName!.isNotEmpty ? "(${widget.cart.areaName}) " : ""}tiffin charge will be deducted from wallet'
                          : (_walletBalance < _tiffinCharge
                              ? 'Wallet balance is ₹${_walletBalance.toStringAsFixed(2)}. Need at least ₹${_tiffinCharge.toStringAsFixed(2)} for tiffin charge.'
                              : 'No wallet deduction.'),
                      style: TextStyle(
                        fontSize: 13,
                        color: _walletDeduction > 0 ? _green : (_walletBalance < _tiffinCharge ? Colors.orange.shade800 : _textGrey),
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
                      'Remaining ₹${_remainingPayable.toStringAsFixed(2)} via $_selectedPayment',
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
              widget.cart.areaName != null && widget.cart.areaName!.isNotEmpty
                  ? 'Wallet Deduction (${widget.cart.areaName} Tiffin)'
                  : 'Wallet Deduction (Tiffin Charge)',
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

  Widget _summaryRow(String label, String value, {bool bold = false, Widget? customValue, Widget? badge}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 13.5, color: _textGrey)),
            if (badge != null) ...[
              const SizedBox(width: 6),
              badge,
            ],
          ],
        ),
        if (customValue != null)
          customValue
        else
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
