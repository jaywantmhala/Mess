// lib/screens/cart_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/cart.dart';
import '../models/order.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../services/wallet_service.dart';
import '../services/address_service.dart';
import '../services/active_order_service.dart';
import 'order_success_screen.dart';

class CartScreen extends StatefulWidget {
  final VoidCallback? onCartChanged;

  const CartScreen({super.key, this.onCartChanged});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  CartSummary _cart = CartSummary.empty();
  bool _isLoading = true;
  final Set<int> _updatingItems = {};

  double _walletBalance = 0.0;
  bool _isPlacingOrder = false;
  String _deliveryAddress = 'Fetching address...';

  @override
  void initState() {
    super.initState();
    _fetchCart();
    _fetchWallet();
    _loadAddress();
  }

  Future<void> _fetchWallet() async {
    try {
      final w = await WalletService.instance.getBalance();
      if (mounted) {
        setState(() {
          _walletBalance = w.balance;
        });
      }
    } catch (_) {
      if (mounted) setState(() {});
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

  Future<void> _fetchCart() async {
    try {
      final cart = await CartService.instance.getCart();
      if (mounted)
        setState(() {
          _cart = cart;
          _isLoading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateQty(CartItem item, int newQty) async {
    if (_updatingItems.contains(item.cartItemId)) return;
    setState(() => _updatingItems.add(item.cartItemId));
    try {
      final updated = await CartService.instance.updateItem(
        cartItemId: item.cartItemId,
        quantity: newQty,
      );
      if (mounted) {
        setState(() {
          _cart = updated;
          _updatingItems.remove(item.cartItemId);
        });
        widget.onCartChanged?.call();
      }
    } catch (_) {
      if (mounted) setState(() => _updatingItems.remove(item.cartItemId));
    }
  }

  Future<void> _clearCart() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Clear Cart?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text('All items will be removed from your cart.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await CartService.instance.clearCart();
      if (mounted) {
        setState(() => _cart = CartSummary.empty());
        widget.onCartChanged?.call();
      }
    }
  }

  Future<void> _placeOrder() async {
    final tiffinCharge = _cart.tiffinCharge > 0 ? _cart.tiffinCharge : 50.0;
    if (_walletBalance < tiffinCharge) {
      final areaSuffix = (_cart.areaName != null && _cart.areaName!.isNotEmpty)
          ? " (${_cart.areaName} Tiffin Charge)"
          : "";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Insufficient wallet balance. Minimum ₹${tiffinCharge.toStringAsFixed(0)}$areaSuffix required in wallet to place an order.",
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);
    try {
      final result = await OrderService.instance.placeOrder(
        paymentMethod: 'WALLET',
        deliveryAddress: _deliveryAddress,
      );
      if (mounted) {
        setState(() => _isPlacingOrder = false);
        WalletService.instance.balanceNotifier.value = result.newWalletBalance;
        WalletService.instance.transactionNotifier.value++;

        final orderItem = OrderHistoryItem(
          orderId: result.orderId,
          hotelName: _cart.hotel?.name ?? 'Mess',
          status: result.status,
          grandTotal: result.grandTotal,
          walletDeducted: result.walletDeducted,
          itemCount: _cart.totalQuantity,
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _showSuccessDialog(OrderResult result) async {
    if (!mounted) return;
    widget.onCartChanged?.call();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => OrderSuccessScreen(
          orderId: result.orderId,
          addressDetails: _deliveryAddress,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // Back button with soft pink background
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0F0),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Color(0xFFEF4444),
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Your Cart',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Review your items and place your order',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (!_cart.isEmpty)
                  GestureDetector(
                    onTap: _clearCart,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFFD1D1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: Color(0xFFEF4444),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Clear Cart',
                            style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFEF4444)),
            )
          : _cart.isEmpty
          ? _buildEmptyCart()
          : _buildCartContent(),
      bottomNavigationBar: _cart.isEmpty ? null : _buildCheckoutBar(),
    );
  }

  // ── Empty State ──────────────────────────────────────────────────────────────

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Browse nearby messes and add items',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Browse Messes',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Cart Main Content ────────────────────────────────────────────────────────

  Widget _buildCartContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Hotel info banner card
          _buildHotelBanner(),
          const SizedBox(height: 20),

          // 2. Items Header
          Row(
            children: [
              const Icon(
                Icons.shopping_bag_outlined,
                color: Color(0xFFEF4444),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Items in Cart (${_cart.totalQuantity})',
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text(
                  'Add more items',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3. Items list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _cart.items.length,
            itemBuilder: (context, index) =>
                _buildCartItemCard(_cart.items[index]),
          ),
          const SizedBox(height: 16),

          // Offers section banner
          _buildOffersSection(),
          const SizedBox(height: 16),

          // 4. Order Summary
          _buildOrderSummary(),
          const SizedBox(height: 16),

          // 5. Safe & Secure Payments Banner
          _buildSecurePaymentsBanner(),
        ],
      ),
    );
  }

  // ── Hotel Banner ─────────────────────────────────────────────────────────────

  Widget _buildHotelBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF1F2), Color(0xFFFFF5F5)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFE4E6), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Hotel Image with floating icon badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _cart.hotel?.name == null
                    ? Container(
                        width: 82,
                        height: 82,
                        color: const Color(0xFFFFF0E6),
                        child: const Icon(
                          Icons.restaurant_rounded,
                          color: Color(0xFFEF4444),
                          size: 36,
                        ),
                      )
                    : Image.asset(
                        'assets/images/thali_platter_banner.png',
                        width: 82,
                        height: 82,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Container(
                          width: 82,
                          height: 82,
                          color: const Color(0xFFFFF0E6),
                          child: const Icon(
                            Icons.restaurant_rounded,
                            color: Color(0xFFEF4444),
                            size: 36,
                          ),
                        ),
                      ),
              ),
              Positioned(
                bottom: -4,
                left: -4,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.storefront_rounded,
                      color: Color(0xFFEF4444),
                      size: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // Middle: Mess Info Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'From',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _cart.hotel?.name ?? 'Grand Mess',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Rating & Time Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F4EA),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.star_rounded,
                            color: Color(0xFF137333),
                            size: 12,
                          ),
                          SizedBox(width: 2),
                          Text(
                            '4.6',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF137333),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '|',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade300,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '25-30 mins',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Badges Row
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      _buildMiniBadge(
                        Icons.restaurant_menu_rounded,
                        'Good food',
                      ),
                      const SizedBox(width: 6),
                      _buildMiniBadge(Icons.access_time_rounded, 'On time'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFEF4444), size: 10.5),
          const SizedBox(width: 3),
          Text(
            text,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
  }

  // ── Cart Item Card ───────────────────────────────────────────────────────────

  Widget _buildCartItemCard(CartItem item) {
    final isUpdating = _updatingItems.contains(item.cartItemId);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF8FAFC), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 2. Veg Icon & Name
          Expanded(
            child: Row(
              children: [
                // Veg Indicator
                Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: item.isVeg
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626),
                      width: 1.2,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Center(
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: item.isVeg
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // 3. Quantity Pill Selector
          if (isUpdating)
            const SizedBox(
              width: 88,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
            )
          else
            Container(
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFE4E6), width: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 30,
                    ),
                    icon: const Icon(
                      Icons.remove_rounded,
                      color: Color(0xFFEF4444),
                      size: 15,
                    ),
                    onPressed: () => _updateQty(item, item.quantity - 1),
                  ),
                  Text(
                    '${item.quantity}',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 30,
                    ),
                    icon: const Icon(
                      Icons.add_rounded,
                      color: Color(0xFFEF4444),
                      size: 15,
                    ),
                    onPressed: () => _updateQty(item, item.quantity + 1),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 12),

          // 4. Delete trash icon
          GestureDetector(
            onTap: () => _updateQty(item, 0),
            child: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFEF4444),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // Offers Section Banner

  Widget _buildOffersSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFEF3C7), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFF59E0B),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.percent_rounded, color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Save more with offers!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'View all available offers & deals',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFFF59E0B),
            size: 22,
          ),
        ],
      ),
    );
  }

  // ── Order Summary Card (Bill Details) ────────────────────────────────────────

  Widget _buildOrderSummary() {
    final tiffinCharge = _cart.tiffinCharge > 0 ? _cart.tiffinCharge : 50.0;
    final totalBill = _cart.grandTotal > 0
        ? _cart.grandTotal
        : (_cart.subtotal + tiffinCharge + _cart.deliveryFee + _cart.taxAmount);
    final payableAmount = totalBill;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF8FAFC), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Color(0xFFEF4444),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Bill Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Row 1: Item Total
          _buildBillRow(
            'Item Total (${_cart.totalQuantity})',
            '₹${_cart.subtotal.toStringAsFixed(2)}',
            isBold: false,
          ),
          const SizedBox(height: 12),

          // Row 2: Area Tiffin Charge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tiffin Charge',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_cart.hasDiscount) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: Text(
                        '${_cart.discountPercentage.toStringAsFixed(0)}% OFF',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_cart.hasDiscount) ...[
                    Text(
                      '₹${_cart.originalTiffinCharge.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade400,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    '₹${tiffinCharge.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _cart.hasDiscount ? const Color(0xFF16A34A) : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 3: Delivery Charge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Delivery Charge',
                style: TextStyle(
                  fontSize: 13.5,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_cart.deliveryFee <= 0)
                Row(
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
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                )
              else
                Text(
                  '₹${_cart.deliveryFee.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 4: Taxes & Fees
          _buildBillRow(
            'Taxes & Fees',
            '₹${_cart.taxAmount.toStringAsFixed(2)}',
            isBold: false,
          ),
          const SizedBox(height: 12),

          // Row 5: Total Bill
          _buildBillRow(
            'Total Bill',
            '₹${totalBill.toStringAsFixed(2)}',
            isBold: false,
          ),
          const SizedBox(height: 12),

          // Row 6: Payment Method
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Payment Mode',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Wallet',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'Balance: ₹${_walletBalance.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade100, height: 1, thickness: 1),
          const SizedBox(height: 16),

          // Net Payable / To Pay
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'To Pay (Net Payable)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                '₹${payableAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Savings / Info Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Color(0xFF10B981),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '₹${payableAmount.toStringAsFixed(2)} will be deducted from your wallet!',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w800,
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

  Widget _buildBillRow(String label, String value, {required bool isBold}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            color: Colors.grey.shade600,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  // ── Trust Badges Banner ──────────────────────────────────────────────────────

  Widget _buildSecurePaymentsBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTrustColumn(
                Icons.security_rounded,
                'Safe & Secure\nPayments',
              ),
              _buildVerticalDivider(),
              _buildTrustColumn(
                Icons.timer_outlined,
                'Lightning Fast\nDelivery',
              ),
              _buildVerticalDivider(),
              _buildTrustColumn(
                Icons.verified_outlined,
                'Best Quality\nGuaranteed',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrustColumn(IconData icon, String text) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.grey.shade400, size: 24),
          const SizedBox(height: 6),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(width: 1, height: 36, color: Colors.grey.shade200);
  }

  // ── Checkout Bottom Bar ──────────────────────────────────────────────────────

  Widget _buildCheckoutBar() {
    final tiffinCharge = _cart.tiffinCharge > 0 ? _cart.tiffinCharge : 50.0;
    final totalBill = _cart.grandTotal > 0
        ? _cart.grandTotal
        : (_cart.subtotal + tiffinCharge + _cart.deliveryFee + _cart.taxAmount);
    final payableAmount = totalBill;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Left: Wallet Icon & Amounts
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Color(0xFFEF4444),
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '₹${payableAmount.toStringAsFixed(payableAmount % 1 == 0 ? 0 : 2)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.keyboard_arrow_right_rounded,
                                  size: 16,
                                  color: Colors.grey.shade400,
                                ),
                              ],
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  children: [
                                    const TextSpan(text: 'Wallet: '),
                                    TextSpan(
                                      text:
                                          '₹${_walletBalance.toStringAsFixed(_walletBalance % 1 == 0 ? 0 : 2)}',
                                      style: const TextStyle(
                                        color: Color(0xFF10B981),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
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
                const SizedBox(width: 8),

                // Right: Pay with Wallet Button
                ElevatedButton(
                  onPressed: _isPlacingOrder ? null : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                  child: _isPlacingOrder
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Pay with Wallet',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Lock indicator row below buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 11,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(width: 3),
                Text(
                  '100% Safe & Secure',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
