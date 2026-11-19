import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/hotel.dart';
import '../services/hotel_service.dart';
import '../services/address_service.dart';
import '../services/ably_service.dart';
import 'hotel_menu_screen.dart';
import '../utils/app_config.dart';

class HotelsNearYouScreen extends StatefulWidget {
  const HotelsNearYouScreen({super.key});

  @override
  State<HotelsNearYouScreen> createState() => _HotelsNearYouScreenState();
}

class _HotelsNearYouScreenState extends State<HotelsNearYouScreen> {
  // ── Design Tokens matching reference photo 100% ────────────────────────────
  static const Color _brandOrange  = Color(0xFFF58220);
  static const Color _bgWarm       = Color(0xFFFAFAFA);
  static const Color _white        = Colors.white;
  static const Color _ink          = Color(0xFF1A1A2E);
  static const Color _greySub      = Color(0xFF6B7280);
  static const Color _cardBorder   = Color(0xFFE5E7EB);
  static const Color _greenBadge   = Color(0xFFE6F4EA);
  static const Color _greenText    = Color(0xFF137333);

  List<Hotel> _allHotels = [];       // Unfiltered hotels from API
  List<Hotel> _hotels = [];          // Displayed (possibly filtered) hotels
  bool _isLoading = true;
  String _errorMessage = '';
  String _foodTypeFilter = 'ALL';    // 'ALL', 'VEG', 'NON-VEG'

  // ── Distance-based filter state ────────────────────────────────────────────
  String? _serviceFilter;            // null = no filter, 'DELIVERY', or 'DINING'
  bool _popupShown = false;          // Prevents showing the popup more than once
  bool _isWaitingForPopupChoice = false; // Block hotel list until user makes a choice if away

  StreamSubscription? _ablySubscription;
  Timer? _webPollTimer;

  @override
  void initState() {
    super.initState();
    AblyService.instance.connect();
    _ablySubscription = AblyService.instance.messages.listen(_handleAblyMessage);
    if (kIsWeb) {
      _webPollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchHotels(silent: true));
    }
    _checkDistanceFromAddress();
  }

  @override
  void dispose() {
    _ablySubscription?.cancel();
    _webPollTimer?.cancel();
    super.dispose();
  }

  /// Real-time Ably handler when vendor toggles online/offline status
  void _handleAblyMessage(Map<String, dynamic> msg) {
    final event = msg['event'] as String?;
    final data = msg['data'];
    debugPrint('HotelsNearYouScreen: Received Ably Event: $event, Data: $data');

    if (event == 'VENDOR_STATUS_UPDATED' ||
        event == 'HOTEL_STATUS_UPDATED' ||
        event == 'VENDOR_ONLINE_STATUS_CHANGED') {
      if (data == null) {
        debugPrint('HotelsNearYouScreen: Ably Event Data is null');
        return;
      }
      int? vId;
      if (data is Map) {
        vId = data['vendor_id'] != null
            ? int.tryParse(data['vendor_id'].toString())
            : null;
      }
      final isOnline = data is Map
          ? (data['is_online'] == true ||
              data['is_online'] == 1 ||
              data['is_online'].toString() == '1')
          : true;

      debugPrint('HotelsNearYouScreen: Parsed vId: $vId, isOnline: $isOnline');

      if (vId != null && mounted) {
        setState(() {
          _allHotels = _allHotels
              .map((h) => h.vendorId == vId
                  ? h.copyWith(isVendorOnline: isOnline)
                  : h)
              .toList();

          _hotels = _hotels
              .map((h) => h.vendorId == vId
                  ? h.copyWith(isVendorOnline: isOnline)
                  : h)
              .toList();
          debugPrint('HotelsNearYouScreen: Updated _hotels and _allHotels status for vendor $vId to isOnline=$isOnline');
        });
      } else {
        debugPrint('HotelsNearYouScreen: Update skipped. vId is null or widget is not mounted.');
      }
    }
  }

  /// Checks saved address + live GPS location in parallel.
  /// If distance > 700m, shows the popup FIRST and holds hotel list loading.
  Future<void> _checkDistanceFromAddress() async {
    try {
      final results = await Future.wait([
        AddressService.instance.getAddress(),
        _getLiveGpsPosition(),
      ]);

      final addr = results[0] as dynamic;  // AddressData?
      final gpsPos = results[1] as Position?;

      if (!mounted) return;

      if (addr != null && addr.latitude != 0.0 && gpsPos != null && !_popupShown) {
        final distanceMeters = Geolocator.distanceBetween(
          gpsPos.latitude, gpsPos.longitude,
          addr.latitude, addr.longitude,
        );

        if (distanceMeters > 700) {
          _popupShown = true;
          setState(() {
            _isWaitingForPopupChoice = true;
          });
          // Show popup FIRST
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showServiceTypePopup(distanceMeters);
          });
          // Also fetch hotels in background so they are ready when user taps option
          _fetchHotels(silent: true);
          return;
        }
      }

      // If within 700m or no address/GPS, load hotels normally
      _fetchHotels();
    } catch (e) {
      debugPrint('Distance check error: $e');
      _fetchHotels();
    }
  }

  /// Gets the live GPS position, returns null if unavailable.
  Future<Position?> _getLiveGpsPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('GPS position error: $e');
      return null;
    }
  }

  Future<void> _fetchHotels({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final addr = await AddressService.instance.getAddress();
      double lat = 18.5204, lng = 73.8567;
      if (addr != null && addr.latitude != 0.0) {
        lat = addr.latitude;
        lng = addr.longitude;
      } else {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
            final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
            lat = pos.latitude;
            lng = pos.longitude;
          }
        }
      }

      final res = await HotelService.instance.getNearbyHotels(latitude: lat, longitude: lng);
      if (mounted) {
        final allHotels = res.hotels.where((h) => (h.distance ?? 0) <= 3.0).toList();
        setState(() {
          _allHotels = allHotels;
          _applyCombinedFilters();
          _errorMessage = res.message ?? '';
          if (!silent) _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && !silent) setState(() { _errorMessage = e.toString(); _isLoading = false; });
    }
  }

  /// Exact replica popup design matching reference image 100%
  void _showServiceTypePopup(double distanceMeters) {
    final distanceText = distanceMeters >= 1000
        ? '${(distanceMeters / 1000).toStringAsFixed(1)} km'
        : '${distanceMeters.toInt()} m';

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true, // Allows sheet to expand cleanly without 50% screen height overflow
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Drag Handle Bar ──────────────────────────────────────────
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2D9CF),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // ── Top Illustration Graphic ──────────────────────────────────
                  const _LocationIllustration(),
                  const SizedBox(height: 8),

                  // ── Main Headline ────────────────────────────────────────────
                  const Text(
                    'You are away from\nyour selected address',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF064E3B), // Dark green
                      height: 1.2,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Distance Tag Pill ─────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFFFFEDD5), width: 1.2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFF7ED),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on_outlined,
                            color: Color(0xFFEA580C),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 4),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '$distanceText ',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFEA580C),
                                ),
                              ),
                              const TextSpan(
                                text: 'away from selected address',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Subtitle Question ─────────────────────────────────────────
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      style: TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                      children: [
                        TextSpan(text: 'How would you like to '),
                        TextSpan(
                          text: 'enjoy your meal?',
                          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF064E3B)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Two Option Cards (Delivery & Dining) ─────────────────────
                  Row(
                    children: [
                      // ── Delivery Card ──────────────────────────────────────────
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx);
                            setState(() {
                              _isWaitingForPopupChoice = false;
                              _isLoading = false;
                            });
                            _applyFilter('DELIVERY');
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4), // Light mint green
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
                            ),
                            child: Column(
                              children: [
                                // White Avatar Circle
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.delivery_dining_rounded,
                                      color: Color(0xFF064E3B),
                                      size: 26,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Delivery',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF064E3B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Get it delivered\nto your doorstep',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF4B5563),
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // Dark Green Button with Arrow
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF064E3B),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // ── Dining Card ────────────────────────────────────────────
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx);
                            setState(() {
                              _isWaitingForPopupChoice = false;
                              _isLoading = false;
                            });
                            _applyFilter('DINING');
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED), // Light cream orange
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFFDBA74), width: 1.5),
                            ),
                            child: Column(
                              children: [
                                // White Avatar Circle
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.restaurant_rounded,
                                      color: Color(0xFFEA580C),
                                      size: 24,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Dining',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFEA580C),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Dine at mess\nand enjoy',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF4B5563),
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // Bright Orange Button with Arrow
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF97316),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 16,
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Applies the Delivery or Dining filter to the hotel list.
  void _applyFilter(String filter) {
    _serviceFilter = filter;
    _applyCombinedFilters();
  }

  /// Clears the active service filter and shows all hotels again.
  void _clearFilter() {
    _serviceFilter = null;
    _applyCombinedFilters();
  }

  /// Combined filter for serviceType (DELIVERY/DINING) and foodType (VEG/NON-VEG/ALL).
  void _applyCombinedFilters() {
    setState(() {
      List<Hotel> filtered = List.from(_allHotels);

      // 1. Filter by Service Type (DELIVERY or DINING)
      if (_serviceFilter == 'DELIVERY') {
        filtered = filtered.where((h) => h.serviceType == 'DELIVERY' || h.serviceType == 'BOTH').toList();
      } else if (_serviceFilter == 'DINING') {
        filtered = filtered.where((h) => h.serviceType == 'DINING' || h.serviceType == 'BOTH').toList();
      }

      // 2. Filter by Food Type (VEG or BOTH)
      if (_foodTypeFilter == 'VEG') {
        filtered = filtered.where((h) {
          final ft = h.foodType.toUpperCase();
          return ft == 'VEG';
        }).toList();
      } else if (_foodTypeFilter == 'BOTH' || _foodTypeFilter == 'NON-VEG' || _foodTypeFilter == 'NON_VEG') {
        filtered = filtered.where((h) {
          final ft = h.foodType.toUpperCase();
          return ft == 'BOTH' || ft == 'NON-VEG' || ft == 'NON_VEG' || ft == '';
        }).toList();
      }

      _hotels = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isWide = mq.size.width > 600;

    return Scaffold(
      backgroundColor: _bgWarm,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWide ? 540 : double.infinity),
            child: Column(
              children: [
                // ── Top Header Navigation Bar ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row( // header
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(Icons.chevron_left_rounded, color: _ink, size: 28),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Messes Near You',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: _ink,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Messes available under your plan',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: _greySub,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Filter Button Top Right
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _cardBorder, width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.filter_list_rounded, color: _ink, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Filter',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Veg / Non-Veg / All Segmented Toggle Bar ─────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _cardBorder, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // ALL Segment
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              _foodTypeFilter = 'ALL';
                              _applyCombinedFilters();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _foodTypeFilter == 'ALL' ? _ink : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  'ALL',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: _foodTypeFilter == 'ALL' ? Colors.white : _greySub,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),

                        // PURE VEG Segment
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              _foodTypeFilter = 'VEG';
                              _applyCombinedFilters();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _foodTypeFilter == 'VEG' ? const Color(0xFFE6F4EA) : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: _foodTypeFilter == 'VEG' ? Border.all(color: const Color(0xFF137333), width: 1.5) : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 13,
                                    height: 13,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: const Color(0xFF137333), width: 1.4),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: 5,
                                        height: 5,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF137333),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'PURE VEG',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: _foodTypeFilter == 'VEG' ? const Color(0xFF137333) : _greySub,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),

                        // VEG & NON-VEG Segment
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              _foodTypeFilter = 'BOTH';
                              _applyCombinedFilters();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: (_foodTypeFilter == 'BOTH' || _foodTypeFilter == 'NON-VEG') ? const Color(0xFFFFF7ED) : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: (_foodTypeFilter == 'BOTH' || _foodTypeFilter == 'NON-VEG') ? Border.all(color: const Color(0xFFEA580C), width: 1.5) : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: const Color(0xFFEA580C), width: 1.4),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.set_meal_rounded, size: 7, color: Color(0xFFEA580C)),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'VEG & NON-VEG',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: (_foodTypeFilter == 'BOTH' || _foodTypeFilter == 'NON-VEG') ? const Color(0xFFEA580C) : _greySub,
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
                ),

                // ── Active Filter Chip (shown only when a filter is active) ──
                if (_serviceFilter != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: _serviceFilter == 'DELIVERY'
                                ? const Color(0xFFEFF6FF)
                                : const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _serviceFilter == 'DELIVERY'
                                  ? const Color(0xFF3B82F6)
                                  : const Color(0xFFF59E0B),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _serviceFilter == 'DELIVERY'
                                    ? Icons.delivery_dining_rounded
                                    : Icons.restaurant_rounded,
                                size: 15,
                                color: _serviceFilter == 'DELIVERY'
                                    ? const Color(0xFF1D4ED8)
                                    : const Color(0xFFC2410C),
                              ),
      
                              Text(
                                _serviceFilter == 'DELIVERY'
                                    ? 'Showing Delivery messes'
                                    : 'Showing Dining messes',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: _serviceFilter == 'DELIVERY'
                                      ? const Color(0xFF1D4ED8)
                                      : const Color(0xFFC2410C),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _clearFilter,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _serviceFilter == 'DELIVERY'
                                        ? const Color(0xFF3B82F6).withOpacity(0.15)
                                        : const Color(0xFFF59E0B).withOpacity(0.15),
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 14,
                                    color: _serviceFilter == 'DELIVERY'
                                        ? const Color(0xFF1D4ED8)
                                        : const Color(0xFFC2410C),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Mess count
                        Text(
                          '${_hotels.length} mess${_hotels.length == 1 ? '' : 'es'}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _greySub,
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Messes List ───────────────────────────────────────────
                Expanded(
                  child: (_isLoading || _isWaitingForPopupChoice)
                      ? const Center(child: CircularProgressIndicator(color: _brandOrange))
                      : _hotels.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.storefront_outlined, size: 56, color: _greySub),
                                  const SizedBox(height: 12),
                                  Text(
                                    _serviceFilter != null
                                        ? 'No ${_serviceFilter == 'DELIVERY' ? 'delivery' : 'dining'} messes available nearby.'
                                        : (_errorMessage.isNotEmpty ? _errorMessage : 'No messes available nearby.'),
                                    style: const TextStyle(fontSize: 14, color: _greySub, fontWeight: FontWeight.w600),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (_serviceFilter != null) ...[
                                    const SizedBox(height: 16),
                                    GestureDetector(
                                      onTap: _clearFilter,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: _brandOrange.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: _brandOrange.withOpacity(0.3)),
                                        ),
                                        child: const Text(
                                          'Show all messes',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: _brandOrange,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            )
                          : ListView.builder(
                              physics: const ClampingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: _hotels.length,
                              itemBuilder: (context, index) {
                                final hotel = _hotels[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildHotelCard(hotel, index),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHotelCard(Hotel hotel, int index) {
    final isVegOnly = (index % 2 == 0);
    final ratingStr = (4.3 + (index % 5) * 0.1).toStringAsFixed(1);
    final distStr = hotel.distance != null ? '${hotel.distance!.toStringAsFixed(1)} km' : '1.2 km';
    final discountText = index % 2 == 0 ? '10% OFF up to ₹50' : '15% OFF up to ₹75';
    final isOnline = hotel.isVendorOnline;

    return GestureDetector(
      onTap: isOnline
          ? () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => HotelMenuScreen(hotel: hotel)),
              )
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${hotel.hotelName} is currently CLOSED and not accepting orders.'),
                  backgroundColor: const Color(0xFFDC2626),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
      child: Opacity(
        opacity: isOnline ? 1.0 : 0.65,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isOnline ? _cardBorder : const Color(0xFFFCA5A5),
              width: 1.2,
            ),
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
              // Left Hotel Image Thumbnail
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: hotel.photoUrl?.isNotEmpty == true
                        ? Image.network(
                            hotel.photoUrl!.startsWith('http')
                                ? hotel.photoUrl!
                                : '$kBaseUrl${hotel.photoUrl!.startsWith('/') ? '' : '/'}${hotel.photoUrl}',
                            width: 82,
                            height: 82,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              width: 82,
                              height: 82,
                              color: const Color(0xFFFFF0E6),
                              child: const Icon(Icons.restaurant_rounded, color: _brandOrange, size: 36),
                            ),
                          )
                        : Container(
                            width: 82,
                            height: 82,
                            color: const Color(0xFFFFF0E6),
                            child: const Icon(Icons.restaurant_rounded, color: _brandOrange, size: 36),
                          ),
                  ),
                  if (!isOnline)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_rounded, color: Colors.white, size: 18),
                              SizedBox(height: 2),
                              Text(
                                'CLOSED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Middle Info Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            hotel.hotelName,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w900,
                              color: isOnline ? _ink : Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isOnline) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFFCA5A5), width: 1),
                            ),
                            child: const Text(
                              'CLOSED',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),

                    // Cuisines Subtitle
                    Text(
                      hotel.landmark?.isNotEmpty == true
                          ? hotel.landmark!
                          : (isVegOnly ? 'Pure Veg, South Indian, Thalis' : 'North Indian, Thalis, Biryani'),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: _greySub,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Rating & Delivery Info Row
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Text(
                            ratingStr,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                          const SizedBox(width: 4),
                          const Text('•', style: TextStyle(color: _greySub, fontSize: 12)),
                          const SizedBox(width: 4),
                          const Text('20-25 mins', style: TextStyle(color: _greySub, fontSize: 11.5, fontWeight: FontWeight.w500)),
                          const SizedBox(width: 4),
                          const Text('•', style: TextStyle(color: _greySub, fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(distStr, style: const TextStyle(color: _greySub, fontSize: 11.5, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        /*
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isOnline ? _greenBadge : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            discountText,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: isOnline ? _greenText : Colors.grey.shade600,
                            ),
                          ),
                        ),

                        */ _buildFoodTypeBadge(hotel.foodType),

                        _buildServiceTypeBadge(hotel.serviceType),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceTypeBadge(String serviceType) {
    final st = serviceType.toUpperCase();
    String label = 'Dining & Delivery';
    IconData icon = Icons.two_wheeler_rounded;
    Color bg = const Color(0xFFECFDF5);
    Color border = const Color(0xFFA7F3D0);
    Color textCol = const Color(0xFF047857);

    if (st == 'DINING') {
      label = 'Dining';
      icon = Icons.restaurant_rounded;
      bg = const Color(0xFFFFF7ED);
      border = const Color(0xFFFFEDD5);
      textCol = const Color(0xFFC2410C);
    } else if (st == 'DELIVERY') {
      label = 'Delivery';
      icon = Icons.delivery_dining_rounded;
      bg = const Color(0xFFEFF6FF);
      border = const Color(0xFFBFDBFE);
      textCol = const Color(0xFF1D4ED8);
    } else {
      label = 'Dining & Delivery';
      icon = Icons.two_wheeler_rounded;
      bg = const Color(0xFFECFDF5);
      border = const Color(0xFFA7F3D0);
      textCol = const Color(0xFF047857);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: textCol),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: textCol,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodTypeBadge(String foodType) {
    final ft = foodType.toUpperCase();
    String label = 'Veg & Non-Veg';
    Color bg = const Color(0xFFFFF7ED);
    Color border = const Color(0xFFFFEDD5);
    Color textCol = const Color(0xFFC2410C);
    Widget icon = const SizedBox.shrink();

    if (ft == 'VEG') {
      label = 'Pure Veg';
      bg = const Color(0xFFE6F4EA);
      border = const Color(0xFFA8DAB5);
      textCol = const Color(0xFF137333);
      icon = Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF137333), width: 1.2),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Center(
          child: Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Color(0xFF137333),
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    } else {
      label = 'Veg & Non-Veg';
      bg = const Color(0xFFFFF7ED);
      border = const Color(0xFFFFEDD5);
      textCol = const Color(0xFFC2410C);
      icon = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7, height: 7,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF137333), width: 1),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Center(child: Container(width: 3, height: 3, decoration: const BoxDecoration(color: Color(0xFF137333), shape: BoxShape.circle))),
          ),
          const SizedBox(width: 2),
          Container(
            width: 7, height: 7,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFC5221F), width: 1),
              borderRadius: BorderRadius.circular(2),
            ),
            child: const Center(child: Icon(Icons.change_history_rounded, size: 4, color: Color(0xFFC5221F))),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: textCol,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom Illustration matching reference image
class _LocationIllustration extends StatelessWidget {
  const _LocationIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 85,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // ── Soft Cream/Yellow Backdrop Circle ──────────────────────────────
          Positioned(
            top: 0,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFF7ED).withOpacity(0.9),
              ),
            ),
          ),

          // ── Background City Buildings Silhouette ───────────────────────────
          Positioned(
            bottom: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBuilding(10, 20),
                const SizedBox(width: 3),
                _buildBuilding(14, 30),
                const SizedBox(width: 3),
                _buildBuilding(16, 38),
                const SizedBox(width: 20), // Center gap for pin
                _buildBuilding(14, 34),
                const SizedBox(width: 3),
                _buildBuilding(12, 24),
                const SizedBox(width: 3),
                _buildBuilding(10, 18),
              ],
            ),
          ),

          // ── Ground Hill Arc ────────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 10,
            right: 10,
            child: Container(
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(100)),
                border: Border.all(color: const Color(0xFFA7F3D0).withOpacity(0.6), width: 1),
              ),
            ),
          ),

          // ── Dotted Vertical Line ───────────────────────────────────────────
          Positioned(
            bottom: 12,
            top: 36,
            child: Column(
              children: List.generate(
                3,
                (_) => Container(
                  width: 2,
                  height: 2.5,
                  margin: const EdgeInsets.symmetric(vertical: 1),
                  color: const Color(0xFFF97316).withOpacity(0.7),
                ),
              ),
            ),
          ),

          // ── Left Plant / Leaf ──────────────────────────────────────────────
          Positioned(
            left: 32,
            bottom: 10,
            child: const Icon(
              Icons.eco_rounded,
              color: Color(0xFF15803D),
              size: 14,
            ),
          ),

          // ── Right Plant / Leaf ─────────────────────────────────────────────
          Positioned(
            right: 32,
            bottom: 10,
            child: const Icon(
              Icons.eco_rounded,
              color: Color(0xFF15803D),
              size: 14,
            ),
          ),

          // ── Bright Orange Pin with Location Off Icon ───────────────────────
          Positioned(
            top: 4,
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFFF97316),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x33F97316),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.location_off_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuilding(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9).withOpacity(0.85),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
    );
  }
}
