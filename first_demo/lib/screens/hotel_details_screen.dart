// lib/screens/hotel_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../models/hotel.dart';

class HotelDetailsScreen extends StatelessWidget {
  final Hotel hotel;
  final Position? userPosition;

  const HotelDetailsScreen({
    super.key,
    required this.hotel,
    this.userPosition,
  });

  static const Color coral = Color(0xFFFF6F5E);
  static const Color textDark = Color(0xFF2B2B2B);
  static const Color textGrey = Color(0xFF9A9A9A);
  static const Color pageBg = Color(0xFFFFF3F1);

  @override
  Widget build(BuildContext context) {
    final hotelLatLng = LatLng(hotel.latitude, hotel.longitude);
    final userLatLng = userPosition != null
        ? LatLng(userPosition!.latitude, userPosition!.longitude)
        : null;

    // Center map on the hotel
    final mapCenter = hotelLatLng;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        title: Text(
          hotel.hotelName,
          style: const TextStyle(fontWeight: FontWeight.bold, color: textDark),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map Panel
            Container(
              height: 320,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: mapCenter,
                  initialZoom: 14.5,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.example.first_demo',
                  ),
                  if (userLatLng != null)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [userLatLng, hotelLatLng],
                          color: coral.withOpacity(0.8),
                          strokeWidth: 4.0,
                          isDotted: true,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      // Hotel Marker
                      Marker(
                        point: hotelLatLng,
                        width: 45,
                        height: 45,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: coral,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.storefront_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // User Marker (if location available)
                      if (userLatLng != null)
                        Marker(
                          point: userLatLng,
                          width: 40,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Details Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              hotel.hotelName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                          ),
                          if (hotel.distance != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: coral.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${hotel.distance!.toStringAsFixed(1)} km away',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: coral,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (hotel.landmark != null && hotel.landmark!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          hotel.landmark!,
                          style: TextStyle(
                            fontSize: 13,
                            color: coral,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: Color(0xFFF0F0F0)),
                      const SizedBox(height: 16),

                      // Contact Details
                      _buildInfoRow(Icons.person_rounded, 'Owner Name', hotel.ownerName),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.phone_rounded, 'Mobile Number', hotel.mobileNumber),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.email_rounded, 'Email Address', hotel.email),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.location_on_rounded, 'Full Address', hotel.hotelAddress),
                      
                      // Extra Location Details if available
                      if (hotel.city != null && hotel.city!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.location_city_rounded, 'City', hotel.city!),
                      ],
                      if (hotel.area != null && hotel.area!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.map_rounded, 'Area', hotel.area!),
                      ],
                      if (hotel.pincode != null && hotel.pincode!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.pin_drop_rounded, 'Pincode', hotel.pincode!),
                      ],

                      const SizedBox(height: 24),

                      // Route / Directions Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final lat = hotel.latitude;
                            final lng = hotel.longitude;
                            final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
                            try {
                              if (await canLaunchUrlString(url)) {
                                await launchUrlString(url, mode: LaunchMode.externalApplication);
                              }
                            } catch (e) {
                              debugPrint('Could not launch directions: $e');
                            }
                          },
                          icon: const Icon(Icons.directions_rounded, color: Colors.white),
                          label: const Text(
                            'Get Route Directions',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: coral,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: coral),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: textGrey),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textDark,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
