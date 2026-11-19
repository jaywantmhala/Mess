import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher_string.dart';
import '../models/hotel.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';
import '../models/cart.dart';
import '../widgets/view_cart_bar.dart';
import '../utils/app_config.dart';
import '../services/hotel_service.dart';
import 'customer_subscription_screen.dart';
import 'cart_screen.dart';

class HotelMenuScreen extends StatefulWidget {
  final Hotel hotel;

  const HotelMenuScreen({super.key, required this.hotel});

  @override
  State<HotelMenuScreen> createState() => _HotelMenuScreenState();
}

class _HotelMenuScreenState extends State<HotelMenuScreen> {
  static const Color textDark = Color(0xFF1C1C1C);
  static const Color textGrey = Color(0xFF696969);
  static const Color zomatoRed = Color(0xFFE23744);
  static const Color vegGreen = Color(0xFF118C4F);

  late ScrollController _scrollController;
  bool _isScrolled = false;
  bool _isLoadingMenu = true;
  bool? _hasActiveSubscription;

  List<Map<String, dynamic>> _menuItems = [];
  CartSummary? _cartSummary;

  bool _filterVeg = false;
  bool _filterNonVeg = false;
  bool _filterHighlyReordered = false;
  bool _filterSpicy = false;
  final Set<dynamic> _expandedItemIds = {};

  List<Map<String, dynamic>> get _filteredMenuItems {
    var items = List<Map<String, dynamic>>.from(_menuItems);

    if (_filterVeg) {
      items = items.where((item) => item['isVeg'] == true).toList();
    }
    if (_filterNonVeg) {
      items = items.where((item) => item['isVeg'] == false).toList();
    }
    if (_filterHighlyReordered) {
      items = items.where((item) => item['isHighlyReordered'] == true).toList();
    }
    if (_filterSpicy) {
      items = items.where((item) => item['isSpicy'] == true).toList();
    }

    return items;
  }

  Future<void> _loadCart() async {
    try {
      final cart = await CartService.instance.getCart();
      if (mounted) {
        setState(() {
          _cartSummary = cart;
        });
      }
    } catch (e) {
      debugPrint('Failed to load cart: $e');
    }
  }

  Future<void> _fetchSubscriptionStatus() async {
    try {
      final hasSub = await HotelService.instance.hasActiveSubscription();
      if (mounted) {
        setState(() {
          _hasActiveSubscription = hasSub;
        });
      }
    } catch (e) {
      debugPrint('Failed to load subscription status: $e');
    }
  }

  int _getItemQuantity(int menuItemId) {
    if (_cartSummary == null) return 0;
    for (var item in _cartSummary!.items) {
      if (item.menuItemId == menuItemId) {
        return item.quantity;
      }
    }
    return 0;
  }

  CartItem? _findCartItem(int menuItemId) {
    if (_cartSummary == null) return null;
    for (var item in _cartSummary!.items) {
      if (item.menuItemId == menuItemId) {
        return item;
      }
    }
    return null;
  }

  Future<void> _addToCart(
    int menuItemId, {
    List<String>? selectedOptionals,
  }) async {
    try {
      final summary = await CartService.instance.addItem(
        menuItemId: menuItemId,
        hotelId: widget.hotel.id,
        quantity: 1,
        selectedOptionals: selectedOptionals,
      );
      setState(() {
        _cartSummary = summary;
      });
    } on HotelConflictException catch (e) {
      _showHotelConflictDialog(e, menuItemId);
    } catch (e) {
      _showErrorSnackBar('Failed to add item: $e');
    }
  }

  Future<bool> _verifyCustomerSubscription() async {
    if (_hasActiveSubscription == true) {
      return true;
    }

    // If status is not yet loaded, show checking progress dialog
    if (_hasActiveSubscription == null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => PopScope(
          canPop: false,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: zomatoRed,
                    ),
                  ),
                  SizedBox(width: 14),
                  Text(
                    'Checking subscription...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final hasSub = await HotelService.instance.hasActiveSubscription();
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        setState(() {
          _hasActiveSubscription = hasSub;
        });
      }
      return hasSub;
    }

    // If recorded as false, do a fresh check from server in case user recently subscribed
    final hasSub = await HotelService.instance.hasActiveSubscription();
    if (mounted) {
      setState(() {
        _hasActiveSubscription = hasSub;
      });
    }
    return hasSub;
  }

  void _showSubscriptionRequiredDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: zomatoRed.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.card_membership_rounded,
                    color: zomatoRed,
                    size: 34,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Subscription Required',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'You must have an active meal subscription to order dishes from this mess. Please buy a subscription to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: textGrey,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.of(dialogCtx).pop();
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CustomerSubscriptionScreen(),
                      ),
                    );
                    if (mounted) {
                      await _fetchSubscriptionStatus();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: zomatoRed,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Buy Subscription',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: textGrey,
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleAddToCart(Map<String, dynamic> item) async {
    // 1. Check if customer has bought an active subscription
    final bool hasSub = await _verifyCustomerSubscription();
    if (!hasSub) {
      _showSubscriptionRequiredDialog();
      return;
    }

    // 2. Customer has an active subscription -> continue as it is
    final bool isCustomisable = item['isCustomisable'] == true ||
        (item['mandatoryItems'] != null &&
            (item['mandatoryItems'] as List).isNotEmpty) ||
        (item['optionalItems'] != null &&
            (item['optionalItems'] as List).isNotEmpty);

    if (isCustomisable) {
      _showOptionalItemsSelectionSheet(item);
    } else {
      _addToCart(item['id'] ?? 0);
    }
  }

  void _showOptionalItemsSelectionSheet(Map<String, dynamic> item) {
    final List<String> mandatoryItems = (item['mandatoryItems'] is List)
        ? List<String>.from(item['mandatoryItems'])
        : [];

    final List<String> allOptionals = (item['optionalItems'] is List)
        ? List<String>.from(item['optionalItems'])
        : [];

    final List<String> drySabjis = [];
    final List<String> gravySabjis = [];
    final List<String> otherOptionals = [];

    for (var opt in allOptionals) {
      if (opt.startsWith('Sukhi Bhaji: ') || opt.startsWith('Dry Sabji: ')) {
        drySabjis.add(
          opt.replaceFirst(RegExp(r'^(Sukhi Bhaji|Dry Sabji):\s*'), ''),
        );
      } else if (opt.startsWith('Patal Bhaji: ') ||
          opt.startsWith('Gravy Sabji: ')) {
        gravySabjis.add(
          opt.replaceFirst(RegExp(r'^(Patal Bhaji|Gravy Sabji):\s*'), ''),
        );
      } else {
        if (drySabjis.length < 2) {
          drySabjis.add(opt);
        } else if (gravySabjis.length < 2) {
          gravySabjis.add(opt);
        } else {
          otherOptionals.add(opt);
        }
      }
    }

    String? selectedDry = drySabjis.isNotEmpty ? drySabjis.first : null;
    String? selectedGravy = gravySabjis.isNotEmpty ? gravySabjis.first : null;
    final Set<String> selectedOthers = {};
    int quantity = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFFF4F4F6),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Floating Close Button (X) above header
                  const SizedBox(height: 10),
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E293B),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Scrollable Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Header Card (Dish Info & Hotel Name)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Thumbnail Image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    item['imageUrl'] ??
                                        'https://images.unsplash.com/photo-1541592106381-b31e9677c0e5?q=80&w=400',
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) =>
                                        Container(
                                          width: 60,
                                          height: 60,
                                          color: Colors.grey.shade200,
                                          child: const Icon(
                                            Icons.restaurant_rounded,
                                            color: Colors.grey,
                                          ),
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Dish & Hotel Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          if (item['isVeg'] == true)
                                            _buildVegIcon()
                                          else
                                            _buildNonVegIcon(),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              item['name'] ?? 'Dish Name',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color: textDark,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.hotel.hotelName,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: textGrey,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // ── CARD 1: MANDATORY ITEMS (REQUIRED • UNCLICKABLE) ──
                          if (mandatoryItems.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Mandatory Included Items',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Required • Included in meal by default',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textGrey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(height: 1),
                                  const SizedBox(height: 8),
                                  ...mandatoryItems.map(
                                    (m) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              m,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: textDark,
                                              ),
                                            ),
                                          ),
                                          // Checked disabled indicator (unclickable)
                                          Container(
                                            width: 22,
                                            height: 22,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF10B981),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.check_rounded,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // ── CARD 2: DRY SABJI / SUKHI BHAJI (OPTIONAL CHOICE) ──
                          if (drySabjis.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Dry Sabji / Sukhi Bhaji',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Select 1 option',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textGrey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(height: 1),
                                  const SizedBox(height: 8),
                                  ...drySabjis.map(
                                    (d) => InkWell(
                                      onTap: () {
                                        setModalState(() {
                                          selectedDry = d;
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                d,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: textDark,
                                                ),
                                              ),
                                            ),
                                            // Radio Button
                                            Container(
                                              width: 22,
                                              height: 22,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: selectedDry == d
                                                      ? zomatoRed
                                                      : Colors.grey.shade400,
                                                  width: selectedDry == d
                                                      ? 6
                                                      : 2,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // ── CARD 3: GRAVY SABJI / PATAL BHAJI (OPTIONAL CHOICE) ──
                          if (gravySabjis.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Gravy Sabji / Patal Bhaji',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Select 1 option',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textGrey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(height: 1),
                                  const SizedBox(height: 8),
                                  ...gravySabjis.map(
                                    (g) => InkWell(
                                      onTap: () {
                                        setModalState(() {
                                          selectedGravy = g;
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                g,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: textDark,
                                                ),
                                              ),
                                            ),
                                            // Radio Button
                                            Container(
                                              width: 22,
                                              height: 22,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: selectedGravy == g
                                                      ? zomatoRed
                                                      : Colors.grey.shade400,
                                                  width: selectedGravy == g
                                                      ? 6
                                                      : 2,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // ── OTHER OPTIONALS CARD (IF ANY) ──
                          if (otherOptionals.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Additional Add-ons',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(height: 1),
                                  const SizedBox(height: 8),
                                  ...otherOptionals.map(
                                    (o) => CheckboxListTile(
                                      activeColor: zomatoRed,
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        o,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: textDark,
                                        ),
                                      ),
                                      value: selectedOthers.contains(o),
                                      onChanged: (val) {
                                        setModalState(() {
                                          if (val == true) {
                                            selectedOthers.add(o);
                                          } else {
                                            selectedOthers.remove(o);
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                  // ── STICKY BOTTOM ACTION BAR (ZOMATO STYLE) ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Quantity stepper box [ - 1 + ]
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: zomatoRed.withOpacity(0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  if (quantity > 1) {
                                    setModalState(() => quantity--);
                                  }
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 14),
                                  child: Text(
                                    '-',
                                    style: TextStyle(
                                      color: zomatoRed,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                '$quantity',
                                style: const TextStyle(
                                  color: zomatoRed,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  setModalState(() => quantity++);
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 14),
                                  child: Text(
                                    '+',
                                    style: TextStyle(
                                      color: zomatoRed,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Big Red "Add item" Button
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: zomatoRed,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () async {
                                Navigator.pop(context);
                                final List<String> chosenOptionals = [];
                                if (selectedDry != null &&
                                    selectedDry!.isNotEmpty) {
                                  chosenOptionals.add(
                                    'Sukhi Bhaji: $selectedDry',
                                  );
                                }
                                if (selectedGravy != null &&
                                    selectedGravy!.isNotEmpty) {
                                  chosenOptionals.add(
                                    'Patal Bhaji: $selectedGravy',
                                  );
                                }
                                for (var o in selectedOthers) {
                                  chosenOptionals.add(o);
                                }

                                // Add item to cart with quantity & chosen optional items
                                for (int i = 0; i < quantity; i++) {
                                  await _addToCart(
                                    item['id'] ?? 0,
                                    selectedOptionals: chosenOptionals,
                                  );
                                }
                              },
                              child: const Text(
                                'Add item',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateCartQuantity(int menuItemId, int newQuantity) async {
    final cartItem = _findCartItem(menuItemId);
    if (cartItem == null) {
      if (newQuantity > 0) {
        await _addToCart(menuItemId);
      }
      return;
    }
    try {
      final summary = await CartService.instance.updateItem(
        cartItemId: cartItem.cartItemId,
        quantity: newQuantity,
      );
      setState(() {
        _cartSummary = summary;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to update quantity: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: zomatoRed),
    );
  }

  void _showHotelConflictDialog(
    HotelConflictException exception,
    int targetMenuItemId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard existing cart?'),
        content: Text(
          'Your cart contains items from "${exception.existingHotelName}". '
          'Would you like to clear the cart and add items from "${widget.hotel.hotelName}" instead?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: textGrey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: zomatoRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await CartService.instance.clearCart();
                await _addToCart(targetMenuItemId);
              } catch (e) {
                _showErrorSnackBar('Failed to clear cart: $e');
              }
            },
            child: const Text('Clear & Add'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        if (_scrollController.offset > 80 && !_isScrolled) {
          setState(() => _isScrolled = true);
        } else if (_scrollController.offset <= 80 && _isScrolled) {
          setState(() => _isScrolled = false);
        }
      });
    _fetchMenu();
    _loadCart();
    _fetchSubscriptionStatus();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMenu() async {
    setState(() => _isLoadingMenu = true);
    try {
      final token = await AuthService.instance.getSavedToken();
      final headers = <String, String>{};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      final response = await http
          .get(
            Uri.parse('$kBaseUrl/api/hotels/menu?hotel_id=${widget.hotel.id}'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List items = data['data'];
          if (mounted) {
            setState(() {
              _menuItems = items
                  .map(
                    (i) => {
                      'id': i['id'] ?? 0,
                      'isVeg': i['isVeg'] ?? true,
                      'isSpicy': i['isSpicy'] ?? false,
                      'name': i['name'] ?? 'Item',
                      'price': i['price'] ?? 0,
                      'originalPrice': i['originalPrice'],
                      'description': i['description'] ?? '',
                      'imageUrl':
                          i['imageUrl'] ??
                          'https://images.unsplash.com/photo-1541592106381-b31e9677c0e5?q=80&w=400',
                      'isHighlyReordered': i['isHighlyReordered'] ?? false,
                      'isAvailable': i['isAvailable'] ?? true,
                      'isCustomisable': i['isCustomisable'] ?? false,
                      'mandatoryItems': (i['mandatoryItems'] is List)
                          ? List<String>.from(i['mandatoryItems'])
                          : <String>[],
                      'optionalItems': (i['optionalItems'] is List)
                          ? List<String>.from(i['optionalItems'])
                          : <String>[],
                    },
                  )
                  .toList();
              _isLoadingMenu = false;
            });
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Menu fetch error: $e');
    }

    // When menu is not present or not updated yet, do NOT show any dummy menu
    if (mounted) {
      setState(() {
        _menuItems = [];
        _isLoadingMenu = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              color: zomatoRed,
              onRefresh: () async {
                await _fetchMenu();
                await _loadCart();
              },
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  _buildSliverAppBar(),
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHotelHeader(),
                        // if (_menuItems.isNotEmpty) ...[
                        //   _buildOffers(),
                        //   _buildFiltersRow(),
                        // ],
                      ],
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 100),
                    sliver: _isLoadingMenu
                        ? const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: zomatoRed,
                                ),
                              ),
                            ),
                          )
                        : (_menuItems.isEmpty
                              ? SliverToBoxAdapter(
                                  child: _buildMenuNotUpdatedYet(),
                                )
                              : (_filteredMenuItems.isEmpty
                                    ? SliverToBoxAdapter(
                                        child: _buildNoFilteredItems(),
                                      )
                                    : SliverList(
                                        delegate: SliverChildBuilderDelegate(
                                          (context, index) {
                                            final item =
                                                _filteredMenuItems[index];
                                            return Column(
                                              children: [
                                                _buildMenuItemCard(item),
                                                if (index <
                                                    _filteredMenuItems.length -
                                                        1)
                                                  const Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 16,
                                                        ),
                                                    child: _DottedDivider(),
                                                  ),
                                              ],
                                            );
                                          },
                                          childCount: _filteredMenuItems.length,
                                        ),
                                      ))),
                  ),
                ],
              ),
            ),

            // Floating Menu Button (only when menu items exist)
            if (_menuItems.isNotEmpty)
              Positioned(
                bottom:
                    (_cartSummary != null && _cartSummary!.totalQuantity > 0)
                    ? 88
                    : 24,
                right: 24,
                child: _buildFloatingMenuButton(),
              ),

            // Sticky Bottom View Cart Bar
            if (_cartSummary != null && _cartSummary!.totalQuantity > 0)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: ViewCartBar(
                  itemCount: _cartSummary!.totalQuantity,
                  totalPrice: _cartSummary!.grandTotal,
                  onTap: () async {
                    final orderPlaced = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CartScreen(),
                      ),
                    );
                    _loadCart(); // Refresh cart on returning
                    if (orderPlaced == true && mounted) {
                      Navigator.pop(context, true);
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuNotUpdatedYet() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.restaurant_menu_rounded,
                size: 38,
                color: Color(0xFFE23744),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Menu not updated yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.hotel.hotelName} has not updated today\'s menu yet. Please check back soon.',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _fetchMenu,
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 16,
                  color: Color(0xFFE23744),
                ),
                label: const Text(
                  'Refresh',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE23744),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
              ),
              if (widget.hotel.mobileNumber.isNotEmpty) ...[
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    final uri = 'tel:${widget.hotel.mobileNumber}';
                    try {
                      if (await canLaunchUrlString(uri)) {
                        await launchUrlString(uri);
                      }
                    } catch (_) {}
                  },
                  icon: const Icon(
                    Icons.call_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Call Hotel',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoFilteredItems() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.filter_alt_off_rounded,
            size: 36,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          const Text(
            'No items match selected filters',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              setState(() {
                _filterVeg = false;
                _filterNonVeg = false;
                _filterHighlyReordered = false;
                _filterSpicy = false;
              });
            },
            child: const Text(
              'Clear Filters',
              style: TextStyle(color: zomatoRed, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      elevation: _isScrolled ? 2 : 0,
      backgroundColor: Colors.white,
      automaticallyImplyLeading: false,
      titleSpacing: 12,
      toolbarHeight: 60,
      title: Row(
        children: [
          // Back button
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: textDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Search Bar
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: textDark, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Search',
                    style: TextStyle(
                      color: textGrey.withOpacity(0.8),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Group icon
          InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Icon(
                Icons.group_add_outlined,
                size: 20,
                color: textDark,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // More icon
          InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Icon(
                Icons.more_vert_rounded,
                size: 20,
                color: textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotelHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pure Veg tag if applicable
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: vegGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.eco_rounded, color: vegGreen, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Pure Veg',
                  style: TextStyle(
                    color: vegGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.hotel.hotelName,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: textDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.info_outline_rounded,
                      color: textGrey,
                      size: 20,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: vegGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '4.2',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: textGrey, size: 16),
              const SizedBox(width: 4),
              Text(
                '${widget.hotel.distance?.toStringAsFixed(1) ?? "5.8"} km • ${widget.hotel.area ?? "Viman Nagar"}',
                style: const TextStyle(
                  fontSize: 13,
                  color: textGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: textGrey,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: textGrey, size: 16),
              const SizedBox(width: 4),
              const Text(
                '35-40 mins • Schedule for later',
                style: TextStyle(
                  fontSize: 13,
                  color: textGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: textGrey,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF2F2F2)),
        ],
      ),
    );
  }

  // Widget _buildOffers() {
  //   return Column(
  //     children: [
  //       Padding(
  //         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //         child: Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [],
  //         ),
  //       ),
  //       Container(
  //         width: double.infinity,
  //         height: 8,
  //         color: const Color(0xFFF4F4F5),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildFiltersRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildFilterChip(
            label: 'Veg',
            iconWidget: _buildVegIcon(),
            isSelected: _filterVeg,
            onTap: () {
              setState(() {
                _filterVeg = !_filterVeg;
                if (_filterVeg) _filterNonVeg = false;
              });
            },
          ),
          const SizedBox(width: 10),
          _buildFilterChip(
            label: 'Non-veg',
            iconWidget: _buildNonVegIcon(),
            isSelected: _filterNonVeg,
            onTap: () {
              setState(() {
                _filterNonVeg = !_filterNonVeg;
                if (_filterNonVeg) _filterVeg = false;
              });
            },
          ),

          const SizedBox(width: 10),
          _buildFilterChip(
            label: 'Highly reordered',
            icon: Icons.refresh_rounded,
            iconColor: vegGreen,
            isSelected: _filterHighlyReordered,
            onTap: () {
              setState(() {
                _filterHighlyReordered = !_filterHighlyReordered;
              });
            },
          ),
          const SizedBox(width: 10),
          _buildFilterChip(
            label: 'Spicy',
            iconWidget: const Icon(
              Icons.whatshot_rounded,
              color: zomatoRed,
              size: 16,
            ),
            isSelected: _filterSpicy,
            onTap: () {
              setState(() {
                _filterSpicy = !_filterSpicy;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    IconData? icon,
    Color? iconColor,
    Widget? iconWidget,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? vegGreen.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? vegGreen : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: iconColor ?? textDark),
              const SizedBox(width: 6),
            ],
            if (iconWidget != null) ...[iconWidget, const SizedBox(width: 6)],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? vegGreen : textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItemCard(Map<String, dynamic> item) {
    final bool isAvailable = item['isAvailable'] ?? true;
    final dynamic itemId = item['id'] ?? item['name'] ?? 0;
    final String description = (item['description'] ?? '').toString().trim();
    final bool isExpanded = _expandedItemIds.contains(itemId);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Opacity(
        opacity: isAvailable ? 1.0 : 0.5,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Veg/NonVeg and Spicy icons
                  Row(
                    children: [
                      if (item['isVeg'] == true)
                        _buildVegIcon()
                      else
                        _buildNonVegIcon(),
                      if (item['isSpicy'] == true) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.whatshot_rounded,
                          color: zomatoRed,
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Item Name
                  Text(
                    item['name'] ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                      letterSpacing: -0.2,
                    ),
                  ),
                  // Popularity Badge ("Highly reordered")
                  if (item['isHighlyReordered'] == true) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          height: 4,
                          width: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Highly reordered',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                  // Mandatory Items List (e.g. Rice + Chapati + Dal)
                  if (item['mandatoryItems'] != null &&
                      (item['mandatoryItems'] as List).isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      (item['mandatoryItems'] as List).join(' + '),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                        height: 1.3,
                      ),
                    ),
                  ],

                  // Optional Items List (e.g. (Aloo Bhendi + Shev Bhaji))
                  if (item['optionalItems'] != null &&
                      (item['optionalItems'] as List).isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '(${(item['optionalItems'] as List).map((s) => s.toString().replaceAll(RegExp(r'^(Sukhi Bhaji|Dry Sabji|Patal Bhaji|Gravy Sabji):\s*', caseSensitive: false), '').trim()).where((s) => s.isNotEmpty).join(' + ')})',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2563EB),
                        height: 1.3,
                      ),
                    ),
                  ],
                  // Description with working "more" / "less" toggle
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedItemIds.remove(itemId);
                          } else {
                            _expandedItemIds.add(itemId);
                          }
                        });
                      },
                      child: isExpanded
                          ? RichText(
                              text: TextSpan(
                                text: description,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: textGrey,
                                  height: 1.4,
                                ),
                                children: const [
                                  TextSpan(
                                    text: '  less',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: textDark,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : (description.length > 55
                              ? RichText(
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  text: TextSpan(
                                    text: description.length > 65
                                        ? '${description.substring(0, 65).trim()}...'
                                        : description,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: textGrey,
                                      height: 1.4,
                                    ),
                                    children: const [
                                      TextSpan(
                                        text: 'more',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: textDark,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Text(
                                  description,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: textGrey,
                                    height: 1.4,
                                  ),
                                )),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Action Buttons
                  Row(
                    children: [
                      _buildActionButton(Icons.favorite_border_rounded),
                      const SizedBox(width: 12),
                      _buildActionButton(
                        Icons.reply_rounded,
                      ), // Share-like icon
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Right side Image & Add button
            Column(
              children: [
                SizedBox(
                  width: 140,
                  height: 160,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      // Image
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 140,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.grey.shade100,
                            image: DecorationImage(
                              image: NetworkImage(item['imageUrl']),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      // Add Button
                      Positioned(
                        bottom: 0,
                        child: _buildAddButton(item, isAvailable),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                if (item['isCustomisable'] == true && isAvailable)
                  const Text(
                    'customisable',
                    style: TextStyle(
                      fontSize: 11,
                      color: textGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(Map<String, dynamic> item, bool isAvailable) {
    if (!isAvailable) {
      return Container(
        width: 110,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade400, width: 1),
        ),
        alignment: Alignment.center,
        child: const Text(
          'SOLD OUT',
          style: TextStyle(
            color: textGrey,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    final int itemId = item['id'] ?? 0;
    final int qty = _getItemQuantity(itemId);

    if (qty == 0) {
      return Container(
        width: 110,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF6F7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: zomatoRed.withOpacity(0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _handleAddToCart(item),
            child: SizedBox.expand(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Text(
                    'ADD',
                    style: TextStyle(
                      color: zomatoRed,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Positioned(
                    top: 3,
                    right: 8,
                    child: Text(
                      '+',
                      style: TextStyle(
                        color: zomatoRed.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: 110,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6F7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: zomatoRed.withOpacity(0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(8),
                ),
                onTap: () => _updateCartQuantity(itemId, qty - 1),
                child: const SizedBox.expand(
                  child: Center(
                    child: Text(
                      '-',
                      style: TextStyle(
                        color: zomatoRed,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '$qty',
                style: const TextStyle(
                  color: zomatoRed,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(8),
                ),
                onTap: () {
                  if (_hasActiveSubscription == false) {
                    _showSubscriptionRequiredDialog();
                    return;
                  }
                  _updateCartQuantity(itemId, qty + 1);
                },
                child: const SizedBox.expand(
                  child: Center(
                    child: Text(
                      '+',
                      style: TextStyle(
                        color: zomatoRed,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Icon(icon, size: 18, color: textGrey),
    );
  }

  Widget _buildVegIcon() {
    return Container(
      width: 14,
      height: 14,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: Border.all(color: vegGreen, width: 1.5),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: vegGreen,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildNonVegIcon() {
    return Container(
      width: 14,
      height: 14,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: Border.all(color: zomatoRed, width: 1.5),
        borderRadius: BorderRadius.circular(2),
      ),
      child: CustomPaint(painter: _TrianglePainter(color: zomatoRed)),
    );
  }

  Widget _buildFloatingMenuButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E33), // Dark grey
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.restaurant_menu_rounded, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text(
            'Menu',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    var path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DottedDivider extends StatelessWidget {
  const _DottedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          direction: Axis.horizontal,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.grey.shade300),
              ),
            );
          }),
        );
      },
    );
  }
}
