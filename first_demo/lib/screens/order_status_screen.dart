// lib/screens/order_status_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/order.dart';
import '../services/ably_service.dart';
import '../services/order_service.dart';
import '../utils/app_config.dart';
import '../services/order_notification_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'order_delivered_screen.dart';
import '../services/chat_service.dart';
import '../widgets/order_chat_sheet.dart';

class OrderStatusScreen extends StatefulWidget {
  final OrderHistoryItem initialOrder;
  
  // Track which order is currently actively viewed on the screen
  static int? activeTrackingOrderId;

  const OrderStatusScreen({super.key, required this.initialOrder});

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  late OrderHistoryItem _order;
  StreamSubscription? _wsSubscription;
  StreamSubscription? _chatSubscription;
  Timer? _pollTimer;
  double? _liveDistance;
  int? _liveEta;
  LatLng? _lastDriverPosition;
  double _driverBearing = 0.0;

  double _calculateBearing(LatLng start, LatLng end) {
    final lat1 = start.latitude * (math.pi / 180.0);
    final lon1 = start.longitude * (math.pi / 180.0);
    final lat2 = end.latitude * (math.pi / 180.0);
    final lon2 = end.longitude * (math.pi / 180.0);

    final dLon = lon2 - lon1;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return math.atan2(y, x);
  }

  OrderDetails? _orderDetails;
  bool _isLoadingDetails = true;

  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = true;

  double _scrollOpacity = 0.0;
  final MapController _mapController = MapController();
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  double _currentSheetExtent = 0.62;
  int _unreadChatCount = 0;

  @override
  void initState() {
    super.initState();
    OrderStatusScreen.activeTrackingOrderId = widget.initialOrder.orderId;
    _order = widget.initialOrder;
    _sheetController.addListener(_onSheetExtentChanged);
    _fetchOrderDetails();
    _startWebSocketListener();
    _initChatListener();
  }

  void _onSheetExtentChanged() {
    if (mounted && _sheetController.isAttached) {
      final newExtent = _sheetController.size;
      if ((newExtent - _currentSheetExtent).abs() > 0.005) {
        setState(() {
          _currentSheetExtent = newExtent;
        });
      }
    }
  }

  @override
  void dispose() {
    _sheetController.removeListener(_onSheetExtentChanged);
    _sheetController.dispose();
    _wsSubscription?.cancel();
    _chatSubscription?.cancel();
    AblyService.instance.unsubscribeFromChannel(kOrderChatChannel(widget.initialOrder.orderId));
    AblyService.instance.unsubscribeFromChannel(kOrderChannel(widget.initialOrder.orderId));
    _pollTimer?.cancel();
    if (OrderStatusScreen.activeTrackingOrderId == widget.initialOrder.orderId) {
      OrderStatusScreen.activeTrackingOrderId = null;
    }
    super.dispose();
  }

  void _initChatListener() {
    _fetchUnreadChatCount();
    final chatChannel = kOrderChatChannel(widget.initialOrder.orderId);
    _chatSubscription = AblyService.instance.subscribe(chatChannel).listen((msg) {
      final event = msg['event'] as String?;
      final data = msg['data'];
      if (event == 'CHAT_MESSAGE' && data != null) {
        if (data['sender_type'] == 'vendor' && mounted) {
          setState(() {
            _unreadChatCount++;
          });
        }
      } else if (event == 'CHAT_READ_RECEIPT' && mounted) {
        setState(() {
          _unreadChatCount = 0;
        });
      }
    });
  }

  Future<void> _fetchUnreadChatCount() async {
    final res = await ChatService.instance.getMessages(widget.initialOrder.orderId);
    if (mounted && res.success) {
      setState(() {
        _unreadChatCount = res.unreadCount;
      });
    }
  }

  Future<void> _fetchOrderDetails() async {
    try {
      final details = await OrderService.instance.getDetails(orderId: _order.orderId);
      if (mounted) {
        // If the API reports a newer status, sync it to the UI immediately
        final freshStatus = details.status;
        if (freshStatus != _order.status) {
          debugPrint(
              'OrderStatus: Poll detected status change '
              '${_order.status} → $freshStatus');

          // If delivered, go to celebration screen
          if (freshStatus == 'completed') {
            _wsSubscription?.cancel();
            _pollTimer?.cancel();
            OrderStatusScreen.activeTrackingOrderId = null;
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => OrderDeliveredScreen(
                    hotelName: _order.hotelName,
                    grandTotal: _order.grandTotal,
                  ),
                ),
              );
            }
            return;
          }

          setState(() {
            _order = OrderHistoryItem(
              orderId: _order.orderId,
              hotelName: _order.hotelName,
              status: freshStatus,
              grandTotal: _order.grandTotal,
              walletDeducted: _order.walletDeducted,
              itemCount: _order.itemCount,
              createdAt: _order.createdAt,
            );
          });
        }

        setState(() {
          _orderDetails = details;
          _isLoadingDetails = false;
        });

        if (_routePoints.isEmpty) {
          _fetchRoute(
            details.hotel.latitude,
            details.hotel.longitude,
            details.customerLatitude,
            details.customerLongitude,
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to load order details: $e');
      if (mounted) {
        setState(() {
          _isLoadingDetails = false;
        });
      }
    }
  }

  Future<void> _fetchRoute(double hotelLat, double hotelLng, double customerLat, double customerLng) async {
    try {
      final url = 'https://router.project-osrm.org/route/v1/driving/$hotelLng,$hotelLat;$customerLng,$customerLat?overview=full&geometries=geojson';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final geometry = data['routes'][0]['geometry'];
          final List coords = geometry['coordinates'] as List;
          final List<LatLng> points = coords.map((c) {
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
      debugPrint('Failed to fetch OSRM driving route: $e');
    }
    // Fallback to straight line
    if (mounted) {
      setState(() {
        _routePoints = [LatLng(hotelLat, hotelLng), LatLng(customerLat, customerLng)];
        _isLoadingRoute = false;
      });
    }
  }

  LatLng _safeLatLng(double lat, double lng, {double fallbackLat = 18.5204, double fallbackLng = 73.8567}) {
    if (lat.isNaN || lat.isInfinite || lat == 0.0) lat = fallbackLat;
    if (lng.isNaN || lng.isInfinite || lng == 0.0) lng = fallbackLng;
    return LatLng(lat, lng);
  }

  int _scooterSegmentIndex = 0;

  LatLng _getScooterPosition(double progress) {
    if (_routePoints.isEmpty) {
      final hotelLat = _orderDetails?.hotel.latitude ?? 18.5284;
      final hotelLng = _orderDetails?.hotel.longitude ?? 73.8739;
      final customerLat = _orderDetails?.customerLatitude ?? 18.5204;
      final customerLng = _orderDetails?.customerLongitude ?? 73.8567;
      return _safeLatLng(
        hotelLat + (customerLat - hotelLat) * progress,
        hotelLng + (customerLng - hotelLng) * progress,
        fallbackLat: hotelLat,
        fallbackLng: hotelLng,
      );
    }
    if (progress <= 0) {
      _scooterSegmentIndex = 0;
      return _routePoints.first;
    }
    if (progress >= 1) {
      _scooterSegmentIndex = _routePoints.length - 1;
      return _routePoints.last;
    }

    double totalLength = 0;
    final List<double> segmentLengths = [];
    for (int i = 0; i < _routePoints.length - 1; i++) {
      double dist = _getLatLngDistance(_routePoints[i], _routePoints[i + 1]);
      segmentLengths.add(dist);
      totalLength += dist;
    }

    if (totalLength <= 0 || totalLength.isNaN) {
      _scooterSegmentIndex = 0;
      return _routePoints.first;
    }

    double targetLength = totalLength * progress;
    double currentLength = 0;

    for (int i = 0; i < _routePoints.length - 1; i++) {
      double len = segmentLengths[i];
      if (len <= 0) continue;
      if (currentLength + len >= targetLength) {
        double ratio = (targetLength - currentLength) / len;
        _scooterSegmentIndex = i;
        final p1 = _routePoints[i];
        final p2 = _routePoints[i + 1];
        return _safeLatLng(
          p1.latitude + (p2.latitude - p1.latitude) * ratio,
          p1.longitude + (p2.longitude - p1.longitude) * ratio,
          fallbackLat: p1.latitude,
          fallbackLng: p1.longitude,
        );
      }
      currentLength += len;
    }
    _scooterSegmentIndex = _routePoints.length - 1;
    return _routePoints.last;
  }

  double _getLatLngDistance(LatLng p1, LatLng p2) {
    final dx = p1.latitude - p2.latitude;
    final dy = p1.longitude - p2.longitude;
    return dx * dx + dy * dy;
  }

  int _getClosestRoutePointIndex(LatLng driverPoint) {
    if (_routePoints.isEmpty) return 0;
    int closestIndex = 0;
    double minDistance = double.infinity;
    for (int i = 0; i < _routePoints.length; i++) {
      double dist = _getLatLngDistance(_routePoints[i], driverPoint);
      if (dist < minDistance) {
        minDistance = dist;
        closestIndex = i;
      }
    }
    return closestIndex;
  }

  void _startWebSocketListener() {
    AblyService.instance.connect();
    AblyService.instance.subscribeToOrder(_order.orderId);

    // ── Periodic polling fallback (every 1 s) ─────────────────────────────
    // Ensures status stays up-to-date even if an Ably event is dropped.
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _fetchOrderDetails();
    });

    _wsSubscription = AblyService.instance.messages.listen((msg) {
      final event = msg['event'] as String?;
      final eventData = msg['data'];
      if (eventData == null) return;

      debugPrint('OrderStatus: Ably event [$event] → $eventData');

      if (event == 'order_updated' || event == 'ORDER_STATUS_UPDATED') {
        try {
          // Safe parse — backend sends int, toString() handles both int & String
          final orderId = int.tryParse(eventData['order_id']?.toString() ?? '');
          final status = eventData['status']?.toString();

          debugPrint(
              'OrderStatus: ORDER_STATUS_UPDATED orderId=$orderId '
              'expected=${_order.orderId} status=$status');

          if (orderId != null && orderId == _order.orderId && status != null) {
            if (status != _order.status) {
              OrderNotificationManager.instance.playStatusSound();
            }

            // ── DELIVERED: immediately show celebration screen ───────────
            if (status == 'completed' && mounted) {
              _wsSubscription?.cancel();
              _pollTimer?.cancel();
              OrderStatusScreen.activeTrackingOrderId = null;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => OrderDeliveredScreen(
                    hotelName: _order.hotelName,
                    grandTotal: _order.grandTotal,
                  ),
                ),
              );
              return;
            }

            if (mounted) {
              setState(() {
                _order = OrderHistoryItem(
                  orderId: _order.orderId,
                  hotelName: _order.hotelName,
                  status: status,
                  grandTotal: _order.grandTotal,
                  walletDeducted: _order.walletDeducted,
                  itemCount: _order.itemCount,
                  createdAt: _order.createdAt,
                );
                if (_orderDetails != null) {
                  _orderDetails = OrderDetails(
                    orderId: _orderDetails!.orderId,
                    status: status,
                    subtotal: _orderDetails!.subtotal,
                    deliveryFee: _orderDetails!.deliveryFee,
                    taxAmount: _orderDetails!.taxAmount,
                    grandTotal: _orderDetails!.grandTotal,
                    walletDeducted: _orderDetails!.walletDeducted,
                    paymentMethod: _orderDetails!.paymentMethod,
                    deliveryAddress: _orderDetails!.deliveryAddress,
                    createdAt: _orderDetails!.createdAt,
                    hotel: _orderDetails!.hotel,
                    items: _orderDetails!.items,
                    deliveryPartner: _orderDetails!.deliveryPartner,
                    customerLatitude: _orderDetails!.customerLatitude,
                    customerLongitude: _orderDetails!.customerLongitude,
                    deliveryOtp: _orderDetails!.deliveryOtp,
                  );
                }
              });
              // Also refresh full details from server
              _fetchOrderDetails();
            }
          }
        } catch (e) {
          debugPrint('OrderStatus: Error parsing status update: $e');
        }
      } else if (event == 'DRIVER_LOCATION_UPDATED') {
        try {
          // Safe parse for orderId (JSON int or String)
          final orderId = int.tryParse(eventData['order_id']?.toString() ?? '');
          if (orderId == null || orderId != _order.orderId) return;

          final driverId = int.tryParse(eventData['driver_id']?.toString() ?? '');
          final lat = double.tryParse(eventData['latitude']?.toString() ?? '');
          final lng = double.tryParse(eventData['longitude']?.toString() ?? '');
          final distance = double.tryParse(eventData['distance']?.toString() ?? '');
          final eta = int.tryParse(eventData['eta']?.toString() ?? '');

          if (mounted && lat != null && lng != null && lat != 0.0 && lng != 0.0) {
            final newPos = LatLng(lat, lng);
            if (_lastDriverPosition != null) {
              final distSq = _getLatLngDistance(_lastDriverPosition!, newPos);
              if (distSq > 0.0000001) {
                _driverBearing = _calculateBearing(_lastDriverPosition!, newPos);
              }
            }
            _lastDriverPosition = newPos;

            setState(() {
              _liveDistance = distance;
              _liveEta = eta;

              if (_orderDetails != null) {
                if (_orderDetails!.deliveryPartner == null && eventData['driver_name'] != null) {
                  _orderDetails = OrderDetails(
                    orderId: _orderDetails!.orderId,
                    status: _orderDetails!.status,
                    subtotal: _orderDetails!.subtotal,
                    deliveryFee: _orderDetails!.deliveryFee,
                    taxAmount: _orderDetails!.taxAmount,
                    grandTotal: _orderDetails!.grandTotal,
                    walletDeducted: _orderDetails!.walletDeducted,
                    paymentMethod: _orderDetails!.paymentMethod,
                    deliveryAddress: _orderDetails!.deliveryAddress,
                    createdAt: _orderDetails!.createdAt,
                    hotel: _orderDetails!.hotel,
                    items: _orderDetails!.items,
                    customerLatitude: _orderDetails!.customerLatitude,
                    customerLongitude: _orderDetails!.customerLongitude,
                    deliveryOtp: _orderDetails!.deliveryOtp,
                    deliveredAt: _orderDetails!.deliveredAt,
                    deliveryPartner: OrderDetailsDeliveryPartner(
                      id: driverId ?? 0,
                      name: eventData['driver_name'].toString(),
                      rating: '4.8',
                      avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=200',
                      phoneNumber: eventData['driver_phone']?.toString() ?? '',
                      vehicleNumber: eventData['vehicle_number']?.toString() ?? '',
                      latitude: lat,
                      longitude: lng,
                    ),
                  );
                } else if (_orderDetails!.deliveryPartner != null) {
                  _orderDetails!.deliveryPartner!.latitude = lat;
                  _orderDetails!.deliveryPartner!.longitude = lng;
                  if (eventData['driver_phone'] != null && eventData['driver_phone'].toString().isNotEmpty) {
                    _orderDetails!.deliveryPartner!.phoneNumber = eventData['driver_phone'].toString();
                  }
                }
              }
            });
          }
        } catch (e) {
          debugPrint('OrderStatus: Error parsing driver location: $e');
        }
      }
    });
  }

  double _getRouteProgress(String status) {
    switch (status) {
      case 'created_order':
        return 0.08;
      case 'accepted':
        return 0.25;
      case 'preparing':
        return 0.40;
      case 'ready':
        return 0.60;
      case 'accepted_by_driver':
        return 0.70;
      case 'picked_up':
        return 0.85;
      case 'arrived_at_customer':
        return 0.95;
      case 'completed':
        return 1.0;
      default:
        return 0.08;
    }
  }

  String _getStatusHeader(String status) {
    switch (status) {
      case 'created_order':
        return 'Order Placed';
      case 'accepted':
        return 'Order Accepted';
      case 'preparing':
        return 'Preparing Food';
      case 'ready':
        return 'Food Ready';
      case 'accepted_by_driver':
        return 'Driver Assigned';
      case 'picked_up':
        return 'Pickup Soon';
      case 'arrived_at_customer':
        return 'Rider Arrived';
      case 'completed':
        return 'Order Delivered';
      default:
        return 'Pickup Soon';
    }
  }

  String _getStatusSubtitle(String status) {
    switch (status) {
      case 'created_order':
        return 'Waiting for restaurant acceptance';
      case 'accepted':
        return 'Restaurant has accepted your order';
      case 'preparing':
        return 'Fresh ingredients cooking in the kitchen!';
      case 'ready':
        return 'Waiting for driver pickup';
      case 'accepted_by_driver':
        return 'Rider is heading to the restaurant';
      case 'picked_up':
        return "Food's in sight, ride's in flight!";
      case 'arrived_at_customer':
        return 'Please collect your order at the door!';
      case 'completed':
        return 'Hope you enjoyed your meal!';
      default:
        return "Food's in sight, ride's in flight!";
    }
  }

  int _getDefaultEta(String status) {
    switch (status) {
      case 'created_order':
        return 35;
      case 'accepted':
        return 30;
      case 'preparing':
        return 25;
      case 'ready':
        return 15;
      case 'accepted_by_driver':
        return 15;
      case 'picked_up':
        return 12;
      case 'arrived_at_customer':
        return 2;
      case 'completed':
        return 0;
      default:
        return 12;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _order.status;
    final progress = _getRouteProgress(status);
    final etaMins = _liveEta ?? _getDefaultEta(status);

    final rawHotelLat = _orderDetails?.hotel.latitude ?? 18.5284;
    final rawHotelLng = _orderDetails?.hotel.longitude ?? 73.8739;
    final rawCustomerLat = _orderDetails?.customerLatitude ?? 18.5204;
    final rawCustomerLng = _orderDetails?.customerLongitude ?? 73.8567;

    final hotelPoint = _safeLatLng(rawHotelLat, rawHotelLng, fallbackLat: 18.5284, fallbackLng: 73.8739);
    final customerPoint = _safeLatLng(rawCustomerLat, rawCustomerLng, fallbackLat: 18.5204, fallbackLng: 73.8567);

    // Calculate driver/scooter position
    final LatLng rawScooterPoint;
    final List<LatLng> coveredPath;
    final List<LatLng> remainingPath;

    if (_orderDetails?.deliveryPartner != null && 
        _orderDetails!.deliveryPartner!.latitude != 0.0 &&
        !_orderDetails!.deliveryPartner!.latitude.isNaN &&
        !_orderDetails!.deliveryPartner!.longitude.isNaN) {
      rawScooterPoint = _safeLatLng(
        _orderDetails!.deliveryPartner!.latitude,
        _orderDetails!.deliveryPartner!.longitude,
        fallbackLat: hotelPoint.latitude,
        fallbackLng: hotelPoint.longitude,
      );
      
      final int rawIdx = _getClosestRoutePointIndex(rawScooterPoint);
      final int safeIdx = _routePoints.isEmpty ? 0 : rawIdx.clamp(0, _routePoints.length - 1);
      
      coveredPath = _routePoints.isEmpty
          ? [hotelPoint, rawScooterPoint]
          : [..._routePoints.sublist(0, safeIdx + 1), rawScooterPoint];
      remainingPath = _routePoints.isEmpty
          ? [rawScooterPoint, customerPoint]
          : [rawScooterPoint, ..._routePoints.sublist(math.min(safeIdx + 1, _routePoints.length))];
    } else {
      rawScooterPoint = _getScooterPosition(progress);
      final int safeIdx = _routePoints.isEmpty ? 0 : _scooterSegmentIndex.clamp(0, _routePoints.length - 1);
      coveredPath = _routePoints.isEmpty
          ? [hotelPoint, rawScooterPoint]
          : [..._routePoints.sublist(0, safeIdx + 1), rawScooterPoint];
      remainingPath = _routePoints.isEmpty
          ? [rawScooterPoint, customerPoint]
          : [rawScooterPoint, ..._routePoints.sublist(math.min(safeIdx + 1, _routePoints.length))];
    }

    final scooterPoint = _safeLatLng(
      rawScooterPoint.latitude,
      rawScooterPoint.longitude,
      fallbackLat: hotelPoint.latitude,
      fallbackLng: hotelPoint.longitude,
    );

    // Determine driver heading phase
    final isPickedUp = ['picked_up', 'arrived_at_customer', 'completed'].contains(status);

    // Focus camera dynamically:
    // Before pickup -> Driver heading to Hotel (Focus between Driver & Hotel)
    // After pickup  -> Driver heading to Customer (Focus between Driver & Customer)
    final LatLng activeTargetPoint = isPickedUp ? customerPoint : hotelPoint;
    final centerLat = (scooterPoint.latitude + activeTargetPoint.latitude) / 2;
    final centerLng = (scooterPoint.longitude + activeTargetPoint.longitude) / 2;
    // Offset center latitude south so that active markers stay visible above the sheet
    final mapCenter = _safeLatLng(
      centerLat - 0.0075,
      centerLng,
      fallbackLat: hotelPoint.latitude - 0.0075,
      fallbackLng: hotelPoint.longitude,
    );

    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final bottomPadding = mediaQuery.padding.bottom;

    // Exact height of the collapsed card + handle + bottom spacing
    final double collapsedHeight = 22.5 + 150.0 + math.max(bottomPadding, 12.0);
    final double minSheetSize = (collapsedHeight / screenHeight).clamp(0.18, 0.30);
    const double snapMiddle = 0.62;
    const double snapTop = 0.88;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Map Background (Full Screen & Touchable with Zoom controls)
          Positioned.fill(
            child: (_isLoadingDetails || _isLoadingRoute)
                ? Container(
                    color: const Color(0xFFF3F7F5),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFEC4899),
                      ),
                    ),
                  )
                : FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: mapCenter,
                      initialZoom: 14.5,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                        userAgentPackageName: 'com.example.first_demo',
                      ),
                      PolylineLayer(
                        polylines: [
                          // Path from Hotel to Scooter
                          if (coveredPath.length >= 2)
                            Polyline(
                              points: coveredPath,
                              color: isPickedUp ? const Color(0xFF2563EB) : const Color(0xFFF59E0B),
                              strokeWidth: 5.5,
                            ),
                          // Path from Scooter to Customer
                          if (remainingPath.length >= 2)
                            Polyline(
                              points: remainingPath,
                              color: isPickedUp ? const Color(0xFF0EA5E9) : const Color(0xFF94A3B8),
                              strokeWidth: isPickedUp ? 5.5 : 4.0,
                            ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          // 1. Hotel Location Marker (User's First Image)
                          Marker(
                            point: hotelPoint,
                            width: 42,
                            height: 42,
                            alignment: Alignment.center,
                            child: _buildHotelMarker(),
                          ),
                          // 2. Customer Location Marker (User's Second Image)
                          Marker(
                            point: customerPoint,
                            width: 36,
                            height: 45,
                            alignment: Alignment.topCenter,
                            child: _buildCustomerMarker(),
                          ),
                          // 3. Driver / Scooter Marker
                          Marker(
                            point: scooterPoint,
                            width: 46,
                            height: 46,
                            alignment: Alignment.center,
                            child: _buildScooterMarker(),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),

          // Google Logo watermark on map (Dynamically sits right above bottom sheet)
          Positioned(
            bottom: math.max(12.0, (_currentSheetExtent * screenHeight) + 8.0),
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Google',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),

          // Driver Direction Banner Indicator on Map
          Positioned(
            top: 75,
            left: 16,
            right: 70,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isPickedUp ? const Color(0xFF0284C7) : const Color(0xFFD97706),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    isPickedUp ? Icons.directions_bike_rounded : Icons.storefront_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isPickedUp
                          ? 'Driver is delivering order to your location!'
                          : 'Driver is heading to mess for order pickup',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Touchable Floating Action Buttons on Map (Zoom In, Zoom Out, Recenter Focus)
          Positioned(
            top: 130,
            right: 12,
            child: Column(
              children: [
                // Zoom In Button
                GestureDetector(
                  onTap: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, currentZoom + 0.8);
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.black87,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Zoom Out Button
                GestureDetector(
                  onTap: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, currentZoom - 0.8);
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                    ),
                    child: const Icon(
                      Icons.remove_rounded,
                      color: Colors.black87,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Recenter / Target Focus Button
                GestureDetector(
                  onTap: () {
                    _mapController.move(mapCenter, 14.5);
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF1E293B),
                      boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 5, offset: Offset(0, 2))],
                    ),
                    child: const Icon(
                      Icons.gps_fixed_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable area inside a Draggable Scrollable Sheet
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: snapMiddle,
            minChildSize: minSheetSize,
            maxChildSize: snapTop,
            snap: true,
            snapSizes: [minSheetSize, snapMiddle, snapTop],
            builder: (context, scrollController) {
              return Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification notification) {
                    if (notification is ScrollUpdateNotification) {
                      double offset = notification.metrics.pixels;
                      double opacity = (offset / 80).clamp(0.0, 1.0);
                      if (opacity != _scrollOpacity) {
                        setState(() {
                          _scrollOpacity = opacity;
                        });
                      }
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    controller: scrollController,
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      children: [
                        // Grab Handle / Drag Indicator (Tap to toggle collapse/expand)
                        GestureDetector(
                          onTap: () {
                            if (_sheetController.isAttached) {
                              if (_sheetController.size > minSheetSize + 0.05) {
                                _sheetController.animateTo(
                                  minSheetSize,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutCubic,
                                );
                              } else {
                                _sheetController.animateTo(
                                  snapMiddle,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutCubic,
                                );
                              }
                            }
                          },
                          behavior: HitTestBehavior.opaque,
                          child: SizedBox(
                            width: double.infinity,
                            child: Column(
                              children: [
                                const SizedBox(height: 8),
                                Container(
                                  width: 40,
                                  height: 4.5,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade400.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(2.5),
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                        ),

                        // Main Order Status Card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: _buildStatusCard(etaMins),
                        ),
                        const SizedBox(height: 16),
                        _buildToothsiBanner(),
                        const SizedBox(height: 16),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'ORDER SUMMARY',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: _buildOrderSummaryCard(),
                        ),
                        const SizedBox(height: 16),
                        _buildBurgerBanner(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Fixed Top Header (Transitions to white background on scroll)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(_scrollOpacity),
                boxShadow: _scrollOpacity > 0.1
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04 * _scrollOpacity),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            _orderDetails?.hotel.hotelName ?? _order.hotelName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '10:02 PM • ${_order.itemCount} items',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Menu actions...')),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.more_horiz_rounded,
                            size: 18,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScooterMarker() {
    return Transform.rotate(
      angle: _driverBearing,
      child: Image.asset(
        'assets/images/scooter_driver.png',
        fit: BoxFit.contain,
        errorBuilder: (ctx, err, stack) => Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: Color(0xFFF58220),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.two_wheeler_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildHotelMarker() {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
            border: Border.all(color: const Color(0xFFF59E0B), width: 2.0),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'assets/images/hotel_marker.png',
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, stack) => const Icon(
              Icons.storefront_rounded,
              color: Color(0xFFF59E0B),
              size: 20,
            ),
          ),
        ),
        Positioned(
          bottom: -2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded, size: 7, color: Color(0xFFF59E0B)),
                SizedBox(width: 2),
                Text(
                  'MESS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 6.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerMarker() {
    return Image.asset(
      'assets/images/customer_marker.png',
      fit: BoxFit.contain,
      errorBuilder: (ctx, err, stack) => Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: Color(0xFFEF4444),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
        ),
        child: const Icon(
          Icons.location_on_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildDriverHelmetAvatar() {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF10B981),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 2,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFC0A0),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 5,
                    left: 4,
                    child: Container(width: 2, height: 2, color: Colors.black87),
                  ),
                  Positioned(
                    top: 5,
                    right: 4,
                    child: Container(width: 2, height: 2, color: Colors.black87),
                  ),
                  Positioned(
                    bottom: 3,
                    child: Container(
                      width: 6,
                      height: 3,
                      decoration: const BoxDecoration(
                        color: Color(0xFFB91C1C),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(3),
                          bottomRight: Radius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: Container(
              width: 28,
              height: 10,
              color: const Color(0xFF047857),
            ),
          ),
          Positioned(
            top: 8,
            child: Container(
              width: 22,
              height: 2,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeliveryInstructionsSheet() {
    final rawOtp = _orderDetails?.deliveryOtp;
    final String otp = (rawOtp != null && rawOtp.isNotEmpty)
        ? rawOtp
        : '${1000 + (_order.orderId * 37) % 9000}';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Delivery Instructions & OTP',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: Color(0xFF16A34A), size: 28),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Delivery OTP',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF166534),
                          ),
                        ),
                        Text(
                          otp,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF15803D),
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _buildInstructionRow(Icons.phone_disabled_rounded, 'Avoid calling unless necessary'),
              const SizedBox(height: 10),
              _buildInstructionRow(Icons.doorbell_outlined, 'Leave at the door / reception'),
              const SizedBox(height: 10),
              _buildInstructionRow(Icons.shield_outlined, 'Contactless delivery preferred'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF334155),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(int etaMins) {
    final status = _order.status;
    final rawOtp = _orderDetails?.deliveryOtp;
    final String otp = (rawOtp != null && rawOtp.isNotEmpty)
        ? rawOtp
        : '${1000 + (_order.orderId * 37) % 9000}';
    final String otpText = status != 'completed'
        ? 'OTP: $otp  Avoid calling...'
        : 'Avoid calling, Leave at the door...';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.bolt_rounded,
                          color: Color(0xFFE91E63),
                          size: 16,
                        ),
                        SizedBox(width: 2),
                        Text(
                          '15MIN FASTER WITH QUICK',
                          style: TextStyle(
                            color: Color(0xFFE91E63),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _getStatusHeader(status),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      (() {
                        String subtitle = _getStatusSubtitle(status);
                        if (_liveDistance != null && status != 'completed') {
                          final distanceKm = (_liveDistance! / 1000).toStringAsFixed(1);
                          subtitle = '$subtitle ($distanceKm km away)';
                        }
                        return subtitle;
                      })(),
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    width: 68,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD0006F),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          color: const Color(0xFF4C0519),
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: const Text(
                            'QUICK',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$etaMins',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    height: 1.0,
                                  ),
                                ),
                                const Text(
                                  'mins',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
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
            ],
          ),
          const SizedBox(height: 11),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _showDeliveryInstructionsSheet,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Text(
                            'Delivery Instructions',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          SizedBox(width: 3),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 15,
                            color: Color(0xFF64748B),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        otpText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final partner = _orderDetails?.deliveryPartner;
                        final phone = (partner?.phoneNumber.isNotEmpty ?? false)
                            ? partner!.phoneNumber
                            : (_orderDetails?.hotel.phoneNumber ?? '');
                        final name = partner?.name ?? _orderDetails?.hotel.hotelName ?? 'Delivery Partner';
                        if (phone.isNotEmpty) {
                          final uri = Uri.parse('tel:$phone');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Could not launch call to $name ($phone)')),
                              );
                            }
                          }
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Phone number not available')),
                            );
                          }
                        }
                      },
                      child: const Icon(
                        Icons.phone_rounded,
                        size: 16,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 14,
                      color: const Color(0xFFCBD5E1),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    GestureDetector(
                      onTap: () async {
                        await OrderChatSheet.show(
                          context,
                          orderId: _order.orderId,
                          hotelName: _orderDetails?.hotel.hotelName ?? _order.hotelName,
                          isDriverAssigned: (_orderDetails?.deliveryPartner != null || ['assigned', 'accepted_by_driver', 'picked_up', 'arrived_at_customer', 'completed'].contains(_order.status)),
                        );
                        _fetchUnreadChatCount();
                      },
                      child: const Icon(
                        Icons.chat_bubble_rounded,
                        size: 15,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildDriverHelmetAvatar(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToothsiBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2FE),
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 110, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Text(
                      'toothsi',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE11D48),
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(width: 3),
                    Text(
                      'by MakeO',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Alert: Half the year is over.\nYour smile goals still have time.',
                  style: TextStyle(
                    color: Color(0xFFB91C1C),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Flat ₹18k off on invisible aligners',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Valid till 31st July, 2026',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Book a free scan today',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: -10,
            bottom: 0,
            top: 10,
            child: Image.asset(
              'assets/images/toothsi_banner_woman.png',
              width: 130,
              height: 130,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.restaurant_menu_rounded,
                      color: Colors.black87,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _orderDetails?.hotel.hotelName ?? _order.hotelName,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _orderDetails?.hotel.hotelAddress ?? 'Shop No : S.No. 40/1B/2, , Floor : , ...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // ── Chat with Restaurant Button (Pre-pickup) ─────────────────
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await OrderChatSheet.show(
                          context,
                          orderId: _order.orderId,
                          hotelName: _orderDetails?.hotel.hotelName ?? _order.hotelName,
                          isDriverAssigned: (_orderDetails?.deliveryPartner != null || ['assigned', 'accepted_by_driver', 'picked_up', 'arrived_at_customer', 'completed'].contains(_order.status)),
                        );
                        _fetchUnreadChatCount();
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFF7ED),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chat_bubble_rounded,
                          color: Color(0xFFF58220),
                          size: 16,
                        ),
                      ),
                    ),
                    if (_unreadChatCount > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981), // Green unread notification dot
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    final phone = _orderDetails?.hotel.phoneNumber ?? '';
                    final name = _orderDetails?.hotel.hotelName ?? _order.hotelName;
                    if (phone.isNotEmpty) {
                      final uri = Uri.parse('tel:$phone');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Could not launch call to $name ($phone)')),
                          );
                        }
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Mess phone number not available for $name')),
                        );
                      }
                    }
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFDF2F8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.phone_rounded,
                      color: Color(0xFFDB2777),
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: _DottedDivider(color: Color(0xFFD1D5DB)),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.home_rounded,
                      color: Colors.black87,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Delivering to Others',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _orderDetails?.deliveryAddress ?? 'Infront of Little scholars school gan...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Edit delivery address/instructions...'),
                        backgroundColor: Color(0xFFDB2777),
                      ),
                    );
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFDF2F8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Color(0xFFDB2777),
                      size: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Order items breakdown
          if (_orderDetails != null && _orderDetails!.items.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: _DottedDivider(color: Color(0xFFD1D5DB)),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ITEMS ORDERED',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.black54,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._orderDetails!.items.map((item) {
                    final List<String> cleanOptionals = item.selectedOptionalItems
                        .map((s) => s.replaceAll(RegExp(r'^(Sukhi Bhaji|Dry Sabji|Patal Bhaji|Gravy Sabji):\s*', caseSensitive: false), '').trim())
                        .where((s) => s.isNotEmpty)
                        .toList();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.quantity}x  ${item.foodName}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              Text(
                                '₹${(item.price * item.quantity).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          if (item.mandatoryItems.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              item.mandatoryItems.join(' + '),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ],
                          if (cleanOptionals.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              '(${cleanOptionals.join(' + ')})',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBurgerBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF022C22),
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 110, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Stack(
                      children: [
                        Text(
                          'WTF',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 2.5
                              ..color = const Color(0xFF22C55E),
                          ),
                        ),
                        const Text(
                          'WTF',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFACC15),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'scenes',
                      style: TextStyle(
                        color: Color(0xFFF472B6),
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Craziest deals on your\nfavourite Burger brands',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text(
                    'KNOW MORE',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            top: 10,
            bottom: 10,
            child: Image.asset(
              'assets/images/wtf_burger.png',
              width: 110,
              height: 110,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            right: 12,
            bottom: 4,
            child: Transform.rotate(
              angle: -0.05,
              child: Opacity(
                opacity: 0.15,
                child: Text(
                  'STAY TUNED!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 1.2
                      ..color = Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DottedDivider extends StatelessWidget {
  final Color color;

  const _DottedDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.constrainWidth();
        const double dashWidth = 5.0;
        const double dashHeight = 1.0;
        final int dashCount = (width / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color),
              ),
            );
          }),
        );
      },
    );
  }
}
