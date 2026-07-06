import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/hotel.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';
import '../models/cart.dart';
import '../widgets/view_cart_bar.dart';
import '../utils/app_config.dart';
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

  List<Map<String, dynamic>> _menuItems = [];
  CartSummary? _cartSummary;

  bool _filterVeg = false;
  bool _filterNonVeg = false;
  bool _filterHighlyReordered = false;
  bool _filterSpicy = false;
  String _sortOption = ''; // '', 'low_to_high', 'high_to_low'

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

    if (_sortOption == 'low_to_high') {
      items.sort((a, b) => (a['price'] as num).compareTo(b['price'] as num));
    } else if (_sortOption == 'high_to_low') {
      items.sort((a, b) => (b['price'] as num).compareTo(a['price'] as num));
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

  Future<void> _addToCart(int menuItemId) async {
    try {
      final summary = await CartService.instance.addItem(
        menuItemId: menuItemId,
        hotelId: widget.hotel.id,
        quantity: 1,
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
      SnackBar(
        content: Text(message),
        backgroundColor: zomatoRed,
      ),
    );
  }

  void _showHotelConflictDialog(HotelConflictException exception, int targetMenuItemId) {
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
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMenu() async {
    try {
      final token = await AuthService.instance.getSavedToken();
      if (token != null) {
        final response = await http.get(
          Uri.parse('$kBaseUrl/api/hotels/menu?hotel_id=${widget.hotel.id}'),
          headers: {'Authorization': 'Bearer $token'},
        ).timeout(const Duration(seconds: 3));
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true && data['data'] != null) {
            final List items = data['data'];
            if (items.isNotEmpty) {
              if (mounted) {
                setState(() {
                  _menuItems = items.map((i) => {
                    'id': i['id'] ?? 0,
                    'isVeg': i['isVeg'] ?? true,
                    'isSpicy': i['isSpicy'] ?? false,
                    'name': i['name'] ?? 'Item',
                    'price': i['price'] ?? 0,
                    'originalPrice': i['originalPrice'],
                    'description': i['description'] ?? '',
                    'imageUrl': i['imageUrl'] ?? 'https://images.unsplash.com/photo-1541592106381-b31e9677c0e5?q=80&w=400',
                    'isHighlyReordered': i['isHighlyReordered'] ?? false,
                    'isAvailable': i['isAvailable'] ?? true,
                    'isCustomisable': i['isCustomisable'] ?? false,
                  }).toList();
                  _isLoadingMenu = false;
                });
              }
              return;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Menu fetch failed, using fallback mock data: $e');
    }
    
    // Fallback Mock Data
    if (mounted) {
      setState(() {
        _menuItems = [
          {
            'id': 101,
            'isVeg': true,
            'isSpicy': false,
            'name': 'Meal For 2',
            'price': 209,
            'originalPrice': 320,
            'description': 'Start your day with a bang! Delicious treats to kickstart your mornin',
            'imageUrl': 'https://images.unsplash.com/photo-1628840042765-356cda07504e?q=80&w=400&auto=format&fit=crop',
            'isHighlyReordered': false,
            'isAvailable': true,
            'isCustomisable': true,
          },
          {
            'id': 102,
            'isVeg': true,
            'isSpicy': true,
            'name': 'Peri Peri French Fries',
            'price': 209,
            'originalPrice': null,
            'description': 'Finely crafted peri peri flavoured Potato fingers served hot wit',
            'imageUrl': 'https://images.unsplash.com/photo-1541592106381-b31e9677c0e5?q=80&w=400&auto=format&fit=crop',
            'isHighlyReordered': true,
            'isAvailable': false, // Mocking an unavailable item
            'isCustomisable': true,
          }
        ];
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
            CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHotelHeader(),
                      _buildOffers(),
                      _buildFiltersRow(),
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
                              child: CircularProgressIndicator(color: zomatoRed),
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index == 0) {
                                return const Padding(
                                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                                  child: Text(
                                    'Items at ₹209',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: textDark,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                );
                              }
                              final item = _filteredMenuItems[index - 1];
                              return Column(
                                children: [
                                  _buildMenuItemCard(item),
                                  if (index < _filteredMenuItems.length)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 16),
                                      child: _DottedDivider(),
                                    ),
                                ],
                              );
                            },
                            childCount: _filteredMenuItems.length + 1,
                          ),
                        ),
                ),
              ],
            ),
            
            // Floating Menu Button
            Positioned(
              bottom: (_cartSummary != null && _cartSummary!.totalQuantity > 0) ? 88 : 24,
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
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: textDark),
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
              child: const Icon(Icons.group_add_outlined, size: 20, color: textDark),
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
              child: const Icon(Icons.more_vert_rounded, size: 20, color: textDark),
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
                Text('Pure Veg', style: TextStyle(color: vegGreen, fontSize: 11, fontWeight: FontWeight.bold)),
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
                    const Icon(Icons.info_outline_rounded, color: textGrey, size: 20),
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
                    const Text('4.2', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(width: 2),
                    const Icon(Icons.star_rounded, color: Colors.white, size: 16),
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
                style: const TextStyle(fontSize: 13, color: textGrey, fontWeight: FontWeight.w500),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, color: textGrey, size: 16),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: textGrey, size: 16),
              const SizedBox(width: 4),
              const Text(
                '35-40 mins • Schedule for later',
                style: TextStyle(fontSize: 13, color: textGrey, fontWeight: FontWeight.w500),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, color: textGrey, size: 16),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF2F2F2)),
        ],
      ),
    );
  }

  Widget _buildOffers() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_offer_rounded, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Flat ₹60 OFF above ₹249',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('7 offers', style: TextStyle(fontSize: 13, color: textGrey, fontWeight: FontWeight.w500)),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: textGrey, size: 16),
                ],
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          height: 8,
          color: const Color(0xFFF4F4F5),
        ),
      ],
    );
  }

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
            label: 'Price: Low to High',
            isSelected: _sortOption == 'low_to_high',
            onTap: () {
              setState(() {
                _sortOption = _sortOption == 'low_to_high' ? '' : 'low_to_high';
              });
            },
          ),
          const SizedBox(width: 10),
          _buildFilterChip(
            label: 'Price: High to Low',
            isSelected: _sortOption == 'high_to_low',
            onTap: () {
              setState(() {
                _sortOption = _sortOption == 'high_to_low' ? '' : 'high_to_low';
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
            iconWidget: const Icon(Icons.whatshot_rounded, color: zomatoRed, size: 16),
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
            width: 1
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: iconColor ?? textDark),
              const SizedBox(width: 6),
            ],
            if (iconWidget != null) ...[
              iconWidget,
              const SizedBox(width: 6),
            ],
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
                    if (item['isVeg'] == true) _buildVegIcon() else _buildNonVegIcon(),
                    if (item['isSpicy'] == true) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.whatshot_rounded, color: zomatoRed, size: 16),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                // Item Name
                Text(
                  item['name'],
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                    letterSpacing: -0.2,
                  ),
                ),
                // Price & Offers
                const SizedBox(height: 6),
                if (item['originalPrice'] != null) ...[
                  Text(
                    '₹${item['originalPrice']}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: textGrey,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Text(
                        'Get for ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        '₹${item['price']}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    '₹${item['price']}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                // Description
                RichText(
                  text: TextSpan(
                    text: item['description'],
                    style: const TextStyle(
                      fontSize: 13,
                      color: textGrey,
                      height: 1.4,
                    ),
                    children: const [
                      TextSpan(
                        text: '...more',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Action Buttons
                Row(
                  children: [
                    _buildActionButton(Icons.favorite_border_rounded),
                    const SizedBox(width: 12),
                    _buildActionButton(Icons.reply_rounded), // Share-like icon
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
                height: 140,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    // Image
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.grey.shade100,
                        image: DecorationImage(
                          image: NetworkImage(item['imageUrl']),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // Add Button
                    Positioned(
                      bottom: -16,
                      child: Container(
                        width: 110,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isAvailable ? const Color(0xFFFFF6F7) : Colors.grey.shade200, // Light red/pink tint
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isAvailable ? zomatoRed.withOpacity(0.3) : Colors.grey.shade400, width: 1),
                          boxShadow: isAvailable ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ] : null,
                        ),
                        alignment: Alignment.center,
                        child: !isAvailable
                            ? const Text(
                                'SOLD OUT',
                                style: TextStyle(
                                  color: textGrey,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              )
                            : (() {
                                final itemId = item['id'] ?? 0;
                                final qty = _getItemQuantity(itemId);
                                if (qty == 0) {
                                  return InkWell(
                                    onTap: () => _addToCart(itemId),
                                    borderRadius: BorderRadius.circular(8),
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
                                          top: 2,
                                          right: 8,
                                          child: Text(
                                            '+',
                                            style: TextStyle(
                                              color: zomatoRed.withOpacity(0.6),
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      InkWell(
                                        onTap: () => _updateCartQuantity(itemId, qty - 1),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          child: Text(
                                            '-',
                                            style: TextStyle(
                                              color: zomatoRed,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '$qty',
                                        style: const TextStyle(
                                          color: zomatoRed,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => _updateCartQuantity(itemId, qty + 1),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          child: Text(
                                            '+',
                                            style: TextStyle(
                                              color: zomatoRed,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }
                              }()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24), // Space for overlapping add button
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
      child: CustomPaint(
        painter: _TrianglePainter(color: zomatoRed),
      ),
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
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.grey.shade300),
              ),
            );
          }),
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
        );
      },
    );
  }
}
