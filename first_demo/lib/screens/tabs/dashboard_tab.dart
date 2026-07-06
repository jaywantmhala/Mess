import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/hotel.dart';
import '../../services/hotel_service.dart';
import '../hotel_details_screen.dart';
import '../hotel_menu_screen.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../models/address_data.dart';
import '../../services/address_service.dart';
import '../select_address_screen.dart';
import '../../services/wallet_service.dart';
import '../wallet_screen.dart';
import '../../services/order_service.dart';
import '../../models/order.dart';
import '../../services/websocket_service.dart';
import 'dart:async';
import '../order_status_screen.dart';

// =============================================================================
// HotelModel
// =============================================================================
class HotelModel {
  final String id;
  final String name;
  final double rating;
  final int reviews;
  final double distanceKm;
  final bool isOpen;
  final String tag; // e.g. "Pure Veg" — empty string if none
  final String deliveryTime; // e.g. "20-25 mins"
  final String costForTwo; // e.g. "₹₹₹"
  final String address;
  final String phone;
  final IconData icon;
  final List<Color> gradient;
  // Fractional position of the pin on the map, x/y in [-1, 1]
  final Alignment mapAlignment;
  final Hotel rawHotel;

  HotelModel({
    required this.id,
    required this.name,
    required this.rating,
    required this.reviews,
    required this.distanceKm,
    required this.isOpen,
    required this.tag,
    required this.deliveryTime,
    required this.costForTwo,
    required this.address,
    required this.phone,
    required this.icon,
    required this.gradient,
    required this.mapAlignment,
    required this.rawHotel,
  });

  String get distanceLabel => '${distanceKm.toStringAsFixed(1)} km away';
}

// =============================================================================
// Color palette — coral / warm-pink + white, matching the reference design.
// =============================================================================
class _HotelColors {
  static const coral = Color(0xFFFF6F5E);
  static const coralSoft = Color(0xFFFFEDE9);
  static const pageBg = Color(0xFFFFF3F1);
  static const mapBg = Color(0xFFF3E9E7);
  static const textDark = Color(0xFF2B2B2B);
  static const textGrey = Color(0xFF9A9A9A);
  static const success = Color(0xFF2ECC71);
  static const danger = Color(0xFFFF5252);
  static const amber = Color(0xFFFFB300);
  static const cardBorder = Color(0xFFF0F0F0);
}

// =============================================================================
// HotelLocatorDashboard — full page, NO sidebar (sidebar intentionally
// omitted per request). Contains: top bar, map panel with radius + pins,
// nearby-hotels list panel, and a bottom stats bar.
// =============================================================================
class HotelLocatorDashboard extends StatefulWidget {
  const HotelLocatorDashboard({super.key});

  @override
  State<HotelLocatorDashboard> createState() => _HotelLocatorDashboardState();
}

class _HotelLocatorDashboardState extends State<HotelLocatorDashboard> with SingleTickerProviderStateMixin {
  String? _selectedHotelId;

  Position? _userPosition;
  List<Hotel> _backendHotels = [];
  bool _isLoading = true;
  String _errorMessage = '';

  AddressData? _savedAddress;
  double? _walletBalance;
  OrderHistoryItem? _activeOrder;
  StreamSubscription? _wsSubscription;

  late ScrollController _scrollController;
  late AnimationController _radarController;
  bool _isMapHidden = false;

  Future<void> refreshWallet() async {
    try {
      final balanceData = await WalletService.instance.getBalance();
      if (mounted) {
        setState(() {
          _walletBalance = balanceData.balance;
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch wallet balance: $e');
    }
  }

  Future<void> _fetchActiveOrder() async {
    try {
      final history = await OrderService.instance.getHistory();
      if (history.isNotEmpty) {
        final latest = history.first;
        // Status flow: created_order, accepted, preparing, ready, completed, cancelled
        final activeStatuses = ['created_order', 'accepted', 'preparing', 'ready'];
        if (activeStatuses.contains(latest.status)) {
          if (mounted) {
            setState(() {
              _activeOrder = latest;
            });
          }
          return;
        }
      }
      if (mounted) {
        setState(() {
          _activeOrder = null;
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch active order: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _loadAddressAndHotels();
    refreshWallet();
    _fetchActiveOrder();
    WalletService.instance.balanceNotifier.addListener(_onWalletBalanceChanged);
    _startWebSocketListener();
  }

  void _startWebSocketListener() {
    // Make sure customer WS is connected
    WebSocketService.instance.connect();
    
    _wsSubscription = WebSocketService.instance.messages.listen((msg) {
      final event = msg['event'] as String?;
      if (event == 'ORDER_STATUS_UPDATED') {
        _fetchActiveOrder();
        refreshWallet(); // Refresh balance just in case it was deducted
      }
    });
  }

  void _onWalletBalanceChanged() {
    if (mounted) {
      setState(() {
        _walletBalance = WalletService.instance.balanceNotifier.value;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      if (_scrollController.offset > 50 && !_isMapHidden) {
        setState(() {
          _isMapHidden = true;
        });
      } else if (_scrollController.offset <= 10 && _isMapHidden) {
        setState(() {
          _isMapHidden = false;
        });
      }
    }
  }

  @override
  void dispose() {
    WalletService.instance.balanceNotifier.removeListener(_onWalletBalanceChanged);
    _wsSubscription?.cancel();
    _radarController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAddressAndHotels() async {
    try {
      final addr = await AddressService.instance.getAddress();
      if (mounted) {
        setState(() {
          _savedAddress = addr;
        });
      }
    } catch (_) {}
    await _fetchNearbyHotels();
  }

  /// Request permissions and fetch nearby hotels from backend based on current GPS location or selected custom address
  Future<void> _fetchNearbyHotels() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      double lat;
      double lng;

      if (_savedAddress != null && _savedAddress!.latitude != 0.0) {
        lat = _savedAddress!.latitude;
        lng = _savedAddress!.longitude;
        // Mock a Position so map calculations using _userPosition work correctly
        _userPosition = Position(
          latitude: lat,
          longitude: lng,
          timestamp: DateTime.now(),
          accuracy: 0.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
      } else {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          throw 'Location services are disabled.';
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            throw 'Location permissions are denied.';
          }
        }

        if (permission == LocationPermission.deniedForever) {
          throw 'Location permissions are permanently denied.';
        }

        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        _userPosition = position;
        lat = position.latitude;
        lng = position.longitude;
      }

      final hotelsList = await HotelService.instance.getNearbyHotels(
        latitude: lat,
        longitude: lng,
      );

      if (mounted) {
        setState(() {
          _backendHotels = hotelsList;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Fetch nearby hotels error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<HotelModel> get _hotels {
    if (_userPosition == null) return [];
    double userLat = _userPosition!.latitude;
    double userLng = _userPosition!.longitude;

    return _backendHotels.map((h) {
      double latDiff = h.latitude - userLat;
      double lngDiff = h.longitude - userLng;

      // rough km conversion for Pune/India (1 degree lat ~ 111km, 1 degree lng ~ 105km)
      double dyKm = latDiff * 111.0;
      double dxKm = lngDiff * 105.0;

      // 2 km corresponds to 0.72 magnitude on the mock map circle
      double alignX = (dxKm / 2.0) * 0.72;
      double alignY = -(dyKm / 2.0) * 0.72; // negative because North is up (-Y in alignment)

      Alignment mapAlignment = Alignment(
        alignX.clamp(-0.95, 0.95),
        alignY.clamp(-0.95, 0.95),
      );

      return HotelModel(
        id: h.id.toString(),
        name: h.hotelName,
        rating: 4.0 + (h.id % 9) * 0.1,
        reviews: 20 + h.id * 8,
        distanceKm: h.distance ?? 0.0,
        isOpen: true,
        tag: h.landmark != null && h.landmark!.isNotEmpty ? h.landmark! : 'Nearby',
        deliveryTime: '20-25 mins',
        costForTwo: '₹₹',
        address: h.hotelAddress,
        phone: h.mobileNumber,
        icon: Icons.storefront_rounded,
        gradient: const [Color(0xFFFFB199), Color(0xFFFF6F5E)],
        mapAlignment: mapAlignment,
        rawHotel: h,
      );
    }).toList();
  }

  Widget _buildActiveOrderBar() {
    if (_activeOrder == null) return const SizedBox.shrink();

    Color statusColor = Colors.orange;
    IconData statusIcon = Icons.query_builder_rounded;
    String statusText = 'Received';

    switch (_activeOrder!.status) {
      case 'created_order':
        statusColor = Colors.orange;
        statusIcon = Icons.query_builder_rounded;
        statusText = 'Received';
        break;
      case 'accepted':
        statusColor = Colors.blue;
        statusIcon = Icons.thumb_up_alt_rounded;
        statusText = 'Accepted';
        break;
      case 'preparing':
        statusColor = Colors.teal;
        statusIcon = Icons.flatware_rounded;
        statusText = 'Preparing';
        break;
      case 'ready':
        statusColor = Colors.indigo;
        statusIcon = Icons.inventory_2_rounded;
        statusText = 'Ready for pickup';
        break;
    }

    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: GestureDetector(
        onTap: _showActiveOrderDialog,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1F1F2E),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  statusIcon,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _activeOrder!.hotelName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Order #${_activeOrder!.orderId} • $statusText',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withOpacity(0.4), width: 1),
                ),
                child: Text(
                  statusText.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActiveOrderDialog() {
    if (_activeOrder == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderStatusScreen(initialOrder: _activeOrder!),
      ),
    );
  }

  String _getStatusTextLabel(String status) {
    switch (status) {
      case 'created_order':
        return 'Order Received';
      case 'accepted':
        return 'Order Accepted';
      case 'preparing':
        return 'Preparing your Meal';
      case 'ready':
        return 'Ready for Pickup / Delivery';
      case 'completed':
        return 'Delivered';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _HotelColors.pageBg,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            final screenWidth = constraints.maxWidth;

            return Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                      child: _buildAddressHeader(),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      height: _isMapHidden ? 0 : 200, // 180 map + 20 spacing
                    ),
                    Expanded(
                      child: _buildHotelListPanel(),
                    ),
                  ],
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  top: _isMapHidden ? -150 : 82, // Slides up off-screen
                  left: 20,
                  right: 20,
                  height: 180,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _isMapHidden ? 0.0 : 1.0,
                    child: _buildMapPanel(),
                  ),
                ),
                // Floating Active Order Status Bar
                _buildActiveOrderBar(),
              ],
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Premium Address Header Row
  // ---------------------------------------------------------------------
  Widget _buildWalletBalanceChip() {
    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const WalletScreen(),
          ),
        );
        refreshWallet(); // Refresh when returning
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFECEB), // Light coral/pink tint
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFC5BD), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.account_balance_wallet_rounded,
              color: _HotelColors.coral,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              _walletBalance != null
                  ? '₹${_walletBalance!.toStringAsFixed(2)}'
                  : '₹--',
              style: const TextStyle(
                color: _HotelColors.textDark,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressHeader() {
    final hasAddress = _savedAddress != null && _savedAddress!.fullAddress.isNotEmpty;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left side: Address picker (tappable)
        Expanded(
          child: InkWell(
            onTap: _openAddressPicker,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: _HotelColors.coralSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: _HotelColors.coral,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasAddress ? 'Delivering to' : 'Set location',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: _HotelColors.textGrey,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                hasAddress
                                    ? _savedAddress!.shortLabel
                                    : 'Add Address',
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: _HotelColors.textDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: _HotelColors.coral,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Right side: Wallet balance chip
        _buildWalletBalanceChip(),
      ],
    );
  }

  Future<void> _openAddressPicker() async {
    final result = await Navigator.push<AddressData>(
      context,
      MaterialPageRoute(
        builder: (context) => const SelectAddressScreen(),
      ),
    );

    if (result != null) {
      await AddressService.instance.saveAddress(result);
      if (mounted) {
        setState(() {
          _savedAddress = result;
        });
        await _fetchNearbyHotels();
      }
    }
  }



  // ---------------------------------------------------------------------
  // Map panel: radius circle + hotel pins + zoom/locate controls + filters
  // ---------------------------------------------------------------------
  Widget _buildMapPanel() {
    return Container(
      decoration: BoxDecoration(
        color: _HotelColors.mapBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _StreetGridPainter())),

          // Faint area labels
          const Positioned(
            top: 24,
            left: 24,
            child: _AreaLabel('Shivajinagar'),
          ),
          const Positioned(
            top: 16,
            right: 28,
            child: _AreaLabel('Kalyani Nagar'),
          ),
          const Positioned(
            top: 100,
            right: 40,
            child: _AreaLabel('Viman Nagar'),
          ),
          const Positioned(bottom: 90, left: 20, child: _AreaLabel('Kothrud')),
          const Positioned(
            bottom: 60,
            right: 30,
            child: _AreaLabel('Hadapsar'),
          ),
          const Positioned(bottom: 24, left: 90, child: _AreaLabel('Warje')),
          const Positioned(bottom: 24, right: 90, child: _AreaLabel('NIBM')),

          // Radius circle + center dot + pins
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, box) {
                final size = box.biggest;
                final radius = math.min(size.width, size.height) * 0.36;
                final center = Offset(size.width / 2, size.height / 2);

                return Stack(
                  children: [
                    AnimatedBuilder(
                      animation: _radarController,
                      builder: (context, child) {
                        return CustomPaint(
                          size: size,
                          painter: _RadarPainter(
                            center: center,
                            radius: radius,
                            animationValue: _radarController.value,
                          ),
                        );
                      },
                    ),
                    Positioned(
                      left: center.dx - 9,
                      top: center.dy - 9,
                      child: const _CenterDot(),
                    ),
                    for (final hotel in _hotels)
                      Align(
                        alignment: hotel.mapAlignment,
                        child: _MapPin(
                          hotel: hotel,
                          selected: _selectedHotelId == hotel.id,
                          onTap: () => setState(() => _selectedHotelId = hotel.id),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // "Showing hotels within 2 km" chip
          Positioned(
            top: 16,
            left: 16,
            child: _floatingChip(
              icon: Icons.info_outline_rounded,
              text: 'Showing hotels within 2 km',
              filled: true,
            ),
          ),

          // Controls
          Positioned(
            bottom: 12,
            right: 12,
            child: Column(
              children: [
                _mapControlButton(Icons.refresh_rounded, onTap: _fetchNearbyHotels),
                const SizedBox(height: 8),
                _mapControlButton(Icons.my_location_rounded, onTap: _fetchNearbyHotels),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _floatingChip({
    IconData? icon,
    bool dot = false,
    required String text,
    bool filled = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: filled ? _HotelColors.coralSoft : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, size: 14, color: _HotelColors.coral)
          else if (dot)
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _HotelColors.coralSoft,
                border: Border.all(color: _HotelColors.coral, width: 1.4),
              ),
            ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _HotelColors.coral,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapControlButton(IconData icon, {required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 18, color: _HotelColors.textDark),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Right-hand "Nearby Hotels" list panel
  // ---------------------------------------------------------------------
  Widget _buildHotelListPanel() {
    final hotels = List<HotelModel>.from(_hotels)..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nearby Hotels (${hotels.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _HotelColors.textDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: _HotelColors.cardBorder),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: const [
                    Text(
                      'Sort by: Nearest',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _HotelColors.textDark,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _HotelColors.coral),
                  )
                : hotels.isEmpty
                    ? Center(
                        child: Text(
                          _errorMessage.isNotEmpty ? _errorMessage : 'No hotels found',
                          style: const TextStyle(color: _HotelColors.textGrey),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        itemCount: hotels.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final hotel = hotels[index];
                          return _ZomatoHotelCard(
                            hotel: hotel,
                            onTap: () async {
                              final orderPlaced = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => HotelMenuScreen(
                                    hotel: hotel.rawHotel,
                                  ),
                                ),
                              );
                              if (orderPlaced == true) {
                                refreshWallet();
                                await _fetchActiveOrder();
                                if (_activeOrder != null && mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OrderStatusScreen(initialOrder: _activeOrder!),
                                    ),
                                  );
                                }
                              }
                            },
                          );
                        },
                      ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------

}

// =============================================================================
// Small stateless helper widgets
// =============================================================================
class _AreaLabel extends StatelessWidget {
  final String text;
  const _AreaLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        color: _HotelColors.textGrey.withOpacity(0.7),
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _CenterDot extends StatelessWidget {
  const _CenterDot({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF3B82F6),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  final HotelModel hotel;
  final bool selected;
  final VoidCallback onTap;

  const _MapPin({
    super.key,
    required this.hotel,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _HotelColors.coral,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.storefront_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4),
              ],
            ),
            child: Text(
              '${hotel.distanceKm.toStringAsFixed(1)} km',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: hotel.distanceKm > 2.0 ? _HotelColors.danger : _HotelColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreetGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1.2;

    const step = 46.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RadarPainter extends CustomPainter {
  final Offset center;
  final double radius;
  final double animationValue;

  _RadarPainter({
    required this.center,
    required this.radius,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()..color = _HotelColors.coral.withOpacity(0.06);
    canvas.drawCircle(center, radius, fillPaint);

    final dashPaint = Paint()
      ..color = _HotelColors.coral.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    const dashWidth = 6.0;
    const dashSpace = 5.0;
    final circumference = 2 * math.pi * radius;
    final dashCount = (circumference / (dashWidth + dashSpace)).floor();
    final angleStep = (2 * math.pi) / dashCount;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * angleStep;
      final endAngle = startAngle + (dashWidth / radius);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        endAngle - startAngle,
        false,
        dashPaint,
      );
    }

    // Radar Sweep
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          _HotelColors.coral.withOpacity(0.0),
          _HotelColors.coral.withOpacity(0.1),
          _HotelColors.coral.withOpacity(0.5),
          _HotelColors.coral.withOpacity(0.0),
        ],
        stops: const [0.0, 0.7, 0.99, 1.0],
        transform: GradientRotation(animationValue * 2 * math.pi),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) =>
      oldDelegate.center != center ||
      oldDelegate.radius != radius ||
      oldDelegate.animationValue != animationValue;
}

class _ZomatoHotelCard extends StatelessWidget {
  final HotelModel hotel;
  final VoidCallback onTap;

  const _ZomatoHotelCard({required this.hotel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image area
            Stack(
              children: [
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: _HotelColors.cardBorder,
                    image: hotel.rawHotel.photoUrl != null && hotel.rawHotel.photoUrl!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(hotel.rawHotel.photoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: (hotel.rawHotel.photoUrl == null || hotel.rawHotel.photoUrl!.isEmpty)
                      ? Icon(hotel.icon, color: _HotelColors.textGrey, size: 50)
                      : null,
                ),
                // Top Left Tag
                if (hotel.tag.isNotEmpty || hotel.isOpen)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            hotel.isOpen ? Icons.stars_rounded : Icons.cancel_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            hotel.isOpen ? (hotel.tag.isNotEmpty ? hotel.tag : 'Open Now') : 'Closed',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Top Right Bookmark
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.bookmark_border_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Ad tag
                Positioned(
                  top: 16,
                  right: 48,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Ad',
                      style: TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            // Content below image
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          hotel.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _HotelColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF24963F), // Zomato green
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  hotel.rating.toString(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.star_rounded, size: 12, color: Colors.white),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'For you',
                            style: TextStyle(fontSize: 10, color: _HotelColors.textGrey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 14, color: _HotelColors.textGrey),
                      const SizedBox(width: 4),
                      Text(
                        hotel.deliveryTime,
                        style: const TextStyle(fontSize: 11, color: _HotelColors.textGrey),
                      ),
                      const SizedBox(width: 6),
                      const Text('•', style: TextStyle(color: _HotelColors.textGrey)),
                      const SizedBox(width: 6),
                      Text(
                        hotel.distanceLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: hotel.distanceKm > 2.0 ? _HotelColors.danger : _HotelColors.textGrey,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('•', style: TextStyle(color: _HotelColors.textGrey)),
                      const SizedBox(width: 6),
                      const Icon(Icons.delivery_dining_rounded, size: 13, color: _HotelColors.textGrey),
                      const SizedBox(width: 3),
                      const Text(
                        'Free',
                        style: TextStyle(fontSize: 11, color: _HotelColors.textGrey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Offer row
                  Row(
                    children: [
                      const Icon(Icons.local_offer_rounded, size: 13, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                        'Flat ₹40 OFF above ₹99',
                        style: TextStyle(fontSize: 11, color: Colors.blue[700], fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Dashed divider replacement (solid light line for simplicity)
                  const Divider(color: Color(0xFFEEEEEE), height: 1, thickness: 1),
                  const SizedBox(height: 8),
                  // Bottom tags
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.eco_rounded,
                              size: 14,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              hotel.tag.isNotEmpty ? hotel.tag : 'Pure Veg restaurant',
                              style: const TextStyle(fontSize: 11, color: _HotelColors.textGrey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

