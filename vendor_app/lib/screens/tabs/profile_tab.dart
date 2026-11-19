// lib/screens/tabs/profile_tab.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/vendor.dart';
import '../../services/auth_service.dart';
import '../../services/hotel_service.dart';
import '../../utils/location_data.dart';
import '../add_hotel_screen.dart';
import '../welcome_screen.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import '../../models/hotel.dart';
import '../vendor_drivers_screen.dart';
import '../bank_details_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  // ── Design tokens (from reference photo) ──────────────────────────────────
  static const Color _bg = Color(0xFFFFF3EC); // warm peach background
  static const Color _orange = Color(0xFFF58220); // brand orange
  static const Color _green = Color(0xFF28A745); // verified green
  static const Color _blue = Color(0xFF4A90D9); // my hotels blue
  static const Color _ink = Color(0xFF1A1A2E); // dark title text
  static const Color _grey = Color(0xFF8A8FA8); // subtitle grey
  static const Color _white = Colors.white;
  static const Color _divider = Color(0xFFF0EBE5); // warm divider

  Vendor? _vendor;
  List<Hotel> _hotels = [];
  int _hotelCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    LocationData.loadFromJson();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final vendor = await AuthService.instance.getSavedVendor();
      final hotels = await HotelService.instance.getHotels();
      if (mounted) {
        setState(() {
          _vendor = vendor;
          _hotels = hotels;
          _hotelCount = hotels.length;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'V';
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.length >= 2
        ? (parts[0][0] + parts[1][0]).toUpperCase()
        : parts[0][0].toUpperCase();
  }

  /// Format createdAt → "04 July 2026"
  String _formatJoinDate(String raw) {
    if (raw.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(raw);
      const months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return raw.split(' ').first;
    }
  }

  /// Days since joining
  int _daysSinceJoin(String raw) {
    if (raw.isEmpty) return 0;
    try {
      final dt = DateTime.parse(raw);
      return DateTime.now().difference(dt).inDays + 1;
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFF3EC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFF58220)),
        ),
      );
    }

    final name = _vendor?.fullName ?? 'Vendor';
    final initials = _getInitials(name);
    // first name only for greeting
    final firstName = name.trim().split(RegExp(r'\s+')).first;
    final joinDate = _vendor?.createdAt ?? '';
    final joinStr = _formatJoinDate(joinDate);
    final days = _daysSinceJoin(joinDate);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── AppBar ─────────────────────────────────────────────────────
            _buildAppBar(context),

            // ── Scrollable body ─────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // ── Hero card ─────────────────────────────────────────
                    _buildHeroCard(initials, firstName),

                    const SizedBox(height: 20),

                    // ── 3 action cards ────────────────────────────────────
                    _buildActionCards(context),

                    const SizedBox(height: 20),

                    // ── Info rows ─────────────────────────────────────────
                    _buildInfoCard(context, joinStr, days),

                    const SizedBox(height: 20),

                    // ── Trust banner ──────────────────────────────────────
                    _buildTrustBanner(),

                    const SizedBox(height: 28),

                    // ── Logout ────────────────────────────────────────────
                    _buildLogoutButton(context),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          // Back button
          TextButton.icon(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.chevron_left_rounded, color: _ink, size: 22),
            label: const Text(
              'Back',
              style: TextStyle(
                color: _ink,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
          ),

          // Title
          const Expanded(
            child: Center(
              child: Text(
                'Partner Profile',
                style: TextStyle(
                  color: _ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),

          // Settings icon
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.settings_outlined, color: _ink, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero card ──────────────────────────────────────────────────────────────
  Widget _buildHeroCard(String initials, String firstName) {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar with verified badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _orange,
                    border: Border.all(color: _white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: _orange.withValues(alpha: 0.30),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: _white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                // Green verified badge
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _green,
                      shape: BoxShape.circle,
                      border: Border.all(color: _white, width: 2),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: _white,
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 16),

            // Text info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Hello, ',
                            style: TextStyle(
                              color: _ink,
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: '$firstName!',
                            style: const TextStyle(
                              color: _orange,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'Verified Partner',
                      style: TextStyle(
                        color: _grey,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Verified pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.verified_rounded, color: _green, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Verified',
                            style: TextStyle(
                              color: _green,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Vendor illustration image
            const SizedBox(width: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/vendor.jpg',
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 90,
                    height: 90,
                    color: const Color(0xFFFFF0E6),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: _orange,
                      size: 44,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Action cards ─────────────────────────────────────────────────────────────
  Widget _buildActionCards(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                iconBg: const Color(0xFFFFF0E6),
                iconColor: _orange,
                icon: Icons.edit_rounded,
                title: 'Edit Account',
                subtitle: 'Update details',
                onTap: () => _showEditProfileModal(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionCard(
                iconBg: const Color(0xFFE8F5E9),
                iconColor: _green,
                icon: Icons.storefront_rounded,
                title: 'Register Mess',
                subtitle: 'Add new mess',
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddHotelScreen()),
                  );
                  _loadProfileData();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                iconBg: const Color(0xFFE3F2FD),
                iconColor: _blue,
                icon: Icons.store_mall_directory_rounded,
                title: 'My Messes',
                subtitle: 'View your messes',
                badge: '$_hotelCount',
                onTap: () => _showMyHotelsSheet(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionCard(
                iconBg: const Color(0xFFE0F7FA),
                iconColor: const Color(0xFF00838F),
                icon: Icons.two_wheeler_rounded,
                title: 'View Drivers',
                subtitle: 'Manage your drivers',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VendorDriversScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Info card with rows ────────────────────────────────────────────────────
  Widget _buildInfoCard(BuildContext context, String joinStr, int days) {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Member Since
          _InfoRow(
            iconBg: const Color(0xFFFFF0E6),
            iconColor: _orange,
            icon: Icons.calendar_month_rounded,
            title: 'Member Since',
            subtitle: joinStr,
            trailing: _OrangePill(label: '$days Days'),
            isFirst: true,
          ),
          Divider(height: 1, color: _divider, indent: 60, endIndent: 16),

          // Location Info Row
          _InfoRow(
            iconBg: const Color(0xFFFFF0E6),
            iconColor: _orange,
            icon: Icons.location_on_rounded,
            title: 'Location & Region',
            subtitle: _vendor != null && _vendor!.state.isNotEmpty
                ? '${_vendor!.taluka.isNotEmpty ? "${_vendor!.taluka}, " : ""}${_vendor!.district.isNotEmpty ? "${_vendor!.district}, " : ""}${_vendor!.state}, ${_vendor!.country}'
                : 'Country: ${_vendor?.country ?? "India"} (Tap to edit)',
            trailing: const Icon(Icons.edit_outlined, color: _orange, size: 20),
            onTap: () => _showEditProfileModal(context),
          ),
          Divider(height: 1, color: _divider, indent: 60, endIndent: 16),

          // Bank Account Details Row
          _InfoRow(
            iconBg: const Color(0xFFFFF8E1),
            iconColor: const Color(0xFFF57F17),
            icon: Icons.account_balance_outlined,
            title: 'Bank Account Details',
            subtitle: 'Manage settlement bank account & IFSC',
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFBDBDBD),
              size: 20,
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BankDetailsScreen()),
            ),
          ),
          Divider(height: 1, color: _divider, indent: 60, endIndent: 16),

          // View Drivers Row
          _InfoRow(
            iconBg: const Color(0xFFE0F7FA),
            iconColor: const Color(0xFF00838F),
            icon: Icons.two_wheeler_rounded,
            title: 'View Delivery Drivers',
            subtitle: 'Manage drivers linked to your account',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F7FA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'View Drivers',
                style: TextStyle(
                  color: Color(0xFF00838F),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VendorDriversScreen()),
            ),
          ),
          Divider(height: 1, color: _divider, indent: 60, endIndent: 16),

          // Account Status
          _InfoRow(
            iconBg: const Color(0xFFE8F5E9),
            iconColor: _green,
            icon: Icons.shield_outlined,
            title: 'Account Status',
            subtitle: 'You are a verified partner',
            trailing: _GreenPill(label: 'Verified Partner'),
          ),
          Divider(height: 1, color: _divider, indent: 60, endIndent: 16),

          // Registered Hotels
          _InfoRow(
            iconBg: const Color(0xFFE3F2FD),
            iconColor: _blue,
            icon: Icons.storefront_rounded,
            title: 'Registered Messes',
            subtitle: 'Total messes you have added',
            trailing: _NumberBadge(number: _hotelCount),
            onTap: () => _showMyHotelsSheet(context),
          ),
          Divider(height: 1, color: _divider, indent: 60, endIndent: 16),

          // Help & Support
          _InfoRow(
            iconBg: const Color(0xFFF3E5FF),
            iconColor: const Color(0xFF9C27B0),
            icon: Icons.headset_mic_rounded,
            title: 'Help & Support',
            subtitle: 'Get help and contact support',
            isLast: true,
            onTap: () => _showHelpSupportSheet(context),
          ),
        ],
      ),
    );
  }

  void _showMyHotelsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Registered Messes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_hotels.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.storefront_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'No messes registered yet.',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _hotels.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final hotel = _hotels[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: _orange.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.storefront_rounded, color: _orange, size: 24),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        hotel.hotelName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Owner: ${hotel.ownerName.isNotEmpty ? hotel.ownerName : "N/A"} • ID #${hotel.id}',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              hotel.hotelAddress,
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F172A),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                icon: const Icon(Icons.qr_code_2_rounded, size: 20),
                                label: const Text('View & Download Tiffin QR Code'),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _showHotelQRCodeDialog(context, hotel);
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showHotelQRCodeDialog(BuildContext context, Hotel hotel) {
    final qrData = 'HOTEL_${hotel.id}_TIFFIN';
    final qrUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=500x500&data=$qrData';
    bool isDownloading = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _orange.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.qr_code_2_rounded, color: _orange, size: 32),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      hotel.hotelName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mess Tiffin Barcode / QR Code (ID: #${hotel.id})',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    
                    // QR Code Image Container
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
                        ],
                      ),
                      child: Image.network(
                        qrUrl,
                        width: 200,
                        height: 200,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const SizedBox(
                            width: 200,
                            height: 200,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox(
                            width: 200,
                            height: 200,
                            child: Center(child: Text('Failed to load QR code.')),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Barcode: $qrData',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 20),

                    // Download / Open Image Action
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: isDownloading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.download_rounded),
                        label: Text(
                          isDownloading ? 'Downloading...' : 'Download / Save QR Code',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: isDownloading
                            ? null
                            : () async {
                                setDialogState(() => isDownloading = true);
                                try {
                                  // 1. Check & Request Gal Gallery Access
                                  final hasAccess = await Gal.hasAccess();
                                  if (!hasAccess) {
                                    final granted = await Gal.requestAccess();
                                    if (!granted) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Gallery permission is required to save QR code. Please allow photos/storage permission in Settings.'),
                                            backgroundColor: Colors.red,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                      return;
                                    }
                                  }

                                  // 2. Fetch QR Code Image Bytes with Fallback URL
                                  Uint8List? imageBytes;
                                  try {
                                    final response = await http.get(Uri.parse(qrUrl)).timeout(const Duration(seconds: 10));
                                    if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
                                      imageBytes = response.bodyBytes;
                                    }
                                  } catch (e) {
                                    debugPrint('Primary QR download error: $e');
                                  }

                                  if (imageBytes == null) {
                                    try {
                                      final fallbackUrl = 'https://quickchart.io/qr?text=$qrData&size=500';
                                      final fallbackRes = await http.get(Uri.parse(fallbackUrl)).timeout(const Duration(seconds: 10));
                                      if (fallbackRes.statusCode == 200 && fallbackRes.bodyBytes.isNotEmpty) {
                                        imageBytes = fallbackRes.bodyBytes;
                                      }
                                    } catch (e) {
                                      debugPrint('Fallback QR download error: $e');
                                    }
                                  }

                                  if (imageBytes == null) {
                                    throw Exception('Unable to download QR code image. Please check your internet connection.');
                                  }

                                  // 3. Write to temporary file and save to Gallery
                                  final tempFile = File('${Directory.systemTemp.path}/qr_${hotel.id}_tiffin.png');
                                  await tempFile.writeAsBytes(imageBytes);

                                  try {
                                    await Gal.putImage(tempFile.path);
                                  } catch (_) {
                                    await Gal.putImageBytes(imageBytes, name: 'qr_${hotel.id}_tiffin');
                                  } finally {
                                    try {
                                      if (await tempFile.exists()) {
                                        await tempFile.delete();
                                      }
                                    } catch (_) {}
                                  }

                                  // 4. Show success snackbar with action to view in gallery
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: const [
                                            Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                                            SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                'Tiffin QR Code downloaded to Gallery successfully!',
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: const Color(0xFF16A34A),
                                        behavior: SnackBarBehavior.floating,
                                        duration: const Duration(seconds: 5),
                                        action: SnackBarAction(
                                          label: 'Open Gallery',
                                          textColor: Colors.white,
                                          onPressed: () {
                                            try {
                                              Gal.open();
                                            } catch (_) {}
                                          },
                                        ),
                                      ),
                                    );
                                  }
                                } on GalException catch (e) {
                                  if (context.mounted) {
                                    String message = 'Gallery error: ${e.type.message}';
                                    if (e.type == GalExceptionType.accessDenied) {
                                      message = 'Gallery permission denied. Please enable photos access in Settings.';
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(message),
                                        backgroundColor: Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Could not save QR code: $e'),
                                        backgroundColor: Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } finally {
                                  setDialogState(() => isDownloading = false);
                                }
                              },
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close', style: TextStyle(color: Colors.grey)),
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

  // ── Trust banner ───────────────────────────────────────────────────────────
  Widget _buildTrustBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFE0C8), width: 1.2),
      ),
      child: Row(
        children: [
          // Shield icon
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8D4),
                  shape: BoxShape.circle,
                ),
              ),
              const Icon(Icons.shield_rounded, color: _orange, size: 36),
              const Positioned(
                top: 12,
                child: Icon(Icons.star_rounded, color: _white, size: 14),
              ),
            ],
          ),
          const SizedBox(width: 14),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Thank you for being a trusted partner!',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Together, let's create amazing experiences for our guests.",
                  style: TextStyle(color: _grey, fontSize: 11.5, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Handshake emoji / icon
          const Text('🤝', style: TextStyle(fontSize: 36)),
        ],
      ),
    );
  }

  // ── Logout button ──────────────────────────────────────────────────────────
  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Sign Out'),
              content: const Text('Are you sure you want to sign out?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel', style: TextStyle(color: _grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: _white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Sign Out'),
                ),
              ],
            ),
          );
          if (confirm == true && context.mounted) {
            final navigator = Navigator.of(context);
            await AuthService.instance.logout();
            navigator.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const WelcomeScreen()),
              (r) => false,
            );
          }
        },
        icon: const Icon(Icons.logout_rounded, color: Color(0xFFE53935)),
        label: const Text(
          'Logout',
          style: TextStyle(
            color: Color(0xFFE53935),
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFFFCDD2), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: const Color(0xFFFFF5F5),
        ),
      ),
    );
  }

  // ── Edit Profile Modal ──────────────────────────────────────────────────────
  void _showEditProfileModal(BuildContext context) async {
    await LocationData.loadFromJson();
    if (_vendor == null) return;

    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: _vendor!.fullName);
    final emailCtrl = TextEditingController(text: _vendor!.email);
    final phoneCtrl = TextEditingController(text: _vendor!.phoneNumber);

    String selectedCountry = _vendor!.country.isNotEmpty
        ? _vendor!.country
        : LocationData.defaultCountry;
    String? selectedState = _vendor!.state.isNotEmpty ? _vendor!.state : null;
    String? selectedDistrict = _vendor!.district.isNotEmpty
        ? _vendor!.district
        : null;
    String? selectedArea;
    final areaCtrl = TextEditingController();
    String? selectedTaluka = _vendor!.taluka.isNotEmpty
        ? _vendor!.taluka
        : null;

    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              decoration: const BoxDecoration(
                color: _white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Edit Vendor Profile',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: _ink,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(modalCtx),
                          icon: const Icon(Icons.close_rounded, color: _grey),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        16,
                        20,
                        MediaQuery.of(context).viewInsets.bottom + 20,
                      ),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Restaurant / Owner Name',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _buildInputBox(
                              icon: Icons.person_outline_rounded,
                              child: TextFormField(
                                controller: nameCtrl,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: _ink,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Enter name',
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'Name is required'
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 14),

                            const Text(
                              'Email Address',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _buildInputBox(
                              icon: Icons.mail_outline_rounded,
                              child: TextFormField(
                                controller: emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: _ink,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Enter email',
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty)
                                    return 'Email is required';
                                  if (!RegExp(
                                    r'^[^@]+@[^@]+\.[^@]+',
                                  ).hasMatch(v))
                                    return 'Invalid email';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 14),

                            const Text(
                              'Phone Number',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _buildInputBox(
                              icon: Icons.phone_outlined,
                              child: TextFormField(
                                controller: phoneCtrl,
                                keyboardType: TextInputType.phone,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: _ink,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Enter phone number',
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            const Text(
''), if (false) Container(child: Container(
                            ),
                          ),
                          const SizedBox(height: 6),
                          // ── Quick Location Search Banner ────────────────────────────
                          GestureDetector(
                            onTap: () async {
                              final result = await _showUnifiedLocationSearchModal(context);
                              if (result != null) {
                                setModalState(() {
                                  if (result['state'] != null && result['state']!.isNotEmpty) {
                                    selectedState = result['state'];
                                  }
                                  if (result['district'] != null && result['district']!.isNotEmpty) {
                                    selectedDistrict = result['district'];
                                  }
                                  if (result['taluka'] != null && result['taluka']!.isNotEmpty) {
                                    selectedTaluka = result['taluka'];
                                  }
                                  if (result['area'] != null && result['area']!.isNotEmpty) {
                                    selectedArea = result['area'];
                                    areaCtrl.text = result['area']!;
                                  }
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: _orange.withOpacity(0.35), width: 1.2),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.search_rounded, color: _orange, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Quick Search (Area / Taluka / District)...',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange.shade800,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _orange,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'SEARCH',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          const Text(
                            'Country',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildSearchableSelectContainer(
                            icon: Icons.public_rounded,
                            value: selectedCountry,
                            hintText: 'Select Country',
                            onTap: () async {
                              final picked = await _showSearchPicker(
                                context: context,
                                title: 'Select Country',
                                items: LocationData.countries,
                                selectedItem: selectedCountry,
                              );
                              if (picked != null) {
                                setModalState(() {
                                  selectedCountry = picked;
                                  selectedState = null;
                                  selectedDistrict = null;
                                  selectedTaluka = null;
                                  selectedArea = null;
                                  areaCtrl.clear();
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 14),

                          const Text(
                            'State',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildSearchableSelectContainer(
                            icon: Icons.map_rounded,
                            value: selectedState,
                            hintText: 'Select State',
                            onTap: () async {
                              final states = LocationData.getStates(selectedCountry);
                              final picked = await _showSearchPicker(
                                context: context,
                                title: 'Select State',
                                items: states,
                                selectedItem: selectedState,
                              );
                              if (picked != null) {
                                setModalState(() {
                                  selectedState = picked;
                                  selectedDistrict = null;
                                  selectedTaluka = null;
                                  selectedArea = null;
                                  areaCtrl.clear();
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 14),

                          const Text(
                            'District',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildSearchableSelectContainer(
                            icon: Icons.location_city_rounded,
                            value: selectedDistrict,
                            hintText: selectedState == null ? 'Select State First' : 'Select District',
                            enabled: selectedState != null,
                            onTap: () async {
                              final districts = LocationData.getDistricts(selectedState!);
                              final picked = await _showSearchPicker(
                                context: context,
                                title: 'Select District ($selectedState)',
                                items: districts,
                                selectedItem: selectedDistrict,
                              );
                              if (picked != null) {
                                setModalState(() {
                                  selectedDistrict = picked;
                                  selectedTaluka = null;
                                  selectedArea = null;
                                  areaCtrl.clear();
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 14),

                          const Text(
                            'Taluka',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildSearchableSelectContainer(
                            icon: Icons.holiday_village_rounded,
                            value: selectedTaluka,
                            hintText: selectedDistrict == null ? 'Select District First' : 'Select Taluka',
                            enabled: selectedDistrict != null,
                            onTap: () async {
                              final talukas = LocationData.getTalukas(selectedDistrict!);
                              final picked = await _showSearchPicker(
                                context: context,
                                title: 'Select Taluka ($selectedDistrict)',
                                items: talukas,
                                selectedItem: selectedTaluka,
                              );
                              if (picked != null) {
                                setModalState(() {
                                  selectedTaluka = picked;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 14),

                          // Area / Locality Selector with Search Button & Direct Typing
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Area / Locality',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: _ink,
                                    ),
                                  ),
                                  if (selectedDistrict != null)
                                    GestureDetector(
                                      onTap: () async {
                                        final areas = LocationData.getAreas(selectedDistrict!);
                                        final picked = await _showSearchPicker(
                                          context: context,
                                          title: 'Select Area ($selectedDistrict)',
                                          items: areas,
                                          selectedItem: areaCtrl.text.isNotEmpty ? areaCtrl.text : selectedArea,
                                          allowCustom: true,
                                          hintText: 'Search or enter area name...',
                                        );
                                        if (picked != null) {
                                          setModalState(() {
                                            selectedArea = picked;
                                            areaCtrl.text = picked;
                                          });
                                        }
                                      },
                                      child: Row(
                                        children: const [
                                          Icon(Icons.list_alt_rounded, size: 14, color: _orange),
                                          SizedBox(width: 4),
                                          Text(
                                            'Browse Areas',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: _orange,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              _buildInputBox(
                                icon: Icons.near_me_outlined,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: areaCtrl,
                                        style: const TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: _ink,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: selectedDistrict == null
                                              ? 'Select District first'
                                              : 'Type or search Area (e.g. Kothrud, Hinjawadi...)',
                                          hintStyle: const TextStyle(color: Color(0xFFA0A5BA), fontSize: 13, fontWeight: FontWeight.w400),
                                          border: InputBorder.none,
                                        ),
                                        onChanged: (val) {
                                          selectedArea = val;
                                        },
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.search_rounded, color: _orange),
                                      tooltip: 'Search & Pick Area',
                                      onPressed: selectedDistrict == null
                                          ? null
                                          : () async {
                                              final areas = LocationData.getAreas(selectedDistrict!);
                                              final picked = await _showSearchPicker(
                                                context: context,
                                                title: 'Select Area ($selectedDistrict)',
                                                items: areas,
                                                selectedItem: areaCtrl.text.isNotEmpty ? areaCtrl.text : selectedArea,
                                                allowCustom: true,
                                                hintText: 'Search or enter area...',
                                              );
                                              if (picked != null) {
                                                setModalState(() {
                                                  selectedArea = picked;
                                                  areaCtrl.text = picked;
                                                });
                                              }
                                            },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (false) ...[
                          const Text(
                            'Country (Legacy)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _buildModalDropdown<String>(
                              icon: Icons.public_rounded,
                              value: selectedCountry,
                              hintText: 'Select Country',
                              items: LocationData.countries,
                              onChanged: (val) {
                                if (val != null && val != selectedCountry) {
                                  setModalState(() {
                                    selectedCountry = val;
                                    selectedState = null;
                                    selectedDistrict = null;
                                    selectedTaluka = null;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 14),

                            const Text(
                              'State',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _buildModalDropdown<String>(
                              icon: Icons.map_rounded,
                              value: selectedState,
                              hintText: 'Select State',
                              items: LocationData.getStates(selectedCountry),
                              onChanged: (val) {
                                if (val != selectedState) {
                                  setModalState(() {
                                    selectedState = val;
                                    selectedDistrict = null;
                                    selectedTaluka = null;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 14),

                            const Text(
                              'District',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _buildModalDropdown<String>(
                              icon: Icons.location_city_rounded,
                              value: selectedDistrict,
                              hintText: selectedState == null
                                  ? 'Select State First'
                                  : 'Select District',
                              enabled: selectedState != null,
                              items: selectedState != null
                                  ? LocationData.getDistricts(selectedState!)
                                  : [],
                              onChanged: (val) {
                                if (val != selectedDistrict) {
                                  setModalState(() {
                                    selectedDistrict = val;
                                    selectedTaluka = null;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 14),

                            const Text(
                              'Taluka',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _buildModalDropdown<String>(
                              icon: Icons.holiday_village_rounded,
                              value: selectedTaluka,
                              hintText: selectedDistrict == null
                                  ? 'Select District First'
                                  : 'Select Taluka',
                              enabled: selectedDistrict != null,
                              items: selectedDistrict != null
                                  ? LocationData.getTalukas(selectedDistrict!)
                                  : [],
                              onChanged: (val) {
                                setModalState(() {
                                  selectedTaluka = val;
                                });
                              },
                            ),
                          ],
                          const SizedBox(height: 24),

                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _orange,
                                  foregroundColor: _white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 2,
                                ),
                                onPressed: isSubmitting
                                    ? null
                                    : () async {
                                        if (!formKey.currentState!.validate())
                                          return;
                                        if (selectedState == null ||
                                            selectedState!.isEmpty) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Please select your State.',
                                              ),
                                            ),
                                          );
                                          return;
                                        }
                                        if (selectedDistrict == null ||
                                            selectedDistrict!.isEmpty) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Please select your District.',
                                              ),
                                            ),
                                          );
                                          return;
                                        }
                                        if (selectedTaluka == null ||
                                            selectedTaluka!.isEmpty) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Please select your Taluka.',
                                              ),
                                            ),
                                          );
                                          return;
                                        }

                                        final messenger = ScaffoldMessenger.of(
                                          context,
                                        );

                                        setModalState(
                                          () => isSubmitting = true,
                                        );

                                        final res = await AuthService.instance
                                            .updateProfile(
                                              fullName: nameCtrl.text,
                                              email: emailCtrl.text,
                                              phoneNumber: phoneCtrl.text,
                                              country: selectedCountry,
                                              state: selectedState!,
                                              district: selectedDistrict!,
                                              taluka: selectedTaluka!,
                                            );

                                        if (modalCtx.mounted)
                                          Navigator.pop(modalCtx);

                                        if (res.success && mounted) {
                                          _loadProfileData();
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text(res.message),
                                              backgroundColor:
                                                  Colors.green.shade600,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                child: isSubmitting
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          color: _white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Text(
                                        'Save Changes',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
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
            );
          },
        );
      },
    );
  }

  // ── Help & Support Modal Sheet ──────────────────────────────────────────────
  static Future<void> _launchSupportUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Launch URL error: $e');
    }
  }

  void _showHelpSupportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF3E5FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.headset_mic_rounded,
                      color: Color(0xFF9C27B0),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Help & Support',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: _ink,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Partner Support & Assistance',
                          style: TextStyle(
                            fontSize: 12,
                            color: _grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded, color: _grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Have questions, feedback, or need assistance with your partner account? Reach out to our dedicated support team.',
                style: TextStyle(fontSize: 13.5, color: _grey, height: 1.45),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFFFEDD5),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  children: [
                    _buildSupportInfoTile(
                      icon: Icons.email_rounded,
                      title: 'Email Support',
                      value: 'info@hungrilyfoods.com',
                      onTap: () => _launchSupportUrl('mailto:info@hungrilyfoods.com'),
                    ),
                    const Divider(height: 20, color: Color(0xFFFFEDD5)),
                    _buildSupportInfoTile(
                      icon: Icons.phone_rounded,
                      title: 'Call Support 1',
                      value: '02269620545',
                      onTap: () => _launchSupportUrl('tel:02269620545'),
                    ),
                    const Divider(height: 20, color: Color(0xFFFFEDD5)),
                    _buildSupportInfoTile(
                      icon: Icons.phone_in_talk_rounded,
                      title: 'Call Support 2',
                      value: '02269710877',
                      onTap: () => _launchSupportUrl('tel:02269710877'),
                    ),
                    const Divider(height: 20, color: Color(0xFFFFEDD5)),
                    _buildSupportInfoTile(
                      icon: Icons.chat_rounded,
                      iconColor: const Color(0xFF25D366),
                      title: 'WhatsApp Support',
                      value: '8625018625',
                      onTap: () => _launchSupportUrl('https://wa.me/918625018625?text=Hello%20Hungrily%20Partner%20Support'),
                    ),
                    const Divider(height: 20, color: Color(0xFFFFEDD5)),
                    _buildSupportInfoTile(
                      icon: Icons.access_time_filled_rounded,
                      title: 'Support Hours',
                      value: 'Mon – Sat: 7:00 AM – 10:00 PM',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Office Address',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.location_on_rounded, color: _orange, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Nagapur, Ahilya Nagar, Maharashtra, India',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: _ink,
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
  }

  Widget _buildSupportInfoTile({
    required IconData icon,
    required String title,
    required String value,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    final body = Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: (iconColor ?? _orange).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor ?? _orange, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: _grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
            ],
          ),
        ),
        if (onTap != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: (iconColor ?? _orange).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  icon == Icons.chat_rounded ? "Chat" : (icon == Icons.email_rounded ? "Email" : "Call"),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: iconColor ?? _orange,
                  ),
                ),
                const SizedBox(width: 3),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 11,
                  color: iconColor ?? _orange,
                ),
              ],
            ),
          ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: body,
        ),
      );
    }
    return body;
  }

  Widget _buildInputBox({required IconData icon, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0E6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _orange, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildSearchableSelectContainer({
    required IconData icon,
    required String? value,
    required String hintText,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    final bool hasVal = value != null && value.trim().isNotEmpty;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: enabled ? _white : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasVal ? _orange.withOpacity(0.5) : const Color(0xFFE5E7EB),
            width: 1.2,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: enabled ? const Color(0xFFFFF0E6) : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: enabled ? _orange : _grey, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasVal ? value! : hintText,
                style: TextStyle(
                  color: hasVal ? _ink : const Color(0xFFA0A5BA),
                  fontSize: 14.5,
                  fontWeight: hasVal ? FontWeight.w700 : FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.search_rounded,
              color: enabled ? _orange : const Color(0xFFA0A5BA),
              size: 20,
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Future<String?> _showSearchPicker({
    required BuildContext context,
    required String title,
    required List<String> items,
    String? selectedItem,
    bool allowCustom = false,
    String hintText = 'Search...',
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String filterQuery = '';
        final searchCtrl = TextEditingController();

        return StatefulBuilder(
          builder: (context, setPickerState) {
            final keyboardPad = MediaQuery.of(context).viewInsets.bottom;
            final filtered = items.where((item) {
              return item.toLowerCase().contains(filterQuery.toLowerCase().trim());
            }).toList();

            final bool showCustomOption = allowCustom &&
                filterQuery.trim().isNotEmpty &&
                !items.any((i) => i.toLowerCase() == filterQuery.trim().toLowerCase());

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              margin: EdgeInsets.only(bottom: keyboardPad),
              decoration: const BoxDecoration(
                color: _white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: _grey),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                    child: TextField(
                      controller: searchCtrl,
                      autofocus: items.length > 6,
                      decoration: InputDecoration(
                        hintText: hintText,
                        prefixIcon: const Icon(Icons.search_rounded, color: _orange, size: 22),
                        suffixIcon: filterQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  setPickerState(() {
                                    searchCtrl.clear();
                                    filterQuery = '';
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _orange, width: 1.5),
                        ),
                      ),
                      onChanged: (val) {
                        setPickerState(() => filterQuery = val);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      itemCount: filtered.length + (showCustomOption ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (showCustomOption && index == 0) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _orange.withOpacity(0.5)),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.add_circle_outline_rounded, color: _orange),
                              title: Text(
                                'Use "${filterQuery.trim()}"',
                                style: const TextStyle(fontWeight: FontWeight.w700, color: _orange),
                              ),
                              subtitle: const Text('Tap to set as custom area', style: TextStyle(fontSize: 11, color: _grey)),
                              onTap: () => Navigator.pop(ctx, filterQuery.trim()),
                            ),
                          );
                        }

                        final itemIndex = showCustomOption ? index - 1 : index;
                        final item = filtered[itemIndex];
                        final isSelected = item == selectedItem;

                        return ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          tileColor: isSelected ? _orange.withOpacity(0.08) : null,
                          title: Text(
                            item,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                              color: isSelected ? _orange : _ink,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_rounded, color: _orange, size: 20)
                              : null,
                          onTap: () => Navigator.pop(ctx, item),
                        );
                      },
                    ),
                  ),
                  if (filtered.isEmpty && !showCustomOption)
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: Text(
                          'No matching items found for "$filterQuery"',
                          style: const TextStyle(color: _grey, fontSize: 13),
                        ),
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

  Future<Map<String, String>?> _showUnifiedLocationSearchModal(BuildContext context) {
    return showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String query = '';
        final searchCtrl = TextEditingController();

        return StatefulBuilder(
          builder: (context, setModalState) {
            final keyboardPad = MediaQuery.of(context).viewInsets.bottom;
            final results = query.trim().length >= 2
                ? LocationData.searchAll(query.trim())
                : <Map<String, String>>[];

            return Container(
              height: MediaQuery.of(context).size.height * 0.82,
              margin: EdgeInsets.only(bottom: keyboardPad),
              decoration: const BoxDecoration(
                color: _white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Search Any Maharashtra Location',
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: _grey),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                    child: TextField(
                      controller: searchCtrl,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'e.g. Kothrud, Hinjawadi, Vashi, Virar, Haveli...',
                        prefixIcon: const Icon(Icons.search_rounded, color: _orange, size: 22),
                        suffixIcon: query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  setModalState(() {
                                    searchCtrl.clear();
                                    query = '';
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _orange, width: 1.5),
                        ),
                      ),
                      onChanged: (val) {
                        setModalState(() => query = val);
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  Expanded(
                    child: query.trim().length < 2
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.travel_explore_rounded, size: 48, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Type at least 2 characters to search across\nall Areas, Talukas, and Districts in Maharashtra',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : results.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Text(
                                    'No results found for "$query"',
                                    style: const TextStyle(color: _grey, fontSize: 14),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                itemCount: results.length,
                                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
                                itemBuilder: (context, index) {
                                  final item = results[index];
                                  final type = item['type'] ?? '';
                                  final name = item['name'] ?? '';
                                  final district = item['district'] ?? '';
                                  final taluka = item['taluka'] ?? '';
                                  final region = item['region'] ?? '';

                                  Color badgeBg = Colors.grey.shade100;
                                  Color badgeText = Colors.grey.shade800;
                                  IconData itemIcon = Icons.location_on_outlined;

                                  if (type == 'area') {
                                    badgeBg = const Color(0xFFFFF3E0);
                                    badgeText = const Color(0xFFE65100);
                                    itemIcon = Icons.place_outlined;
                                  } else if (type == 'taluka') {
                                    badgeBg = const Color(0xFFE8F5E9);
                                    badgeText = const Color(0xFF2E7D32);
                                    itemIcon = Icons.holiday_village_outlined;
                                  } else if (type == 'district') {
                                    badgeBg = const Color(0xFFE3F2FD);
                                    badgeText = const Color(0xFF1565C0);
                                    itemIcon = Icons.location_city_outlined;
                                  }

                                  String subtitle = 'District: $district';
                                  if (taluka.isNotEmpty && taluka != name) {
                                    subtitle += ', Taluka: $taluka';
                                  }
                                  if (region.isNotEmpty) {
                                    subtitle += ' ($region)';
                                  }

                                  return ListTile(
                                    leading: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: badgeBg,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(itemIcon, color: badgeText, size: 20),
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14.5,
                                              color: _ink,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: badgeBg,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            type.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: badgeText,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      subtitle,
                                      style: const TextStyle(fontSize: 12, color: _grey),
                                    ),
                                    onTap: () {
                                      Navigator.pop(ctx, {
                                        'state': 'Maharashtra',
                                        'district': district,
                                        'taluka': taluka.isNotEmpty ? taluka : (type == 'taluka' ? name : ''),
                                        'area': type == 'area' ? name : '',
                                      });
                                    },
                                  );
                                },
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

  Widget _buildModalDropdown<T>({
    required IconData icon,
    required T? value,
    required String hintText,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? _white : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: enabled
                  ? const Color(0xFFFFF0E6)
                  : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: enabled ? _orange : _grey, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: (value != null && items.contains(value)) ? value : null,
                hint: Text(
                  hintText,
                  style: const TextStyle(
                    color: Color(0xFFA0A5BA),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                isExpanded: true,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: enabled ? _orange : const Color(0xFFA0A5BA),
                ),
                dropdownColor: _white,
                borderRadius: BorderRadius.circular(16),
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
                items: items.map((T item) {
                  return DropdownMenuItem<T>(
                    value: item,
                    child: Text(
                      item.toString(),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: enabled ? onChanged : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action Card ───────────────────────────────────────────────────────────────
class _ActionCard extends StatelessWidget {
  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  const _ActionCard({
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFBDBDBD),
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF1A1A2E),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ),
                if (badge != null) ...[
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A90D9),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF8A8FA8),
                fontSize: 10.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Info Row ─────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.isFirst = false,
    this.isLast = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(20) : Radius.zero,
        bottom: isLast ? const Radius.circular(20) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon circle
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            // Texts
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF1A1A2E),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF8A8FA8),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            // Trailing widget
            ?trailing,
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFBDBDBD),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Orange pill badge ─────────────────────────────────────────────────────────
class _OrangePill extends StatelessWidget {
  final String label;
  const _OrangePill({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0E6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF58220).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_today_rounded,
            color: Color(0xFFF58220),
            size: 11,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFF58220),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Green pill badge ──────────────────────────────────────────────────────────
class _GreenPill extends StatelessWidget {
  final String label;
  const _GreenPill({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF28A745).withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF28A745),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Number badge ───────────────────────────────────────────────────────────────
class _NumberBadge extends StatelessWidget {
  final int number;
  const _NumberBadge({required this.number});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: const Color(0xFF4A90D9),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$number',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
