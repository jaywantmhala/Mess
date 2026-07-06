// lib/screens/select_location_screen.dart
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../services/geocoding_service.dart';

class SelectLocationScreen extends StatefulWidget {
  const SelectLocationScreen({super.key});

  @override
  State<SelectLocationScreen> createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> {
  final MapController _mapController = MapController();
  final LatLng _initialLocation = const LatLng(19.0760, 72.8777); // Default to Mumbai
  LatLng _currentLocation = const LatLng(19.0760, 72.8777);

  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _suggestions = [];
  bool _isMapLoading = false;

  String _primaryAddress = 'Loading Location...';
  String _secondaryAddress = '';

  Timer? _searchDebounce;
  Timer? _geocodeDebounce;

  Map<String, dynamic>? _lastGeocodedData;
  List<Marker> _poiMarkers = [];
  LatLng? _gpsLocation;
  static const String _googleApiKey = 'AIzaSyDuZC6kFobB0pnp-k3VcxQIjvb0EhgfnVI';

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  /// Gets the exact device location on load
  Future<void> _getUserLocation() async {
    setState(() => _isMapLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Location services are disabled.';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Location permissions are denied.';
      }

      if (permission == LocationPermission.deniedForever) throw 'Location permissions are permanently denied.';

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final newLatLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _gpsLocation = newLatLng;
        _currentLocation = newLatLng;
      });

      _mapController.move(newLatLng, 17.5);

      await _reverseGeocode(newLatLng.latitude, newLatLng.longitude);
    } catch (e) {
      setState(() {
        _primaryAddress = 'Cannot find address';
        _secondaryAddress = e.toString();
      });
    } finally {
      setState(() => _isMapLoading = false);
    }
  }

  /// Google reverse geocodes the coordinates and parses them into a primary name and secondary sub-address
  Future<void> _reverseGeocode(double lat, double lng) async {
    _geocodeDebounce?.cancel();
    setState(() {
      _primaryAddress = 'Loading Address...';
      _secondaryAddress = 'Fetching coordinates information';
    });
    _geocodeDebounce = Timer(const Duration(milliseconds: 800), () async {
      try {
        final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$_googleApiKey',
        );
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          if (body['status'] == 'OK' && body['results'] != null && (body['results'] as List).isNotEmpty) {
            final firstResult = (body['results'] as List).first as Map<String, dynamic>;
            final placeId = firstResult['place_id'] as String? ?? '';
            final addressData = _parseGoogleAddressComponents(firstResult, placeId, lat, lng);
            
            if (mounted) {
              setState(() {
                _primaryAddress = addressData['primary_address'] as String;
                _secondaryAddress = addressData['secondary_address'] as String;
                _lastGeocodedData = addressData;
              });
              _fetchNearbyPOIs(lat, lng);
            }
            return;
          }
        }
        
        // Fallback if API fails or doesn't return results
        if (mounted) {
          setState(() {
            _primaryAddress = 'Selected Position';
            _secondaryAddress = 'Coordinates: (${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)})';
            _lastGeocodedData = {
              'hotel_address': 'Coordinates: (${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)})',
              'latitude': lat,
              'longitude': lng,
            };
          });
        }
      } catch (e) {
        print('Reverse geocoding error: $e');
        if (mounted) {
          setState(() {
            _primaryAddress = 'Selected Position';
            _secondaryAddress = 'Coordinates: (${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)})';
          });
        }
      }
    });
  }

  /// Parses the Google Maps geocoding/places response to extract location properties
  Map<String, dynamic> _parseGoogleAddressComponents(
      Map<String, dynamic> result, String placeId, double lat, double lng) {
    final components = result['address_components'] as List? ?? [];
    final formattedAddress = result['formatted_address'] as String? ?? '';

    String city = '';
    String area = '';
    String state = '';
    String country = '';
    String pincode = '';
    String landmark = '';

    for (var comp in components) {
      final types = comp['types'] as List? ?? [];
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
      } else if (types.contains('sublocality_level_2') || types.contains('neighborhood') || types.contains('premise') || types.contains('point_of_interest')) {
        if (landmark.isEmpty) {
          landmark = longName;
        } else {
          landmark = '$landmark, $longName';
        }
      }
    }

    String primary = '';
    String secondary = '';
    if (formattedAddress.isNotEmpty) {
      final parts = formattedAddress.split(',');
      if (parts.isNotEmpty) {
        primary = parts.first.trim();
        secondary = parts.skip(1).join(',').trim();
      } else {
        primary = formattedAddress;
      }
    }

    if (primary.isEmpty) {
      primary = 'Selected Position';
      secondary = 'Coordinates: (${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)})';
    }

    return {
      'primary_address': primary,
      'secondary_address': secondary,
      'hotel_address': formattedAddress.isNotEmpty ? formattedAddress : '$primary, $secondary',
      'latitude': lat,
      'longitude': lng,
      'place_id': placeId,
      'city': city,
      'area': area,
      'state': state,
      'country': country,
      'pincode': pincode,
      'landmark': landmark,
    };
  }

  /// Shows the full screen search bottom sheet
  void _showSearchBottomSheet() {
    _searchController.clear();
    _suggestions = [];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.85,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Address',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.black),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black87, width: 1.2),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        onChanged: (val) {
                          if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
                          _searchDebounce = Timer(const Duration(milliseconds: 600), () async {
                            if (val.trim().isEmpty) {
                              setModalState(() => _suggestions = []);
                              return;
                            }
                            try {
                              final url = Uri.parse(
                                'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(val)}&key=$_googleApiKey&components=country:in',
                              );
                              final response = await http.get(url);
                              if (response.statusCode == 200) {
                                final data = jsonDecode(response.body) as Map<String, dynamic>;
                                if (data['status'] == 'OK' && data['predictions'] != null) {
                                  final predictions = data['predictions'] as List;
                                  setModalState(() {
                                    _suggestions = predictions.map((pred) => {
                                      'name': pred['structured_formatting']?['main_text'] ?? '',
                                      'display_name': pred['description'] ?? '',
                                      'place_id': pred['place_id'] ?? '',
                                    }).toList();
                                  });
                                }
                              }
                            } catch (e) {
                              print('Google Autocomplete search error: $e');
                            }
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search for apartment, street name...',
                          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                          prefixIcon: const Icon(Icons.search, color: Colors.black54),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close, color: Colors.black54),
                                  onPressed: () {
                                    _searchController.clear();
                                    setModalState(() {
                                      _suggestions = [];
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.separated(
                        itemCount: _suggestions.length,
                        separatorBuilder: (context, index) => const Divider(color: Colors.black12, height: 1),
                        itemBuilder: (context, index) {
                          final item = _suggestions[index];
                          final name = item['name'] as String? ?? '';
                          final displayName = item['display_name'] as String? ?? '';
                          final subtitle = displayName.startsWith(name)
                              ? displayName.substring(name.length).replaceAll(RegExp(r'^,\s*'), '')
                              : displayName;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 4),
                            leading: const Icon(Icons.location_on_outlined, color: Colors.black87),
                            title: Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87),
                            ),
                            subtitle: Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _selectSuggestion(item);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Fetches Google Place Details and updates pin & map center
  Future<void> _fetchPlaceDetails(String placeId) async {
    setState(() => _isMapLoading = true);
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry,address_components,formatted_address&key=$_googleApiKey',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['status'] == 'OK' && body['result'] != null) {
          final result = body['result'] as Map<String, dynamic>;
          final geometry = result['geometry'] as Map<String, dynamic>?;
          final location = geometry?['location'] as Map<String, dynamic>?;
          if (location != null) {
            final lat = double.tryParse(location['lat'].toString()) ?? 0.0;
            final lng = double.tryParse(location['lng'].toString()) ?? 0.0;
            final targetLatLng = LatLng(lat, lng);
            
            final addressData = _parseGoogleAddressComponents(result, placeId, lat, lng);
            
            setState(() {
              _currentLocation = targetLatLng;
              _suggestions = [];
              _searchController.clear();
              _primaryAddress = addressData['primary_address'] as String;
              _secondaryAddress = addressData['secondary_address'] as String;
              _lastGeocodedData = addressData;
              FocusScope.of(context).unfocus();
            });
            
            _mapController.move(targetLatLng, 18.0);
            _fetchNearbyPOIs(lat, lng);
          }
        }
      }
    } catch (e) {
      print('Place Details error: $e');
    } finally {
      setState(() => _isMapLoading = false);
    }
  }

  /// Triggered when user selects a search suggestion
  void _selectSuggestion(Map<String, dynamic> suggestion) {
    final placeId = suggestion['place_id'] as String? ?? '';
    if (placeId.isNotEmpty) {
      _fetchPlaceDetails(placeId);
    }
  }

  /// Fetch nearby POIs (Hospitals, Schools, Parks, Cafes, etc.) from Google Places Nearby Search
  Future<void> _fetchNearbyPOIs(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&radius=300&key=$_googleApiKey',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['status'] == 'OK' && body['results'] != null) {
          final results = body['results'] as List;
          final List<Marker> newMarkers = [];
          for (var item in results) {
            final loc = item['geometry']?['location'];
            if (loc == null) continue;
            final pLat = double.tryParse(loc['lat'].toString()) ?? 0.0;
            final pLng = double.tryParse(loc['lng'].toString()) ?? 0.0;
            final types = item['types'] as List? ?? [];
            final name = item['name'] as String? ?? '';
            
            IconData icon = Icons.place_rounded;
            Color color = Colors.orange;
            
            if (types.contains('school') || types.contains('university')) {
              icon = Icons.school_rounded;
              color = Colors.blue;
            } else if (types.contains('hospital') || types.contains('doctor') || types.contains('health')) {
              icon = Icons.local_hospital_rounded;
              color = Colors.redAccent;
            } else if (types.contains('restaurant') || types.contains('food')) {
              icon = Icons.restaurant_rounded;
              color = Colors.teal;
            } else if (types.contains('cafe') || types.contains('bar')) {
              icon = Icons.local_cafe_rounded;
              color = Colors.brown;
            } else if (types.contains('park') || types.contains('tourist_attraction')) {
              icon = Icons.park_rounded;
              color = Colors.green;
            } else if (types.contains('place_of_worship') || types.contains('church') || types.contains('hindu_temple') || types.contains('mosque')) {
              icon = Icons.church_rounded;
              color = Colors.indigo;
            } else if (types.contains('shopping_mall') || types.contains('store')) {
              icon = Icons.shopping_bag_rounded;
              color = Colors.purple;
            } else if (types.contains('bank') || types.contains('atm')) {
              icon = Icons.account_balance_rounded;
              color = Colors.blueGrey;
            }
            
            newMarkers.add(
              Marker(
                point: LatLng(pLat, pLng),
                width: 32,
                height: 32,
                child: Tooltip(
                  message: name,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                ),
              ),
            );
          }
          if (mounted) {
            setState(() {
              _poiMarkers = newMarkers;
            });
          }
        }
      }
    } catch (e) {
      print('POI fetch error: $e');
    }
  }

  String get _distanceLabel {
    if (_gpsLocation == null) return '';
    final distance = Geolocator.distanceBetween(
      _gpsLocation!.latitude,
      _gpsLocation!.longitude,
      _currentLocation.latitude,
      _currentLocation.longitude,
    );
    if (distance < 1000) {
      return 'Pin location is ${distance.toStringAsFixed(0)} m away from your current location';
    } else {
      return 'Pin location is ${(distance / 1000.0).toStringAsFixed(1)} km away from your current location';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    _searchDebounce?.cancel();
    _geocodeDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          'Select Your Location',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black, fontSize: 16),
        ),
      ),
      body: Stack(
        children: [
          // OpenStreetMap viewport using CartoDB Positron theme & High-DPI support
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _initialLocation,
                initialZoom: 17.0,
                onPositionChanged: (position, hasGesture) {
                  if (hasGesture) {
                    _currentLocation = position.center ?? _currentLocation;
                  }
                },
                onMapEvent: (event) {
                  if (event is MapEventMoveEnd) {
                    _reverseGeocode(_currentLocation.latitude, _currentLocation.longitude);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                  userAgentPackageName: 'com.example.vendor_app',
                ),
                MarkerLayer(
                  markers: [
                    if (_gpsLocation != null)
                      Marker(
                        point: _gpsLocation!,
                        width: 40,
                        height: 40,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF3B82F6).withOpacity(0.2),
                              ),
                            ),
                            Container(
                              width: 14,
                              height: 14,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ..._poiMarkers,
                  ],
                ),
                // Accuracy circle overlay matching the Zomato photo
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _currentLocation,
                      radius: 35,
                      useRadiusInMeter: true,
                      color: const Color(0xFFEA1D5D).withOpacity(0.08),
                      borderColor: const Color(0xFFEA1D5D).withOpacity(0.2),
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Custom pin and tooltip overlay matching image
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 60.0), // align pin tip with center point
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161E2E).withOpacity(0.95), // Dark slate tooltip
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Column(
                      children: [
                        Text(
                          'Order will be delivered here',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Place the pin to your exact location',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -2),
                    child: Icon(Icons.arrow_drop_down, color: const Color(0xFF161E2E).withOpacity(0.95), size: 24),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -12),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(Icons.location_on, size: 54, color: Color(0xFFEA1D5D)), // Match Zomato Pink
                        Positioned(
                          top: 10,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Float dummy search bar
          Positioned(
            top: 16,
            left: isTablet ? size.width * 0.15 : 16,
            right: isTablet ? size.width * 0.15 : 16,
            child: GestureDetector(
              onTap: _showSearchBottomSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: Colors.grey[600], size: 22),
                    const SizedBox(width: 12),
                    Text(
                      'Search for apartment, street name...',
                      style: TextStyle(color: Colors.grey[500], fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Float Geolocate Button (Bottom Right)
          Positioned(
            bottom: 230,
            right: isTablet ? size.width * 0.15 : 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.my_location_rounded, color: Colors.black87),
                onPressed: _getUserLocation,
              ),
            ),
          ),

          // Bottom card showing address and Confirm button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              alignment: Alignment.center,
              child: Container(
                constraints: BoxConstraints(maxWidth: isTablet ? 600 : double.infinity),
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _primaryAddress,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _secondaryAddress,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_distanceLabel.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _distanceLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD32F2F),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          final fullAddress = _secondaryAddress.isEmpty
                              ? _primaryAddress
                              : '$_primaryAddress, $_secondaryAddress';
                          Navigator.pop(context, {
                            'address': fullAddress,
                            'hotel_address': _lastGeocodedData?['hotel_address'] ?? fullAddress,
                            'latitude': _currentLocation.latitude,
                            'longitude': _currentLocation.longitude,
                            'place_id': _lastGeocodedData?['place_id'],
                            'city': _lastGeocodedData?['city'],
                            'area': _lastGeocodedData?['area'],
                            'state': _lastGeocodedData?['state'],
                            'country': _lastGeocodedData?['country'],
                            'pincode': _lastGeocodedData?['pincode'],
                            'landmark': _lastGeocodedData?['landmark'],
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEA1D5D), // Match Zomato Pink
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Confirm Location',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_isMapLoading)
            Container(
              color: Colors.white.withOpacity(0.6),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFFEA1D5D)),
              ),
            ),
        ],
      ),
    );
  }
}
