// lib/screens/order_status_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/order.dart';
import '../services/websocket_service.dart';
import '../services/order_service.dart';

class OrderStatusScreen extends StatefulWidget {
  final OrderHistoryItem initialOrder;

  const OrderStatusScreen({super.key, required this.initialOrder});

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  late OrderHistoryItem _order;
  StreamSubscription? _wsSubscription;

  OrderDetails? _orderDetails;
  bool _isLoadingDetails = true;

  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = true;

  @override
  void initState() {
    super.initState();
    _order = widget.initialOrder;
    _fetchOrderDetails();
    _startWebSocketListener();
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchOrderDetails() async {
    try {
      final details = await OrderService.instance.getDetails(orderId: _order.orderId);
      if (mounted) {
        setState(() {
          _orderDetails = details;
          _isLoadingDetails = false;
        });

        _fetchRoute(
          details.hotel.latitude,
          details.hotel.longitude,
          details.customerLatitude,
          details.customerLongitude,
        );
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

  int _scooterSegmentIndex = 0;

  LatLng _getScooterPosition(double progress) {
    if (_routePoints.isEmpty) {
      final hotelLat = _orderDetails?.hotel.latitude ?? 18.5284;
      final hotelLng = _orderDetails?.hotel.longitude ?? 73.8739;
      final customerLat = _orderDetails?.customerLatitude ?? 18.5204;
      final customerLng = _orderDetails?.customerLongitude ?? 73.8567;
      return LatLng(
        hotelLat + (customerLat - hotelLat) * progress,
        hotelLng + (customerLng - hotelLng) * progress,
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

    double targetLength = totalLength * progress;
    double currentLength = 0;

    for (int i = 0; i < _routePoints.length - 1; i++) {
      double len = segmentLengths[i];
      if (currentLength + len >= targetLength) {
        double ratio = (targetLength - currentLength) / len;
        _scooterSegmentIndex = i;
        final p1 = _routePoints[i];
        final p2 = _routePoints[i + 1];
        return LatLng(
          p1.latitude + (p2.latitude - p1.latitude) * ratio,
          p1.longitude + (p2.longitude - p1.longitude) * ratio,
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
    WebSocketService.instance.connect();

    _wsSubscription = WebSocketService.instance.messages.listen((msg) {
      final event = msg['event'] as String?;
      final eventData = msg['data'];
      if (eventData == null) return;

      if (event == 'ORDER_STATUS_UPDATED') {
        try {
          final orderId = eventData['order_id'] as int?;
          final status = eventData['status'] as String?;
          
          if (orderId == _order.orderId && status != null) {
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
              });
              // Refresh details
              _fetchOrderDetails();
            }
          }
        } catch (e) {
          debugPrint('Error parsing status update: $e');
        }
      } else if (event == 'DRIVER_LOCATION_UPDATED') {
        try {
          final driverId = eventData['driver_id'] as int?;
          final lat = double.tryParse(eventData['latitude'].toString());
          final lng = double.tryParse(eventData['longitude'].toString());

          if (lat != null && lng != null && _orderDetails?.deliveryPartner != null) {
            if (_orderDetails!.deliveryPartner!.id == driverId) {
              if (mounted) {
                setState(() {
                  _orderDetails!.deliveryPartner!.latitude = lat;
                  _orderDetails!.deliveryPartner!.longitude = lng;
                });
              }
            }
          }
        } catch (e) {
          debugPrint('Error parsing driver location update: $e');
        }
      }
    });
  }

  int _getCurrentStep(String status) {
    switch (status) {
      case 'created_order':
        return 0;
      case 'accepted':
      case 'preparing':
        return 1;
      case 'ready':
        return 2;
      case 'completed':
        return 3;
      default:
        return 0;
    }
  }

  double _getRouteProgress(String status) {
    switch (status) {
      case 'created_order':
        return 0.08;
      case 'accepted':
        return 0.25;
      case 'preparing':
        return 0.50;
      case 'ready':
        return 0.75;
      case 'completed':
        return 1.0;
      default:
        return 0.08;
    }
  }

  String _getEtaText(String status) {
    switch (status) {
      case 'created_order':
        return 'Arriving in 30-35 mins';
      case 'accepted':
      case 'preparing':
        return 'Arriving in 20-25 mins';
      case 'ready':
        return 'Arriving in 5-10 mins';
      case 'completed':
        return 'Delivered successfully!';
      default:
        return 'Arriving soon';
    }
  }



  @override
  Widget build(BuildContext context) {
    final currentStep = _getCurrentStep(_order.status);
    final progress = _getRouteProgress(_order.status);
    final etaText = _getEtaText(_order.status);
    
    // UI Theme colors
    const Color themeGreen = Color(0xFF10B981);
    const Color themeOrange = Color(0xFFF97316);
    const Color themeRed = Color(0xFFEF4444);
    const Color themeNavy = Color(0xFF1E2F4D);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFEAF5EE), // Pale light mint green at the top
              Color(0xFFF7FBF9), 
              Colors.white,      // Fades to pure white
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.25, 0.6],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header / AppBar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.arrow_back_rounded, size: 22, color: Colors.black87),
                      ),
                    ),
                    const Text(
                      'Track Order',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_rounded, size: 22, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    children: [
                      // Top Card (Tracking Progress & Map)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Progress steps row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildStepNode(
                                  isActive: currentStep >= 0,
                                  isCompleted: currentStep > 0,
                                  color: themeGreen,
                                  icon: Icons.check_rounded,
                                  label: 'Order\nPlaced',
                                ),
                                _buildStepLine(isActive: currentStep >= 1, color: themeOrange),
                                _buildStepNode(
                                  isActive: currentStep >= 1,
                                  isCompleted: currentStep > 1,
                                  color: themeOrange,
                                  icon: Icons.soup_kitchen_rounded,
                                  label: 'Food\nPreparing',
                                ),
                                _buildStepLine(isActive: currentStep >= 2, color: themeRed),
                                _buildStepNode(
                                  isActive: currentStep >= 2,
                                  isCompleted: currentStep > 2,
                                  color: themeRed,
                                  icon: Icons.delivery_dining_rounded,
                                  label: 'Out for\nDelivery',
                                ),
                                _buildStepLine(isActive: currentStep >= 3, color: themeGreen),
                                _buildStepNode(
                                  isActive: currentStep >= 3,
                                  isCompleted: currentStep > 3,
                                  color: themeGreen,
                                  icon: Icons.flag_rounded,
                                  label: 'Delivered',
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // ETA text
                            Text(
                              etaText,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Map Graphic
                            Container(
                              height: 145,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F7F5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: (_isLoadingDetails || _isLoadingRoute)
                                    ? const Center(child: CircularProgressIndicator(color: themeGreen))
                                    : (() {
                                         final hotelLat = _orderDetails?.hotel.latitude ?? 18.5284;
                                         final hotelLng = _orderDetails?.hotel.longitude ?? 73.8739;
                                         final customerLat = _orderDetails?.customerLatitude ?? 18.5204;
                                         final customerLng = _orderDetails?.customerLongitude ?? 73.8567;

                                         final hotelPoint = LatLng(hotelLat, hotelLng);
                                         final customerPoint = LatLng(customerLat, customerLng);

                                         // Calculate scooter point (use live driver coordinates if assigned)
                                         final LatLng scooterPoint;
                                         final List<LatLng> coveredPath;
                                         final List<LatLng> remainingPath;

                                         if (_orderDetails?.deliveryPartner != null && 
                                             _orderDetails!.deliveryPartner!.latitude != 0.0) {
                                           scooterPoint = LatLng(
                                             _orderDetails!.deliveryPartner!.latitude,
                                             _orderDetails!.deliveryPartner!.longitude,
                                           );
                                           
                                           final int idx = _getClosestRoutePointIndex(scooterPoint);
                                           coveredPath = _routePoints.isEmpty
                                               ? [hotelPoint, scooterPoint]
                                               : [..._routePoints.sublist(0, idx + 1), scooterPoint];
                                           remainingPath = _routePoints.isEmpty
                                               ? [scooterPoint, customerPoint]
                                               : [scooterPoint, ..._routePoints.sublist(idx + 1)];
                                         } else {
                                           scooterPoint = _getScooterPosition(progress);
                                           coveredPath = _routePoints.isEmpty
                                               ? [hotelPoint, scooterPoint]
                                               : [..._routePoints.sublist(0, _scooterSegmentIndex + 1), scooterPoint];
                                           remainingPath = _routePoints.isEmpty
                                               ? [scooterPoint, customerPoint]
                                               : [scooterPoint, ..._routePoints.sublist(_scooterSegmentIndex + 1)];
                                         }

                                         // Calculate map center (midpoint)
                                         final centerLat = (hotelPoint.latitude + customerPoint.latitude) / 2;
                                         final centerLng = (hotelPoint.longitude + customerPoint.longitude) / 2;
                                         final mapCenter = LatLng(centerLat, centerLng);

                                        return FlutterMap(
                                          options: MapOptions(
                                            initialCenter: mapCenter,
                                            initialZoom: 13.5,
                                            interactionOptions: const InteractionOptions(
                                              flags: InteractiveFlag.all,
                                            ),
                                          ),
                                          children: [
                                            TileLayer(
                                              urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                                              subdomains: const ['a', 'b', 'c', 'd'],
                                              userAgentPackageName: 'com.example.first_demo',
                                            ),
                                            PolylineLayer(
                                              polylines: [
                                                // Covered road route path (solid royal blue)
                                                Polyline(
                                                  points: coveredPath,
                                                  color: const Color(0xFF2563EB),
                                                  strokeWidth: 6.0,
                                                ),
                                                // Remaining road route path (solid light blue)
                                                Polyline(
                                                  points: remainingPath,
                                                  color: const Color(0xFF93C5FD),
                                                  strokeWidth: 6.0,
                                                ),
                                              ],
                                            ),
                                            MarkerLayer(
                                              markers: [
                                                // Hotel Marker
                                                Marker(
                                                  point: hotelPoint,
                                                  width: 32,
                                                  height: 32,
                                                  child: Container(
                                                    decoration: const BoxDecoration(
                                                      color: Colors.white,
                                                      shape: BoxShape.circle,
                                                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                                                    ),
                                                    child: const Icon(Icons.storefront_rounded, size: 16, color: Colors.redAccent),
                                                  ),
                                                ),
                                                // Customer Marker
                                                Marker(
                                                  point: customerPoint,
                                                  width: 32,
                                                  height: 32,
                                                  child: Container(
                                                    decoration: const BoxDecoration(
                                                      color: themeNavy,
                                                      shape: BoxShape.circle,
                                                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                                                    ),
                                                    child: const Icon(Icons.location_on_rounded, size: 16, color: Colors.white),
                                                  ),
                                                ),
                                                // Scooter Marker
                                                Marker(
                                                  point: scooterPoint,
                                                  width: 34,
                                                  height: 34,
                                                  child: Container(
                                                    padding: const EdgeInsets.all(5),
                                                    decoration: const BoxDecoration(
                                                      color: Colors.white,
                                                      shape: BoxShape.circle,
                                                      boxShadow: [
                                                        BoxShadow(color: Colors.black12, blurRadius: 4, spreadRadius: 1),
                                                      ],
                                                    ),
                                                    child: const Icon(
                                                      Icons.delivery_dining_rounded,
                                                      color: themeGreen,
                                                      size: 16,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        );
                                      }()),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Middle Card (Hotel details & Bill Receipt)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Hotel Header (White section)
                            Padding(
                              padding: const EdgeInsets.all(18),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Red Hotel circular avatar
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF6B1D1D),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.restaurant_rounded, color: Color(0xFFFFD700), size: 24),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'HOTEL NAME',
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _orderDetails?.hotel.hotelName ?? _order.hotelName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on_outlined, size: 13, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                _orderDetails?.hotel.hotelAddress ?? 'Campus Food Court, Main Bldg',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Star rating badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFFBEB),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFFEF3C7)),
                                    ),
                                    child: Row(
                                      children: const [
                                        Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                        SizedBox(width: 2),
                                        Text(
                                          '4.0',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Separator / Order ID line
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                              color: const Color(0xFFF9FAFB),
                              child: Text(
                                'Order ID: #${_order.orderId}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                            ),

                            // Receipt Section (Navy Blue background)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: const BoxDecoration(
                                color: themeNavy,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(24),
                                  bottomRight: Radius.circular(24),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // List items
                                  _isLoadingDetails
                                      ? const Center(child: Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                                        ))
                                      : Column(
                                          children: (_orderDetails?.items ?? [
                                            // Mock fallback items if API load fails
                                            OrderDetailsItem(foodName: 'Menu Meal', quantity: widget.initialOrder.itemCount, price: _order.grandTotal),
                                          ]).map((item) {
                                            return Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 6),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    '${item.foodName} (${item.quantity}x)',
                                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                                                  ),
                                                  Text(
                                                    '- ₹${(item.price * item.quantity).toStringAsFixed(0)}',
                                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),

                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Total items', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                      Text(
                                        '${_orderDetails?.items.length ?? _order.itemCount}',
                                        style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 14),
                                  const _DottedDivider(color: Colors.white30),
                                  const SizedBox(height: 14),

                                  // Bill Summary Header
                                  Row(
                                    children: [
                                      const Text(
                                        'Bill Summary',
                                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(color: themeRed, shape: BoxShape.circle),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Item Total:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                      Text('₹${(_orderDetails?.subtotal ?? (_order.grandTotal - 30 - 45)).toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Delivery Fee:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                      Text('₹${(_orderDetails?.deliveryFee ?? 30.0).toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Taxes & Charges:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                      Text('₹${(_orderDetails?.taxAmount ?? 45.0).toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                                    ],
                                  ),

                                  const SizedBox(height: 14),
                                  const _DottedDivider(color: Colors.white30),
                                  const SizedBox(height: 14),

                                  // Grand Total row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'GRAND TOTAL',
                                        style: TextStyle(color: Color(0xFFE2F05D), fontSize: 16, fontWeight: FontWeight.w900),
                                      ),
                                      Text(
                                        '₹${_order.grandTotal.toStringAsFixed(0)}',
                                        style: const TextStyle(color: Color(0xFFE2F05D), fontSize: 18, fontWeight: FontWeight.w900),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _orderDetails?.walletDeducted == _orderDetails?.grandTotal
                                        ? 'Paid via Wallet'
                                        : 'Paid via ${_orderDetails == null ? (_order.walletDeducted > 0 ? "Wallet/UPI" : "UPI") : _orderDetails!.paymentMethod}',
                                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Bottom Card (Delivery Partner)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: _orderDetails?.deliveryPartner == null
                            ? Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFFEFF6FF),
                                      ),
                                      child: const Icon(
                                        Icons.sports_motorsports_rounded,
                                        color: Color(0xFF2563EB),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: const [
                                          Text(
                                            'Awaiting Driver Assignment',
                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            'We will assign a delivery partner shortly...',
                                            style: TextStyle(fontSize: 11, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.grey.shade200,
                                          image: DecorationImage(
                                            image: NetworkImage(_orderDetails!.deliveryPartner!.avatarUrl.isNotEmpty
                                                ? _orderDetails!.deliveryPartner!.avatarUrl
                                                : 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=200'),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Your Delivery Partner:',
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _orderDetails!.deliveryPartner!.name,
                                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                const Icon(Icons.star_rounded, color: Colors.amber, size: 13),
                                                const SizedBox(width: 2),
                                                Text(
                                                  _orderDetails!.deliveryPartner!.rating,
                                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.black87),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  '•  ${_orderDetails!.deliveryPartner!.vehicleNumber}',
                                                  style: const TextStyle(fontSize: 11.5, color: Colors.grey, fontWeight: FontWeight.w500),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Action buttons row
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                          ),
                                          onPressed: () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Calling ${_orderDetails!.deliveryPartner!.name}: ${_orderDetails!.deliveryPartner!.phoneNumber}'),
                                                backgroundColor: const Color(0xFF10B981),
                                              ),
                                            );
                                          },
                                          child: const Text('Call', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 14)),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        flex: 2,
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: Color(0xFFF97316), width: 1.5),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                          ),
                                          onPressed: () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Messaging ${_orderDetails!.deliveryPartner!.name}...'),
                                                backgroundColor: const Color(0xFFF97316),
                                              ),
                                            );
                                          },
                                          child: const Text('Message', style: TextStyle(color: Color(0xFFF97316), fontWeight: FontWeight.bold, fontSize: 14)),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        flex: 3,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF2563EB),
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                          ),
                                          onPressed: () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Redirecting to Help & Support...'),
                                                backgroundColor: Color(0xFF2563EB),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15),
                                          label: const Text('Help & Support', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepNode({
    required bool isActive,
    required bool isCompleted,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted
                ? color
                : (isActive ? Colors.white : Colors.grey.shade100),
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? color : Colors.grey.shade300,
              width: 2,
            ),
            boxShadow: isActive ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 6)] : null,
          ),
          child: Icon(
            isCompleted ? Icons.check_rounded : icon,
            size: 16,
            color: isCompleted
                ? Colors.white
                : (isActive ? color : Colors.grey.shade400),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.black87 : Colors.grey.shade400,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine({required bool isActive, required Color color}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Container(
          height: 3,
          color: isActive ? color : Colors.grey.shade200,
        ),
      ),
    );
  }
}



// Custom dotted line widget
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
