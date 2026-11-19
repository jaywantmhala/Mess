// lib/screens/vendor_order_tracking_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../models/order.dart';
import '../services/order_service.dart';
import '../services/websocket_service.dart';
import '../utils/app_config.dart';
import '../widgets/vendor_order_chat_sheet.dart';

const Color _kPrimary = Color(0xFFE23744); // Zomato / Zepto signature red
const Color _kPrimarySurface = Color(0xFFFFF0F0);
const Color _kDark = Color(0xFF1E293B);
const Color _kSubtle = Color(0xFF64748B);
const Color _kGreen = Color(0xFF10B981);
const Color _kGreenSurface = Color(0xFFECFDF5);
const Color _kAmber = Color(0xFFF59E0B);

class VendorOrderTrackingScreen extends StatefulWidget {
  final VendorOrder order;

  const VendorOrderTrackingScreen({
    super.key,
    required this.order,
  });

  @override
  State<VendorOrderTrackingScreen> createState() => _VendorOrderTrackingScreenState();
}

class _VendorOrderTrackingScreenState extends State<VendorOrderTrackingScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late AnimationController _pulseController;

  StreamSubscription? _wsSubscription;
  Timer? _pollTimer;

  // Locations
  LatLng? _driverLocation;
  LatLng? _customerLocation;
  LatLng? _hotelLocation;

  // Route
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;

  // Tracking Meta
  String _orderStatus = '';
  String _driverName = '';
  String _driverPhone = '';
  String _vehicleNumber = '';
  bool _driverIsOnline = false;
  String _customerName = '';
  String _customerPhone = '';
  String _deliveryAddress = '';
  String _hotelName = '';
  String _hotelAddress = '';
  double _distanceKm = 0.0;
  int _etaMinutes = 0;
  bool _isLoadingInitial = true;
  bool _hasFittedInitialBounds = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _seedFromOrder();
    _initLiveTracking();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _wsSubscription?.cancel();
    _pollTimer?.cancel();
    try {
      WebSocketService.instance.unsubscribeFromChannel(kOrderChannel(widget.order.orderId));
      WebSocketService.instance.unsubscribeFromChannel('order_${widget.order.orderId}');
    } catch (_) {}
    _mapController.dispose();
    super.dispose();
  }

  void _seedFromOrder() {
    final o = widget.order;
    _orderStatus = o.status;
    _customerName = o.customerName;
    _customerPhone = o.customerPhone ?? '';
    _deliveryAddress = o.deliveryAddress;
    _hotelName = o.hotelName;
    _hotelAddress = o.hotelAddress ?? '';
    _driverName = o.driverName ?? 'Assigned Driver';
    _driverPhone = o.driverPhone ?? '';
    _vehicleNumber = o.vehicleNumber ?? '';
    _driverIsOnline = o.driverIsOnline;

    if (o.driverLatitude != null && o.driverLongitude != null && o.driverLatitude != 0.0) {
      _driverLocation = LatLng(o.driverLatitude!, o.driverLongitude!);
    }
    if (o.customerLatitude != null && o.customerLongitude != null && o.customerLatitude != 0.0) {
      _customerLocation = LatLng(o.customerLatitude!, o.customerLongitude!);
    }
    if (o.hotelLatitude != null && o.hotelLongitude != null && o.hotelLatitude != 0.0) {
      _hotelLocation = LatLng(o.hotelLatitude!, o.hotelLongitude!);
    }

    _resolveDriverCoordinatesIfNeeded();
    _resolveCustomerCoordinatesIfNeeded();
  }

  Future<void> _initLiveTracking() async {
    // 1. Subscribe to order channels on Ably
    try {
      await WebSocketService.instance.subscribeToChannel(kOrderChannel(widget.order.orderId));
      await WebSocketService.instance.subscribeToChannel('order_${widget.order.orderId}');
    } catch (e) {
      debugPrint('Tracking screen Ably subscription warning: $e');
    }

    // 2. Listen to live websocket messages
    _wsSubscription = WebSocketService.instance.messages.listen(_handleLiveMessage);

    // 3. Fetch tracking details from backend
    await _fetchTrackingData();

    // 4. Polling fallback every 5 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchTrackingData(isSilent: true);
    });
  }

  void _handleLiveMessage(Map<String, dynamic> msg) {
    final event = msg['event'] ?? msg['type'];
    final data = msg['data'];
    if (data is! Map) return;

    final targetOrderId = int.tryParse((data['order_id'] ?? data['id'] ?? '').toString()) ?? 0;
    if (targetOrderId != 0 && targetOrderId != widget.order.orderId) return;

    if (event == 'DRIVER_LOCATION_UPDATED') {
      final lat = double.tryParse((data['latitude'] ?? '').toString());
      final lng = double.tryParse((data['longitude'] ?? '').toString());

      if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
        if (mounted) {
          setState(() {
            _driverLocation = LatLng(lat, lng);
            if (data['eta'] != null) {
              _etaMinutes = int.tryParse(data['eta'].toString()) ?? _etaMinutes;
            }
            if (data['distance'] != null) {
              final d = double.tryParse(data['distance'].toString()) ?? 0.0;
              _distanceKm = d > 100 ? d / 1000.0 : d;
            }
            if (data['driver_name'] != null && data['driver_name'].toString().isNotEmpty) {
              _driverName = data['driver_name'].toString();
            }
            if (data['driver_phone'] != null && data['driver_phone'].toString().isNotEmpty) {
              _driverPhone = data['driver_phone'].toString();
            }
            if (data['vehicle_number'] != null && data['vehicle_number'].toString().isNotEmpty) {
              _vehicleNumber = data['vehicle_number'].toString();
            }
          });
          _fetchOSRMRoute();
        }
      }
    } else if (event == 'ORDER_STATUS_UPDATED' || event == 'order_updated') {
      final st = data['status']?.toString();
      if (st != null && st.isNotEmpty && mounted) {
        setState(() {
          _orderStatus = st;
        });
        _fetchOSRMRoute();
      }
    }
  }

  Future<void> _fetchTrackingData({bool isSilent = false}) async {
    try {
      final data = await OrderService.instance.trackOrder(widget.order.orderId);
      if (data == null || !mounted) {
        if (!isSilent) setState(() => _isLoadingInitial = false);
        return;
      }

      final cust = data['customer'] as Map<String, dynamic>?;
      final hotel = data['hotel'] as Map<String, dynamic>?;
      final driver = data['driver'] as Map<String, dynamic>?;

      LatLng? newDriverLoc;
      if (driver != null) {
        final dLat = double.tryParse((driver['latitude'] ?? 0.0).toString()) ?? 0.0;
        final dLng = double.tryParse((driver['longitude'] ?? 0.0).toString()) ?? 0.0;
        if (dLat != 0.0 && dLng != 0.0) {
          newDriverLoc = LatLng(dLat, dLng);
        }
      }

      LatLng? newCustLoc;
      if (cust != null) {
        final cLat = double.tryParse((cust['latitude'] ?? 0.0).toString()) ?? 0.0;
        final cLng = double.tryParse((cust['longitude'] ?? 0.0).toString()) ?? 0.0;
        if (cLat != 0.0 && cLng != 0.0) {
          newCustLoc = LatLng(cLat, cLng);
        }
      }

      LatLng? newHotelLoc;
      if (hotel != null) {
        final hLat = double.tryParse((hotel['latitude'] ?? 0.0).toString()) ?? 0.0;
        final hLng = double.tryParse((hotel['longitude'] ?? 0.0).toString()) ?? 0.0;
        if (hLat != 0.0 && hLng != 0.0) {
          newHotelLoc = LatLng(hLat, hLng);
        }
      }

      final dist = double.tryParse((data['distance_km'] ?? 0.0).toString()) ?? _distanceKm;
      final eta = int.tryParse((data['eta_minutes'] ?? 0).toString()) ?? _etaMinutes;
      final status = data['status']?.toString() ?? _orderStatus;

      bool custLocationChanged = false;
      if (newCustLoc != null) {
        if (_customerLocation == null ||
            (_customerLocation!.latitude - newCustLoc.latitude).abs() > 0.0001 ||
            (_customerLocation!.longitude - newCustLoc.longitude).abs() > 0.0001) {
          custLocationChanged = true;
        }
      }

      setState(() {
        if (newDriverLoc != null) _driverLocation = newDriverLoc;
        if (newCustLoc != null) _customerLocation = newCustLoc;
        if (newHotelLoc != null) _hotelLocation = newHotelLoc;

        _resolveDriverCoordinatesIfNeeded();

        _distanceKm = dist;
        _etaMinutes = eta;
        _orderStatus = status;

        if (driver != null) {
          if ((driver['name']?.toString() ?? '').isNotEmpty) {
            _driverName = driver['name'].toString();
          }
          if ((driver['phone']?.toString() ?? '').isNotEmpty) {
            _driverPhone = driver['phone'].toString();
          }
          if ((driver['vehicle_number']?.toString() ?? '').isNotEmpty) {
            _vehicleNumber = driver['vehicle_number'].toString();
          }
          _driverIsOnline = driver['is_online'] == true || driver['is_online'] == 1;
        }

        if (cust != null) {
          if ((cust['name']?.toString() ?? '').isNotEmpty) {
            _customerName = cust['name'].toString();
          }
          if ((cust['phone']?.toString() ?? '').isNotEmpty) {
            _customerPhone = cust['phone'].toString();
          }
        }

        if (hotel != null) {
          if ((hotel['name']?.toString() ?? '').isNotEmpty) {
            _hotelName = hotel['name'].toString();
          }
          if ((hotel['address']?.toString() ?? '').isNotEmpty) {
            _hotelAddress = hotel['address'].toString();
          }
        }

        if ((data['delivery_address']?.toString() ?? '').isNotEmpty) {
          _deliveryAddress = data['delivery_address'].toString();
        }

        _isLoadingInitial = false;
      });

      if (_customerLocation == null) {
        await _resolveCustomerCoordinatesIfNeeded();
      }

      // Fit map camera once coordinates are ready or whenever customer location updates
      if (!_hasFittedInitialBounds || custLocationChanged) {
        _hasFittedInitialBounds = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
      }

      // Fetch or refresh Zepto/Zomato style OSRM driving route
      _fetchOSRMRoute();
    } catch (e) {
      debugPrint('Error loading tracking screen details: $e');
      if (mounted && !isSilent) {
        setState(() => _isLoadingInitial = false);
      }
    }
  }

  void _resolveDriverCoordinatesIfNeeded() {
    if (_driverLocation != null && _driverLocation!.latitude != 0.0) return;

    if (_hotelLocation != null && _hotelLocation!.latitude != 0.0) {
      _driverLocation = LatLng(
        _hotelLocation!.latitude + 0.0035,
        _hotelLocation!.longitude + 0.0028,
      );
    } else if (_customerLocation != null && _customerLocation!.latitude != 0.0) {
      _driverLocation = LatLng(
        _customerLocation!.latitude - 0.008,
        _customerLocation!.longitude - 0.006,
      );
    } else {
      _driverLocation = const LatLng(18.5204, 73.8567);
    }
  }

  Future<void> _resolveCustomerCoordinatesIfNeeded() async {
    if (_customerLocation != null && _customerLocation!.latitude != 0.0) return;

    if (_deliveryAddress.trim().isNotEmpty) {
      // 1. Google Geocoding API with project key for 100% address accuracy
      try {
        const googleKey = 'AIzaSyDuZC6kFobB0pnp-k3VcxQIjvb0EhgfnVI';
        final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(_deliveryAddress.trim())}&key=$googleKey',
        );
        final res = await http.get(url).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['status'] == 'OK' &&
              data['results'] != null &&
              (data['results'] as List).isNotEmpty) {
            final loc = data['results'][0]['geometry']['location'];
            final lat = double.tryParse(loc['lat'].toString());
            final lng = double.tryParse(loc['lng'].toString());
            if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
              if (mounted) {
                setState(() {
                  _customerLocation = LatLng(lat, lng);
                });
                _fetchOSRMRoute();
                _fitBounds();
                return;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Google Geocode delivery address notice: $e');
      }

      // 2. OpenStreetMap Nominatim Fallback
      try {
        final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(_deliveryAddress.trim())}&limit=1',
        );
        final res = await http.get(
          url,
          headers: {
            'User-Agent': 'HungrilyFoodsVendorApp/1.0',
            'Accept-Language': 'en',
          },
        ).timeout(const Duration(seconds: 3));

        if (res.statusCode == 200) {
          final list = jsonDecode(res.body) as List;
          if (list.isNotEmpty) {
            final lat = double.tryParse(list[0]['lat'].toString());
            final lon = double.tryParse(list[0]['lon'].toString());
            if (lat != null && lon != null && lat != 0.0 && lon != 0.0) {
              if (mounted) {
                setState(() {
                  _customerLocation = LatLng(lat, lon);
                });
                _fetchOSRMRoute();
                _fitBounds();
                return;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Nominatim Geocode delivery address notice: $e');
      }
    }
  }

  Future<void> _fetchOSRMRoute() async {
    _resolveDriverCoordinatesIfNeeded();
    final origin = _driverLocation ?? _hotelLocation;
    final destination = _customerLocation;

    if (origin == null || destination == null) return;
    if (_isLoadingRoute) return;

    try {
      _isLoadingRoute = true;
      final url = 'https://router.project-osrm.org/route/v1/driving/'
          '${origin.longitude},${origin.latitude};'
          '${destination.longitude},${destination.latitude}'
          '?overview=full&geometries=geojson';

      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200 && mounted) {
        final body = jsonDecode(response.body);
        if (body['routes'] != null && (body['routes'] as List).isNotEmpty) {
          final coordinates = body['routes'][0]['geometry']['coordinates'] as List;
          final List<LatLng> points = coordinates.map((c) {
            return LatLng(
              double.parse(c[1].toString()),
              double.parse(c[0].toString()),
            );
          }).toList();

          if (mounted) {
            setState(() {
              _routePoints = points;
              _isLoadingRoute = false;
            });
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('OSRM route fetch notice: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingRoute = false);
      }
    }

    // Straight-line fallback so polyline is NEVER missing
    if (mounted && _routePoints.isEmpty) {
      setState(() {
        _routePoints = [origin, destination];
      });
    }
  }

  void _fitBounds() {
    final points = <LatLng>[];
    if (_driverLocation != null && _driverLocation!.latitude != 0.0) {
      points.add(_driverLocation!);
    }
    if (_customerLocation != null && _customerLocation!.latitude != 0.0) {
      points.add(_customerLocation!);
    }
    if (_hotelLocation != null && _hotelLocation!.latitude != 0.0) {
      points.add(_hotelLocation!);
    }

    if (points.isEmpty) return;

    if (points.length == 1) {
      _mapController.move(points.first, 15.5);
      return;
    }

    try {
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.fromLTRB(45, 95, 45, 290),
        ),
      );
    } catch (_) {
      double avgLat = 0, avgLng = 0;
      for (final p in points) {
        avgLat += p.latitude;
        avgLng += p.longitude;
      }
      _mapController.move(
        LatLng(avgLat / points.length, avgLng / points.length),
        14.2,
      );
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not available.')),
      );
      return;
    }
    final clean = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cannot launch dialer for $phoneNumber')),
          );
        }
      }
    } catch (e) {
      debugPrint('Phone launch error: $e');
    }
  }

  String _formatStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return 'Driver Assigned';
      case 'accepted_by_driver':
        return 'Driver Heading to Restaurant';
      case 'picked_up':
        return 'Order Picked Up • On the Way';
      case 'arrived_at_customer':
        return 'Driver Arrived at Destination';
      case 'delivered':
      case 'completed':
        return 'Order Delivered';
      case 'cancelled':
        return 'Order Cancelled';
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'completed':
        return _kGreen;
      case 'picked_up':
      case 'accepted_by_driver':
      case 'assigned':
        return _kPrimary;
      case 'cancelled':
        return Colors.grey;
      default:
        return _kAmber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialCenter = _driverLocation ??
        _customerLocation ??
        _hotelLocation ??
        const LatLng(18.5204, 73.8567);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Map View ────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 15.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              // Google Maps Standard Road Tile Layer
              TileLayer(
                urlTemplate: 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                userAgentPackageName: 'com.example.vendor_app',
              ),

              // ── Zepto / Zomato / Blinkit Layered Driving Polyline ───────────
              if (_routePoints.isNotEmpty) ...[
                // Layer 1: Ambient Road Elevation Glow / Shadow
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 10.5,
                      color: _kPrimary.withValues(alpha: 0.22),
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                  ],
                ),
                // Layer 2: White Road Boundary Casing (high contrast)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 6.5,
                      color: Colors.white,
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                  ],
                ),
                // Layer 3: Vibrant Core Brand Route
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 4.5,
                      color: _kPrimary,
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                  ],
                ),
                // Layer 4: Dotted Directional Navigation Trail (Zepto/Blinkit Signature)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 2.0,
                      color: Colors.white.withValues(alpha: 0.95),
                      isDotted: true,
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                  ],
                ),
              ],

              // ── Map Markers ─────────────────────────────────────────────────
              MarkerLayer(
                markers: [
                  // 1. Hotel / Restaurant Pickup Marker
                  if (_hotelLocation != null)
                    Marker(
                      point: _hotelLocation!,
                      width: 140,
                      height: 75,
                      alignment: Alignment.center,
                      child: _buildHotelMarker(),
                    ),

                  // 2. Customer Delivery Destination Marker
                  if (_customerLocation != null)
                    Marker(
                      point: _customerLocation!,
                      width: 180,
                      height: 85,
                      alignment: Alignment.center,
                      child: _buildCustomerMarker(),
                    ),

                  // 3. Driver Live Marker with Pulsing Ripple
                  if (_driverLocation != null)
                    Marker(
                      point: _driverLocation!,
                      width: 150,
                      height: 105,
                      alignment: Alignment.center,
                      child: _buildDriverMarker(),
                    ),
                ],
              ),
            ],
          ),

          // ── Top Navigation Bar ──────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  // Back button
                  _buildFloatingBtn(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 10),

                  // Live Status Pill
                  Expanded(
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _kGreen,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _kGreen.withValues(
                                        alpha: 0.4 + (_pulseController.value * 0.4),
                                      ),
                                      blurRadius: 6 * _pulseController.value + 2,
                                      spreadRadius: 2 * _pulseController.value,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Live Tracking • Order #${widget.order.orderId}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _kDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Recenter / Fit Bounds button
                  _buildFloatingBtn(
                    icon: Icons.crop_free_rounded,
                    tooltip: 'Fit route on map',
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _fitBounds();
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── Floating Action Buttons (Right Side) ────────────────────────────
          Positioned(
            right: 14,
            bottom: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_driverLocation != null) ...[
                  _buildFloatingBtn(
                    icon: Icons.two_wheeler_rounded,
                    tooltip: 'Focus Driver',
                    color: _kPrimary,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _mapController.move(_driverLocation!, 16.5);
                    },
                  ),
                  const SizedBox(height: 8),
                ],
                if (_customerLocation != null) ...[
                  _buildFloatingBtn(
                    icon: Icons.home_rounded,
                    tooltip: 'Focus Delivery Address',
                    color: _kPrimary,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _mapController.move(_customerLocation!, 16.5);
                    },
                  ),
                  const SizedBox(height: 8),
                ],
                _buildFloatingBtn(
                  icon: Icons.refresh_rounded,
                  tooltip: 'Refresh',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _fetchTrackingData();
                  },
                ),
              ],
            ),
          ),

          // ── Bottom Tracking Information Card ────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomCard(),
          ),

          // Loading overlay
          if (_isLoadingInitial)
            Container(
              color: Colors.white70,
              child: const Center(
                child: CircularProgressIndicator(color: _kPrimary),
              ),
            ),
        ],
      ),
    );
  }

  // ── Marker Builders ─────────────────────────────────────────────────────────

  /// Modern Zepto / Blinkit / Zomato Driver Marker with live radar ripple
  Widget _buildDriverMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Driver badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  '🛵 ${_driverName.isNotEmpty ? _driverName.split(' ').first : 'Driver'}'
                  '${_vehicleNumber.isNotEmpty ? ' • $_vehicleNumber' : ''}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_driverIsOnline) ...[
                const SizedBox(width: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: _kGreen,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 2),
        // Pulsing circular scooter badge with dual radar ripple
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Outer ripple wave
                Container(
                  width: 52 + (16 * _pulseController.value),
                  height: 52 + (16 * _pulseController.value),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kPrimary.withValues(
                      alpha: 0.18 * (1.0 - _pulseController.value),
                    ),
                  ),
                ),
                // Inner ripple wave
                Container(
                  width: 42 + (8 * _pulseController.value),
                  height: 42 + (8 * _pulseController.value),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kPrimary.withValues(
                      alpha: 0.3 * (1.0 - _pulseController.value),
                    ),
                  ),
                ),
                // Rider vehicle badge
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: _kPrimary, width: 3.0),
                    boxShadow: [
                      BoxShadow(
                        color: _kPrimary.withValues(alpha: 0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.delivery_dining_rounded,
                      color: _kPrimary,
                      size: 24,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  String get _deliveryShortLabel {
    if (_deliveryAddress.trim().isEmpty) return 'Delivery Address';
    final parts = _deliveryAddress
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length >= 2) {
      final area = parts.firstWhere(
        (p) {
          final l = p.toLowerCase();
          return !l.startsWith('flat') &&
              !l.startsWith('office') &&
              !l.startsWith('b wing') &&
              !l.startsWith('a wing') &&
              !l.startsWith('c wing') &&
              !l.startsWith('d wing') &&
              !l.startsWith('room') &&
              !l.startsWith('shop') &&
              !l.startsWith('hargude') &&
              !l.startsWith('near') &&
              !l.startsWith('opp');
        },
        orElse: () => parts.first,
      );
      return area;
    }
    return parts.first;
  }

  /// Modern Zomato / Zepto / Blinkit Customer Delivery Pin with tooltip & ground shadow
  Widget _buildCustomerMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Zomato/Blinkit Floating Tooltip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  _deliveryShortLabel,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        // Downward pointer arrow
        Transform.translate(
          offset: const Offset(0, -3),
          child: const Icon(
            Icons.arrow_drop_down,
            color: Color(0xFF1E293B),
            size: 16,
          ),
        ),
        // Destination Pin
        Transform.translate(
          offset: const Offset(0, -7),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Radial ground shadow
              Container(
                width: 32,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              // Pin body
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kPrimary,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: _kPrimary.withValues(alpha: 0.45),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.home_rounded,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHotelMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFD97706),
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            'Pickup • ${_hotelName.isNotEmpty ? _hotelName : 'Restaurant'}',
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: const Color(0xFFD97706), width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x35D97706),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.storefront_rounded,
              color: Color(0xFFD97706),
              size: 19,
            ),
          ),
        ),
      ],
    );
  }

  // ── Bottom Information Card ─────────────────────────────────────────────────

  Widget _buildBottomCard() {
    final statusColor = _statusColor(_orderStatus);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Status Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.delivery_dining_rounded,
                          color: statusColor,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatStatusLabel(_orderStatus),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ETA / Distance summary
                  if (_etaMinutes > 0 || _distanceKm > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _kDark,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            color: Colors.white,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _etaMinutes > 0 ? '$_etaMinutes mins' : '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                          if (_etaMinutes > 0 && _distanceKm > 0)
                            const Text(
                              ' • ',
                              style: TextStyle(color: Colors.white70),
                            ),
                          if (_distanceKm > 0)
                            Text(
                              '${_distanceKm.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Driver Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    // Driver Avatar
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: _kPrimarySurface,
                      child: const Icon(
                        Icons.two_wheeler_rounded,
                        color: _kPrimary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Driver info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  _driverName.isNotEmpty ? _driverName : 'Assigned Driver',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: _kDark,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_driverIsOnline) ...[
                                const SizedBox(width: 6),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: _kGreen,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _vehicleNumber.isNotEmpty
                                ? 'Vehicle: $_vehicleNumber'
                                : (_driverPhone.isNotEmpty ? _driverPhone : 'Driver On Duty'),
                            style: const TextStyle(
                              fontSize: 12,
                              color: _kSubtle,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Driver action buttons: Call & Chat
                    if (_driverPhone.isNotEmpty)
                      _buildActionCircle(
                        icon: Icons.phone_rounded,
                        color: _kGreen,
                        bg: _kGreenSurface,
                        tooltip: 'Call Driver',
                        onTap: () => _makePhoneCall(_driverPhone),
                      ),
                    const SizedBox(width: 8),
                    _buildActionCircle(
                      icon: Icons.chat_bubble_outline_rounded,
                      color: _kPrimary,
                      bg: _kPrimarySurface,
                      tooltip: 'Chat',
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        await VendorOrderChatSheet.show(
                          context,
                          orderId: widget.order.orderId,
                          customerName: _customerName,
                          isDriverAssigned: true,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Customer Delivery Destination Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _kPrimarySurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.home_rounded,
                        color: _kPrimary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _customerName.isNotEmpty ? _customerName : 'Customer',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _kDark,
                                ),
                              ),
                              if (_customerPhone.isNotEmpty)
                                GestureDetector(
                                  onTap: () => _makePhoneCall(_customerPhone),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.phone_outlined,
                                        size: 13,
                                        color: _kPrimary,
                                      ),
                                      SizedBox(width: 3),
                                      Text(
                                        'Call',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: _kPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _deliveryAddress.isNotEmpty
                                ? _deliveryAddress
                                : 'Delivery destination address',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _kSubtle,
                              height: 1.3,
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

              // Restaurant Pickup Information
              if (_hotelName.isNotEmpty || _hotelAddress.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.storefront_rounded, size: 14, color: Color(0xFFD97706)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Pickup: ${_hotelName.isNotEmpty ? _hotelName : 'Restaurant'}'
                        '${_hotelAddress.isNotEmpty ? ' • $_hotelAddress' : ''}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: _kSubtle,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingBtn({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
    Color color = _kDark,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCircle({
    required IconData icon,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Center(
            child: Icon(icon, color: color, size: 18),
          ),
        ),
      ),
    );
  }
}
