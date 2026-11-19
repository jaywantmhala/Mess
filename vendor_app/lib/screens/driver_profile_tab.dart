// lib/screens/driver_profile_tab.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/driver.dart';
import '../services/driver_auth_service.dart';
import '../services/driver_order_service.dart';
import 'login_screen.dart';

class DriverProfileTab extends StatefulWidget {
  const DriverProfileTab({super.key});

  @override
  State<DriverProfileTab> createState() => _DriverProfileTabState();
}

class _DriverProfileTabState extends State<DriverProfileTab> {
  Driver? _driver;
  List<DriverOrder> _orders = [];
  String _appVersion = 'v1.0.0';
  bool _isLoading = true;

  // Design Tokens matching 100% reference photo
  static const Color _brandOrange  = Color(0xFFF58220);
  static const Color _gradientEnd  = Color(0xFFE65100);
  static const Color _greenSuccess = Color(0xFF00A65A);
  static const Color _bgWarm       = Color(0xFFF6F8FA);
  static const Color _white        = Colors.white;
  static const Color _ink          = Color(0xFF1A1A2E);
  static const Color _greySub      = Color(0xFF8A8FA8);
  static const Color _cardBorder   = Color(0xFFEEEEEE);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final driver = await DriverAuthService.instance.getSavedDriver();
    final orders = await DriverOrderService.instance.fetchOrders();
    String verStr = 'v1.0.0';
    try {
      final info = await PackageInfo.fromPlatform();
      if (info.version.isNotEmpty) {
        verStr = 'v${info.version} (Build ${info.buildNumber})';
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _driver = driver;
        _orders = orders;
        _appVersion = verStr;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Logout', style: TextStyle(fontWeight: FontWeight.w900, color: _ink)),
        content: const Text('Are you sure you want to sign out of your driver account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: _greySub, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B30),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DriverAuthService.instance.updateStatus(isOnline: false);
      await DriverAuthService.instance.logout();
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _bgWarm,
        body: Center(child: CircularProgressIndicator(color: _brandOrange)),
      );
    }

    final driverName  = _driver?.fullName ?? 'jaywant';
    final email       = _driver?.email ?? 'jaywantwtl@gmail.com';
    final phone       = _driver?.phoneNumber ?? '9527243062';
    final vehicleNo   = _driver?.vehicleNumber ?? 'MH-27-BB-1234';
    final isOnline    = _driver?.isOnline ?? false;
    final firstName   = driverName.trim().split(RegExp(r'\s+')).first;

    return Scaffold(
      backgroundColor: _bgWarm,
      body: SafeArea(
        child: RefreshIndicator(
          color: _brandOrange,
          onRefresh: _loadProfile,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
            child: Column(
              children: [
                // ── 1. Top Orange Header Banner + Hero Profile Card ──────────
                _buildHeroHeaderSection(driverName, isOnline),
                const SizedBox(height: 18),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    children: [
                      // ── 2. Contact & Vehicle Details Card ──────────────────
                      _buildContactDetailsCard(email, phone, vehicleNo),
                      const SizedBox(height: 18),

                      // ── 3. Stat Metrics Grid Card (4 Stats) ────────────────
                      _buildStatMetricsGridCard(),
                      const SizedBox(height: 18),

                      // ── 4. Golden Trophy Rewards Banner Card ───────────────
                      _buildRewardsBannerCard(firstName),
                      const SizedBox(height: 18),

                      // ── 5. Account Settings & Menu List Card ───────────────
                      _buildMenuListCard(),
                      const SizedBox(height: 22),

                      // ── 6. Sign Out Button ─────────────────────────────────
                      _buildSignOutButton(),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 1. Top Orange Header Banner + Hero Profile Card ────────────────────────
  Widget _buildHeroHeaderSection(String driverName, bool isOnline) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1. Top Orange Cityscape Gradient Banner
        Container(
          height: 205,
          width: double.infinity,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            gradient: LinearGradient(
              colors: [_brandOrange, _gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.menu_rounded, color: _white, size: 26),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Driver Profile',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: _white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Manage your account and preferences',
                    style: TextStyle(
                      fontSize: 12,
                      color: _white.withOpacity(0.85),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 2. Floating Curved White Hero Profile Card with Organic S-Wave Cutout
        Padding(
          padding: const EdgeInsets.only(top: 76, left: 18, right: 18),
          child: ClipPath(
            clipper: HeaderProfileCardClipper(),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: _white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
              child: Row(
                children: [
                  // Avatar Image with Camera Badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _brandOrange, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(39),
                          child: Image.asset(
                            'assets/images/driver_avatar.png',
                            width: 78,
                            height: 78,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, _, __) => const Icon(
                              Icons.person_rounded,
                              color: _brandOrange,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                      // Orange Camera Badge Button
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: _brandOrange,
                            shape: BoxShape.circle,
                            border: Border.all(color: _white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: _white, size: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // Name, Online Status & Rating Row
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driverName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: _ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),

                        // Online/Offline Pill Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isOnline ? const Color(0xFFE8F8EE) : const Color(0xFFEAEAEA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: isOnline ? _greenSuccess : const Color(0xFF757575),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isOnline ? 'ONLINE' : 'OFFLINE',
                                style: TextStyle(
                                  color: isOnline ? _greenSuccess : const Color(0xFF757575),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Rating & Deliveries Row
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: _brandOrange, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              (_driver?.rating ?? 4.8).toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('|', style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 13)),
                            const SizedBox(width: 8),
                            Text(
                              '${_driver?.totalDeliveries ?? (_orders.isNotEmpty ? _orders.length : 120)} Deliveries',
                              style: const TextStyle(
                                fontSize: 12,
                                color: _greySub,
                                fontWeight: FontWeight.w500,
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
        ),

        // 3. 3D Scooter Delivery Graphic placed ON TOP of the white card
        Positioned(
          right: 12,
          top: 38,
          child: Image.asset(
            'assets/images/driver_profile_scooter.png',
            height: 140,
            fit: BoxFit.contain,
            errorBuilder: (ctx, _, __) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  // ── 2. Contact & Vehicle Details Card ──────────────────────────────────────
  Widget _buildContactDetailsCard(String email, String phone, String vehicleNo) {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.mail_rounded,
            label: 'Email Address',
            value: email,
            iconBg: const Color(0xFFFFF0E6),
            iconColor: _brandOrange,
          ),
          const Divider(height: 1, color: Color(0xFFF0EBE5)),
          _buildInfoRow(
            icon: Icons.phone_rounded,
            label: 'Phone Number',
            value: phone,
            iconBg: const Color(0xFFFFF0E6),
            iconColor: _brandOrange,
          ),
          const Divider(height: 1, color: Color(0xFFF0EBE5)),
          _buildInfoRow(
            icon: Icons.two_wheeler_rounded,
            label: 'Vehicle Registration',
            value: vehicleNo,
            iconBg: const Color(0xFFFFF0E6),
            iconColor: _brandOrange,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconBg,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: _greySub,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. Stat Metrics Grid Card (4 Dynamic Stats) ────────────────────────────
  Widget _buildStatMetricsGridCard() {
    int totalDeliveries = _driver?.totalDeliveries ?? 120;
    if (_orders.isNotEmpty) {
      final completedCount = _orders.where((o) => o.status == 'completed').length;
      if (completedCount > 0) {
        totalDeliveries = completedCount;
      } else if (_orders.isNotEmpty && totalDeliveries == 120) {
        totalDeliveries = _orders.length;
      }
    }

    String completionRate = _driver?.completionRate ?? '98%';
    if (_orders.isNotEmpty) {
      final completedCount = _orders.where((o) => o.status == 'completed').length;
      final rate = (completedCount / _orders.length * 100).toStringAsFixed(0);
      completionRate = '$rate%';
    }

    final String rating = (_driver?.rating ?? 4.8).toStringAsFixed(1);
    final String yearsOnPlatform = _driver?.yearsOnPlatform ?? '2 Yrs';

    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      child: Row(
        children: [
          Expanded(
            child: _buildStatColumn(
              icon: Icons.work_rounded,
              iconBg: const Color(0xFFFFF0E6),
              iconColor: _brandOrange,
              value: '$totalDeliveries',
              label: 'Total Deliveries',
            ),
          ),
          Container(height: 42, width: 1, color: const Color(0xFFF0EBE5)),
          Expanded(
            child: _buildStatColumn(
              icon: Icons.verified_user_rounded,
              iconBg: const Color(0xFFE8F8EE),
              iconColor: _greenSuccess,
              value: completionRate,
              label: 'Completion Rate',
            ),
          ),
          Container(height: 42, width: 1, color: const Color(0xFFF0EBE5)),
          Expanded(
            child: _buildStatColumn(
              icon: Icons.star_rounded,
              iconBg: const Color(0xFFEBF5FF),
              iconColor: const Color(0xFF007AFF),
              value: rating,
              label: 'Customer Rating',
            ),
          ),
          Container(height: 42, width: 1, color: const Color(0xFFF0EBE5)),
          Expanded(
            child: _buildStatColumn(
              icon: Icons.access_time_filled_rounded,
              iconBg: const Color(0xFFF3E8FF),
              iconColor: const Color(0xFF9C27B0),
              value: yearsOnPlatform,
              label: 'On Platform',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: _ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10.5,
            color: _greySub,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── 4. Golden Trophy Rewards Banner Card ───────────────────────────────────
  Widget _buildRewardsBannerCard(String firstName) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_brandOrange, _gradientEnd],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _brandOrange.withOpacity(0.3),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 3D Golden Trophy Graphic on Right
          Positioned(
            right: -10,
            bottom: -25,
            child: Image.asset(
              'assets/images/golden_trophy.png',
              height: 125,
              fit: BoxFit.contain,
              errorBuilder: (ctx, _, __) => const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 80),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Great job, $firstName!',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Keep delivering happiness\nand earn more rewards.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: _white.withOpacity(0.9),
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),

              // White Pill Button "View Rewards →"
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'View Rewards',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: _brandOrange,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded, color: _brandOrange, size: 15),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 5. Account Settings & Menu List Card ───────────────────────────────────
  Widget _buildMenuListCard() {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          _buildMenuRow(
            icon: Icons.headset_mic_rounded,
            iconBg: const Color(0xFFF3E5FF),
            iconColor: const Color(0xFF9C27B0),
            title: 'Help & Support',
            subtitle: 'Contact support & driver assistance',
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFBDBDBD),
              size: 20,
            ),
            onTap: () => _showHelpSupportSheet(context),
          ),
          const Divider(height: 1, color: _cardBorder),
          _buildMenuRow(
            icon: Icons.info_rounded,
            iconBg: const Color(0xFFEBF5FF),
            iconColor: const Color(0xFF007AFF),
            title: 'App Version',
            subtitle: _appVersion,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMenuRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: _greySub,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
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
      debugPrint('Launch URL error: ');
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
                          'Driver Partner Assistance',
                          style: TextStyle(
                            fontSize: 12,
                            color: _greySub,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded, color: _greySub),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Have questions, route issues, or need delivery assistance? Reach out to our dedicated support team.',
                style: TextStyle(fontSize: 13.5, color: _greySub, height: 1.45),
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
                      onTap: () => _launchSupportUrl('https://wa.me/918625018625?text=Hello%20Hungrily%20Driver%20Support'),
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
                    Icon(Icons.location_on_rounded, color: _brandOrange, size: 20),
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
            color: (iconColor ?? _brandOrange).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor ?? _brandOrange, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _greySub,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: onTap != null ? _ink : const Color(0xFF333333),
                  decoration: onTap != null ? TextDecoration.underline : TextDecoration.none,
                  decorationColor: _brandOrange.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
        if (onTap != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: (iconColor ?? _brandOrange).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title.startsWith('WhatsApp')
                      ? 'Chat'
                      : title.startsWith('Call')
                          ? 'Call'
                          : 'Send',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: iconColor ?? _brandOrange,
                  ),
                ),
                const SizedBox(width: 3),
                Icon(
                  Icons.arrow_outward_rounded,
                  size: 12,
                  color: iconColor ?? _brandOrange,
                ),
              ],
            ),
          ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: body,
        ),
      );
    }
    return body;
  }

  // ── 6. Sign Out Button ─────────────────────────────────────────────────────
  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF3B30),
          foregroundColor: _white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _handleLogout,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.logout_rounded, color: _white, size: 20),
            SizedBox(width: 8),
            Text(
              'Sign Out',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Organic S-Wave Curved Clipper for Hero Profile Card
// ─────────────────────────────────────────────────────────────────────────────

class HeaderProfileCardClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final double radius = 28.0;

    // Top left rounded corner
    path.moveTo(0, radius);
    path.quadraticBezierTo(0, 0, radius, 0);

    // Top edge straight until ~48% width
    path.lineTo(size.width * 0.48, 0);

    // Deep organic S-curve scoop dipping down to x=76%, y=64
    path.cubicTo(
      size.width * 0.56, 0,
      size.width * 0.52, 64,
      size.width * 0.76, 64,
    );

    // Curve smoothly back up to top-right (x = 94%, y = 16)
    path.cubicTo(
      size.width * 0.88, 64,
      size.width * 0.94, 16,
      size.width - radius, 16,
    );

    path.quadraticBezierTo(size.width, 16, size.width, 16 + radius);

    // Right edge down
    path.lineTo(size.width, size.height - radius);
    path.quadraticBezierTo(size.width, size.height, size.width - radius, size.height);

    // Bottom edge left
    path.lineTo(radius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - radius);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}
