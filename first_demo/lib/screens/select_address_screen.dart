// lib/screens/select_address_screen.dart
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../models/address_data.dart';

// ── Design tokens (matching light coral theme) ────────────────────────────────
const _kCoral       = Color(0xFFF07070);
const _kTextDark    = Color(0xFF1A1A2E);
const _kTextMuted   = Color(0xFF6B7280);
const _kBgPage      = Color(0xFFF9FAFB);

// Same Google API key as vendor app
const _kGoogleApiKey = 'AIzaSyDuZC6kFobB0pnp-k3VcxQIjvb0EhgfnVI';

class SelectAddressScreen extends StatefulWidget {
  const SelectAddressScreen({super.key});

  @override
  State<SelectAddressScreen> createState() => _SelectAddressScreenState();
}

class _SelectAddressScreenState extends State<SelectAddressScreen> {
  final MapController _mapController = MapController();

  // Default center: Mumbai
  LatLng _currentLocation = const LatLng(19.0760, 72.8777);

  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _suggestions = [];
  bool _isMapLoading = false;

  String _primaryAddress   = 'Loading Location...';
  String _secondaryAddress = '';

  Timer? _searchDebounce;
  Timer? _geocodeDebounce;

  Map<String, dynamic>? _lastGeocodedData;
  List<Marker> _poiMarkers = [];
  LatLng? _gpsLocation;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    _searchDebounce?.cancel();
    _geocodeDebounce?.cancel();
    super.dispose();
  }

  // ── GPS ───────────────────────────────────────────────────────────────────
  Future<void> _getUserLocation() async {
    setState(() => _isMapLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Location services are disabled.';

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
      final newLatLng = LatLng(position.latitude, position.longitude);

      if (!mounted) return;
      setState(() {
        _gpsLocation    = newLatLng;
        _currentLocation = newLatLng;
      });

      _mapController.move(newLatLng, 17.5);
      await _reverseGeocode(newLatLng.latitude, newLatLng.longitude);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _primaryAddress   = 'Cannot find location';
        _secondaryAddress = e.toString();
      });
    } finally {
      if (mounted) setState(() => _isMapLoading = false);
    }
  }

  // ── Reverse geocode ───────────────────────────────────────────────────────
  Future<void> _reverseGeocode(double lat, double lng) async {
    _geocodeDebounce?.cancel();
    if (!mounted) return;
    setState(() {
      _primaryAddress   = 'Finding address...';
      _secondaryAddress = '';
    });

    _geocodeDebounce = Timer(const Duration(milliseconds: 800), () async {
      try {
        final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$_kGoogleApiKey',
        );
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          if (body['status'] == 'OK' &&
              body['results'] != null &&
              (body['results'] as List).isNotEmpty) {
            final first = (body['results'] as List).first as Map<String, dynamic>;
            final placeId = first['place_id'] as String? ?? '';
            final data = _parseAddressComponents(first, placeId, lat, lng);
            if (mounted) {
              setState(() {
                _primaryAddress    = data['primary_address'] as String;
                _secondaryAddress  = data['secondary_address'] as String;
                _lastGeocodedData  = data;
              });
              _fetchNearbyPOIs(lat, lng);
            }
            return;
          }
        }
        // Fallback
        if (mounted) {
          setState(() {
            _primaryAddress   = 'Selected Position';
            _secondaryAddress = '(${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)})';
            _lastGeocodedData = {
              'hotel_address': _secondaryAddress,
              'latitude': lat, 'longitude': lng,
            };
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _primaryAddress   = 'Selected Position';
            _secondaryAddress = '(${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)})';
          });
        }
      }
    });
  }

  // ── Parse Google address components ──────────────────────────────────────
  Map<String, dynamic> _parseAddressComponents(
    Map<String, dynamic> result, String placeId, double lat, double lng) {
    final components      = result['address_components'] as List? ?? [];
    final formattedAddress = result['formatted_address'] as String? ?? '';

    String city = '', area = '', state = '', country = '', pincode = '', landmark = '';

    for (final comp in components) {
      final types    = comp['types'] as List? ?? [];
      final longName = comp['long_name'] as String? ?? '';
      if (types.contains('locality')) {
        city = longName;
      } else if (types.contains('sublocality_level_1') || types.contains('sublocality')) {
        area = longName;
      } else if (types.contains('administrative_area_level_1')) {
        state = longName;
      } else if (types.contains('country')) {
        country = longName;
      } else if (types.contains('postal_code')) {
        pincode = longName;
      } else if (types.contains('sublocality_level_2') ||
          types.contains('neighborhood') ||
          types.contains('premise') ||
          types.contains('point_of_interest')) {
        landmark = landmark.isEmpty ? longName : '$landmark, $longName';
      }
    }

    String primary = '', secondary = '';
    if (formattedAddress.isNotEmpty) {
      final parts = formattedAddress.split(',');
      primary   = parts.first.trim();
      secondary = parts.skip(1).join(',').trim();
    }
    if (primary.isEmpty) {
      primary   = 'Selected Position';
      secondary = '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
    }

    return {
      'primary_address':   primary,
      'secondary_address': secondary,
      'hotel_address': formattedAddress.isNotEmpty ? formattedAddress : '$primary, $secondary',
      'latitude':  lat,
      'longitude': lng,
      'place_id':  placeId,
      'city':     city,
      'area':     area,
      'state':    state,
      'country':  country,
      'pincode':  pincode,
      'landmark': landmark,
    };
  }

  // ── Google Autocomplete ───────────────────────────────────────────────────
  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(query)}'
        '&key=$_kGoogleApiKey'
        '&components=country:in',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['status'] == 'OK' && data['predictions'] != null) {
          setState(() {
            _suggestions = (data['predictions'] as List).map((p) => {
              'name':         p['structured_formatting']?['main_text']  ?? '',
              'display_name': p['description'] ?? '',
              'place_id':     p['place_id'] ?? '',
            }).toList();
          });
        }
      }
    } catch (_) {}
  }

  // ── Place details ─────────────────────────────────────────────────────────
  Future<void> _fetchPlaceDetails(String placeId) async {
    setState(() => _isMapLoading = true);
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&fields=geometry,address_components,formatted_address'
        '&key=$_kGoogleApiKey',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['status'] == 'OK' && body['result'] != null) {
          final result   = body['result'] as Map<String, dynamic>;
          final geometry = result['geometry'] as Map<String, dynamic>?;
          final location = geometry?['location'] as Map<String, dynamic>?;
          if (location != null) {
            final lat  = double.tryParse(location['lat'].toString()) ?? 0.0;
            final lng  = double.tryParse(location['lng'].toString()) ?? 0.0;
            final target = LatLng(lat, lng);
            final data   = _parseAddressComponents(result, placeId, lat, lng);
            if (mounted) {
              setState(() {
                _currentLocation  = target;
                _suggestions      = [];
                _primaryAddress   = data['primary_address'] as String;
                _secondaryAddress = data['secondary_address'] as String;
                _lastGeocodedData = data;
              });
              _searchController.clear();
              FocusScope.of(context).unfocus();
              _mapController.move(target, 18.0);
              _fetchNearbyPOIs(lat, lng);
            }
          }
        }
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isMapLoading = false);
    }
  }

  // ── Nearby POIs ───────────────────────────────────────────────────────────
  Future<void> _fetchNearbyPOIs(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=$lat,$lng&radius=300&key=$_kGoogleApiKey',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['status'] == 'OK' && body['results'] != null) {
          final List<Marker> markers = [];
          for (final item in (body['results'] as List)) {
            final loc = item['geometry']?['location'];
            if (loc == null) continue;
            final pLat  = double.tryParse(loc['lat'].toString()) ?? 0.0;
            final pLng  = double.tryParse(loc['lng'].toString()) ?? 0.0;
            final types = item['types'] as List? ?? [];
            final name  = item['name'] as String? ?? '';

            IconData icon = Icons.place_rounded;
            Color    color = Colors.orange;
            if (types.contains('school') || types.contains('university')) {
              icon = Icons.school_rounded; color = Colors.blue;
            } else if (types.contains('hospital') || types.contains('health')) {
              icon = Icons.local_hospital_rounded; color = Colors.redAccent;
            } else if (types.contains('restaurant') || types.contains('food')) {
              icon = Icons.restaurant_rounded; color = Colors.teal;
            } else if (types.contains('cafe')) {
              icon = Icons.local_cafe_rounded; color = Colors.brown;
            } else if (types.contains('park')) {
              icon = Icons.park_rounded; color = Colors.green;
            } else if (types.contains('shopping_mall') || types.contains('store')) {
              icon = Icons.shopping_bag_rounded; color = Colors.purple;
            }

            markers.add(Marker(
              point: LatLng(pLat, pLng),
              width: 30, height: 30,
              child: Tooltip(
                message: name,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: Colors.white, size: 14),
                ),
              ),
            ));
          }
          if (mounted) setState(() => _poiMarkers = markers);
        }
      }
    } catch (_) {}
  }

  // ── Distance label ────────────────────────────────────────────────────────
  String get _distanceLabel {
    if (_gpsLocation == null) return '';
    final d = Geolocator.distanceBetween(
      _gpsLocation!.latitude, _gpsLocation!.longitude,
      _currentLocation.latitude, _currentLocation.longitude,
    );
    if (d < 1000) return '${d.toStringAsFixed(0)} m from your current location';
    return '${(d / 1000).toStringAsFixed(1)} km from your current location';
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size     = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final hPad     = isTablet ? size.width * 0.15 : 16.0;

    return Scaffold(
      backgroundColor: _kBgPage,
      // White AppBar matching light theme
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _kTextDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Set Delivery Location',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: _kTextDark,
            fontSize: 17,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFEEF0F4)),
        ),
      ),
      body: Stack(
        children: [
          // ── Full-screen Map ─────────────────────────────────────────────
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation,
                initialZoom: 17.0,
                onPositionChanged: (position, hasGesture) {
                  if (hasGesture) {
                    _currentLocation = position.center ?? _currentLocation;
                  }
                },
                onMapEvent: (event) {
                  if (event is MapEventMoveEnd) {
                    _reverseGeocode(
                      _currentLocation.latitude,
                      _currentLocation.longitude,
                    );
                  }
                },
              ),
              children: [
                // Google Maps-style tile layer
                TileLayer(
                  urlTemplate: 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                  userAgentPackageName: 'com.example.first_demo',
                ),
                // GPS dot marker
                MarkerLayer(
                  markers: [
                    if (_gpsLocation != null)
                      Marker(
                        point: _gpsLocation!,
                        width: 40, height: 40,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _kCoral.withValues(alpha: 0.15),
                              ),
                            ),
                            Container(
                              width: 14, height: 14,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle, color: Colors.white,
                                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                              ),
                            ),
                            Container(
                              width: 10, height: 10,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle, color: _kCoral,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ..._poiMarkers,
                  ],
                ),
                // Accuracy circle around pin
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _currentLocation,
                      radius: 35,
                      useRadiusInMeter: true,
                      color: _kCoral.withValues(alpha: 0.07),
                      borderColor: _kCoral.withValues(alpha: 0.2),
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Centre pin with tooltip ──────────────────────────────────────
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 48.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dark tooltip bubble
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.14),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Column(
                      children: [
                        Text(
                          'Deliver here',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Place the pin to your exact location',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Coral drop pin
                  const Icon(
                    Icons.location_on_rounded,
                    size: 52,
                    color: _kCoral,
                  ),
                ],
              ),
            ),
          ),

          // ── Floating search bar ───────────────────────────────────────────
          Positioned(
            top: 16,
            left: hPad,
            right: hPad,
            child: Column(
              children: [
                // Search input
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.07),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
                      _searchDebounce = Timer(
                        const Duration(milliseconds: 500),
                        () => _searchAddress(val),
                      );
                    },
                    style: const TextStyle(fontSize: 14.5, color: _kTextDark),
                    decoration: InputDecoration(
                      hintText: 'Search apartment, area, city...',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded, color: _kCoral),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear_rounded, color: Colors.grey[400]),
                              onPressed: () => setState(() {
                                _searchController.clear();
                                _suggestions = [];
                              }),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    ),
                  ),
                ),

                // Suggestions dropdown
                if (_suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 260),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _suggestions.length,
                      itemBuilder: (_, i) {
                        final item        = _suggestions[i];
                        final name        = item['name'] as String? ?? '';
                        final displayName = item['display_name'] as String? ?? '';
                        final subtitle    = displayName.startsWith(name)
                            ? displayName.substring(name.length).replaceAll(RegExp(r'^,\s*'), '')
                            : displayName;
                        return ListTile(
                          leading: const Icon(Icons.location_on_outlined, color: _kCoral),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12)),
                          onTap: () => _fetchPlaceDetails(item['place_id'] as String? ?? ''),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // ── GPS re-center button ──────────────────────────────────────────
          Positioned(
            bottom: 220,
            right: hPad,
            child: FloatingActionButton.small(
              backgroundColor: Colors.white,
              foregroundColor: _kCoral,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onPressed: _getUserLocation,
              child: const Icon(Icons.gps_fixed_rounded),
            ),
          ),

          // ── Bottom confirm card ───────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: isTablet ? 600 : double.infinity),
                padding: EdgeInsets.fromLTRB(
                  20, 20, 20,
                  20 + MediaQuery.of(context).padding.bottom,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 20,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 36, height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Pin icon + primary address
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _kCoral.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.location_on_rounded, color: _kCoral, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _primaryAddress,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: _kTextDark,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_secondaryAddress.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _secondaryAddress,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: _kTextMuted,
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (_distanceLabel.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.directions_walk_rounded, size: 12, color: _kCoral),
                                    const SizedBox(width: 4),
                                    Text(
                                      _distanceLabel,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: _kCoral,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Confirm button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isMapLoading ? null : _onConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kCoral,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: _kCoral.withValues(alpha: 0.5),
                          elevation: 4,
                          shadowColor: _kCoral.withValues(alpha: 0.35),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isMapLoading
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text(
                                'Confirm Location',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Loading overlay ───────────────────────────────────────────────
          if (_isMapLoading)
            Container(
              color: Colors.white.withValues(alpha: 0.55),
              child: const Center(
                child: CircularProgressIndicator(color: _kCoral),
              ),
            ),
        ],
      ),
    );
  }

  void _onConfirm() {
    final fullAddress = _secondaryAddress.isEmpty
        ? _primaryAddress
        : '$_primaryAddress, $_secondaryAddress';

    final address = AddressData(
      fullAddress: _lastGeocodedData?['hotel_address'] as String? ?? fullAddress,
      area:        _lastGeocodedData?['area']      as String? ?? '',
      city:        _lastGeocodedData?['city']      as String? ?? '',
      state:       _lastGeocodedData?['state']     as String? ?? '',
      country:     _lastGeocodedData?['country']   as String? ?? '',
      pincode:     _lastGeocodedData?['pincode']   as String? ?? '',
      landmark:    _lastGeocodedData?['landmark']  as String? ?? '',
      placeId:     _lastGeocodedData?['place_id']  as String? ?? '',
      latitude:    _lastGeocodedData?['latitude']  as double? ?? _currentLocation.latitude,
      longitude:   _lastGeocodedData?['longitude'] as double? ?? _currentLocation.longitude,
    );

    Navigator.pop(context, address);
  }
}
