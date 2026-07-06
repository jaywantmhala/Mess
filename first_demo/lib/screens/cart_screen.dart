// lib/screens/cart_screen.dart
import 'package:flutter/material.dart';
import '../models/cart.dart';
import '../services/cart_service.dart';
import 'checkout_screen.dart';
import 'order_status_screen.dart';
import '../services/active_order_service.dart';

class CartScreen extends StatefulWidget {
  final VoidCallback? onCartChanged;

  const CartScreen({super.key, this.onCartChanged});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  static const _coral = Color(0xFFF07070);
  static const _green = Color(0xFF1DA462);
  static const _pageBg = Color(0xFFF9FAFB);
  static const _textDark = Color(0xFF1A1A2E);
  static const _textGrey = Color(0xFF6B7280);
  static const _divider = Color(0xFFE5E7EB);

  CartSummary _cart = CartSummary.empty();
  bool _isLoading = true;
  final Set<int> _updatingItems = {};

  @override
  void initState() {
    super.initState();
    _fetchCart();
  }

  Future<void> _fetchCart() async {
    try {
      final cart = await CartService.instance.getCart();
      if (mounted) setState(() { _cart = cart; _isLoading = false; });
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Cart?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('All items will be removed from your cart.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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

  void _proceedToCheckout() {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          cart: _cart,
          onOrderPlaced: () {
            widget.onCartChanged?.call();
            Navigator.pop(context, true); // pop CartScreen

            // Redirect to OrderStatusScreen showing the live order status
            final activeOrder = ActiveOrderService.instance.activeOrderNotifier.value;
            if (activeOrder != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderStatusScreen(initialOrder: activeOrder),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Your Cart',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: _textDark,
          ),
        ),
        actions: [
          if (!_cart.isEmpty)
            TextButton(
              onPressed: _clearCart,
              child: const Text(
                'Clear',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _coral))
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
          Icon(Icons.shopping_cart_outlined,
              size: 80, color: _textGrey.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('Your cart is empty',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: _textDark)),
          const SizedBox(height: 8),
          Text('Browse nearby hotels and add items',
              style: TextStyle(color: _textGrey, fontSize: 13)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Browse Hotels'),
          ),
        ],
      ),
    );
  }

  // ── Cart Content ─────────────────────────────────────────────────────────────

  Widget _buildCartContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hotel info chip
          if (_cart.hotel != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _divider),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _coral.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.storefront_rounded,
                        color: _coral, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _cart.hotel!.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: _textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Items
          const Text('Items',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _textDark)),
          const SizedBox(height: 10),
          Container(
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
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _cart.items.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, index) =>
                  _buildCartItemRow(_cart.items[index]),
            ),
          ),

          const SizedBox(height: 20),

          // Order Summary
          _buildOrderSummary(),
        ],
      ),
    );
  }

  Widget _buildCartItemRow(CartItem item) {
    final isUpdating = _updatingItems.contains(item.cartItemId);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Veg/NonVeg icon
          _vegIndicator(item.isVeg),
          const SizedBox(width: 10),
          // Name + price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${item.price.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12.5, color: _textGrey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Quantity controls
          if (isUpdating)
            const SizedBox(
              width: 80,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _coral),
                ),
              ),
            )
          else
            _qtyControl(item),
          const SizedBox(width: 10),
          // Subtotal
          SizedBox(
            width: 60,
            child: Text(
              '₹${item.subtotal.toStringAsFixed(0)}',
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: _textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vegIndicator(bool isVeg) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        border: Border.all(
            color: isVeg ? const Color(0xFF118C4F) : Colors.red, width: 1.5),
        borderRadius: BorderRadius.circular(3),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isVeg ? const Color(0xFF118C4F) : Colors.red,
        ),
      ),
    );
  }

  Widget _qtyControl(CartItem item) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _coral.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Minus / remove
          InkWell(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
            onTap: () => _updateQty(item, item.quantity - 1),
            child: Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              child: Icon(
                item.quantity == 1
                    ? Icons.delete_outline_rounded
                    : Icons.remove_rounded,
                size: 18,
                color: _coral,
              ),
            ),
          ),
          // Count
          SizedBox(
            width: 28,
            child: Text(
              '${item.quantity}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: _textDark,
              ),
            ),
          ),
          // Plus
          InkWell(
            borderRadius:
                const BorderRadius.horizontal(right: Radius.circular(8)),
            onTap: () => _updateQty(item, item.quantity + 1),
            child: Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              child: const Icon(Icons.add_rounded, size: 18, color: _coral),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Summary',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800, color: _textDark)),
          const SizedBox(height: 14),
          _summaryRow('Items (${_cart.totalQuantity})',
              '₹${_cart.subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 10),
          _summaryRow('Delivery Fee', '₹${_cart.deliveryFee.toStringAsFixed(2)}'),
          const SizedBox(height: 10),
          _summaryRow('Taxes & Fees', '₹${_cart.taxAmount.toStringAsFixed(2)}'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Grand Total',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _textDark)),
              Text(
                '₹${_cart.grandTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w900, color: _coral),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13.5, color: _textGrey)),
        Text(value,
            style: const TextStyle(
                fontSize: 13.5, fontWeight: FontWeight.w600, color: _textDark)),
      ],
    );
  }

  // ── Checkout Bar ─────────────────────────────────────────────────────────────

  Widget _buildCheckoutBar() {
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
                offset: const Offset(0, -4)),
          ],
        ),
        child: Row(
          children: [
            // Total
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₹${_cart.grandTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: _textDark,
                  ),
                ),
                const Text(
                  'View Detailed Bill',
                  style: TextStyle(
                    fontSize: 12,
                    color: _green,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // Proceed
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _proceedToCheckout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Proceed to Pay',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
