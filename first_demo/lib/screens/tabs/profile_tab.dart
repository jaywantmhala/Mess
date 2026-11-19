// lib/screens/tabs/profile_tab.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../models/customer.dart';
import '../your_orders_screen.dart';
import '../welcome_screen.dart';
import '../customer_subscription_screen.dart';
import '../select_address_screen.dart';
import '../home_shell.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  // ── Design Tokens matching reference photo 100% ────────────────────────────
  static const Color _brandOrange = Color(0xFFF58220);
  static const Color _gradientEnd = Color(0xFFE65100);
  static const Color _bgWarm = Color(0xFFF6F8FA);
  static const Color _white = Colors.white;
  static const Color _ink = Color(0xFF1A1A2E);
  static const Color _greySub = Color(0xFF6B7280);
  static const Color _fieldBorder = Color(0xFFF3F4F6);
  static const Color _iconBoxBg = Color(0xFFFFF0E6);

  Customer? _customer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final customer = await AuthService.instance.getSavedCustomer();
      if (mounted)
        setState(() {
          _customer = customer;
          _isLoading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getInitial(String name) {
    if (name.isEmpty) return 'J';
    return name.trim()[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isWide = mq.size.width > 600;

    final name = _customer?.fullName ?? 'Jaywant';
    final email = _customer?.email ?? 'jaywant61495@gmail.com';
    final initial = _getInitial(name);

    return Scaffold(
      backgroundColor: _bgWarm,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandOrange))
          : SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isWide ? 540 : double.infinity,
                  ),
                  child: Stack(
                    children: [
                      // ── 1. Top Orange Header Banner with Custom Organic S-Wave Curve ───
                      ClipPath(
                        clipper: HeaderCurveClipper(),
                        child: Container(
                          height: 175,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_brandOrange, _gradientEnd],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),

                      // ── 2. Top App Bar (Back | Profile | Settings) ───────────────────
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Back Button
                              GestureDetector(
                                onTap: () {
                                  final homeShell = context
                                      .findAncestorStateOfType<
                                        HomeShellState
                                      >();
                                  if (homeShell != null) {
                                    homeShell.selectTab(0);
                                  } else if (Navigator.canPop(context)) {
                                    Navigator.pop(context);
                                  }
                                },
                                child: Row(
                                  children: [
                                    Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: _white.withOpacity(0.22),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.chevron_left_rounded,
                                        color: _white,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Back',
                                      style: TextStyle(
                                        color: _white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Center Title: Profile
                              const Text(
                                'Profile',
                                style: TextStyle(
                                  color: _white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3,
                                ),
                              ),

                              // Settings Gear Icon Button
                              GestureDetector(
                                onTap: () {},
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: _white.withOpacity(0.22),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.settings_outlined,
                                    color: _white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── 3. Profile Content Stack ─────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 105,
                          left: 14,
                          right: 14,
                          bottom: 16,
                        ),
                        child: Column(
                          children: [
                            // Avatar & User Details Block
                            Column(
                              children: [
                                // Circular Orange Avatar with Camera Badge
                                Stack(
                                  children: [
                                    Container(
                                      width: 95,
                                      height: 95,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _brandOrange,
                                        border: Border.all(
                                          color: _white,
                                          width: 3.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.12,
                                            ),
                                            blurRadius: 12,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          initial,
                                          style: const TextStyle(
                                            fontSize: 42,
                                            fontWeight: FontWeight.w900,
                                            color: _white,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Bottom Right Camera Badge
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _white,
                                          border: Border.all(
                                            color: const Color(0xFFF3F4F6),
                                            width: 1.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.08,
                                              ),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt_rounded,
                                          color: _brandOrange,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Name
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: _ink,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                const SizedBox(height: 2),

                                // Email
                                Text(
                                  email,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: _greySub,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // ── 4. Feature Cards Grid (Edit Profile & Address Book) ───────
                            Row(
                              children: [
                                // 1. Edit Profile
                                Expanded(
                                  child: _buildTopFeatureCard(
                                    icon: Icons.edit_rounded,
                                    title: 'Edit Profile',
                                    subtitle: 'Update your info',
                                    onTap: () {},
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // 2. Address Book
                                Expanded(
                                  child: _buildTopFeatureCard(
                                    icon: Icons.location_on_rounded,
                                    title: 'Address Book',
                                    subtitle: 'Saved addresses',
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const SelectAddressScreen(),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // ── 5. Menu Options Card Container ────────────────────────────
                            Container(
                              decoration: BoxDecoration(
                                color: _white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _fieldBorder,
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Row 1: Order History
                                  _buildMenuOptionRow(
                                    icon: Icons.history_rounded,
                                    title: 'Order History',
                                    subtitle: 'View your past orders',
                                    onTap: () {
                                      final homeShell = context
                                          .findAncestorStateOfType<
                                            HomeShellState
                                          >();
                                      if (homeShell != null) {
                                        homeShell.selectTab(1);
                                      } else {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const YourOrdersScreen(),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  const Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: _fieldBorder,
                                  ),

                                  // Row 2: Manage Subscriptions
                                  _buildMenuOptionRow(
                                    icon: Icons.calendar_month_rounded,
                                    title: 'Manage Subscriptions',
                                    subtitle: 'View and manage your plans',
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const CustomerSubscriptionScreen(),
                                      ),
                                    ),
                                  ),
                                  const Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: _fieldBorder,
                                  ),

                                  // Row 3: Help & Support / Contact Us
                                  _buildMenuOptionRow(
                                    icon: Icons.headset_mic_rounded,
                                    title: 'Help & Support',
                                    subtitle:
                                        'Contact support & get assistance',
                                    onTap: () => _showContactUsSheet(context),
                                  ),
                                  const Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: _fieldBorder,
                                  ),

                                  // Row 4: Privacy & Security
                                  _buildMenuOptionRow(
                                    icon: Icons.shield_outlined,
                                    title: 'Privacy & Security',
                                    subtitle: 'Manage your privacy settings',
                                    onTap: () =>
                                        _showPrivacyPolicySheet(context),
                                  ),
                                  const Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: _fieldBorder,
                                  ),

                                  // Row 5: Delete Account
                                  _buildMenuOptionRow(
                                    icon: Icons.delete_outline_rounded,
                                    title: 'Delete Account',
                                    subtitle:
                                        'Permanently delete your account & data',
                                    isDestructive: true,
                                    onTap: () =>
                                        _showDeleteAccountDialog(context),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // ── 5b. Policies & Terms Section Card ───────────────────────────
                            Container(
                              decoration: BoxDecoration(
                                color: _white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _fieldBorder,
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      16,
                                      14,
                                      16,
                                      10,
                                    ),
                                    child: Text(
                                      'Policies & Information',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: _ink,
                                      ),
                                    ),
                                  ),
                                  const Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: _fieldBorder,
                                  ),

                                  // 1. Terms and Conditions
                                  _buildBulletPolicyRow(
                                    title: 'Terms and Conditions',
                                    onTap: () =>
                                        _showTermsAndConditionsSheet(context),
                                  ),
                                  const Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: _fieldBorder,
                                  ),

                                  // 2. Privacy Policy
                                  _buildBulletPolicyRow(
                                    title: 'Privacy Policy',
                                    onTap: () =>
                                        _showPrivacyPolicySheet(context),
                                  ),
                                  const Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: _fieldBorder,
                                  ),

                                  // 3. Shipping Policy
                                  _buildBulletPolicyRow(
                                    title: 'Shipping Policy',
                                    onTap: () =>
                                        _showShippingPolicySheet(context),
                                  ),
                                  const Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: _fieldBorder,
                                  ),

                                  // 4. Contact Us
                                  _buildBulletPolicyRow(
                                    title: 'Contact Us',
                                    onTap: () => _showContactUsSheet(context),
                                  ),
                                  const Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: _fieldBorder,
                                  ),

                                  // 5. Cancellation and Refunds
                                  _buildBulletPolicyRow(
                                    title: 'Cancellation and Refunds',
                                    onTap: () =>
                                        _showCancellationAndRefundsSheet(
                                          context,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // ── 6. Bottom "Thanks for being with us!" Banner & Logout ───────
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF5F0),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(0xFFFFE8DD),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Left Food Bag Icon / Graphic
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        '🛍️',
                                        style: TextStyle(fontSize: 20),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: const [
                                        Text(
                                          'Thanks for being with us!',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: _ink,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Enjoy delicious food every day.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: _greySub,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Logout Button
                                  GestureDetector(
                                    onTap: () => _showLogoutDialog(context),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _brandOrange,
                                          width: 1.2,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(
                                            Icons.logout_rounded,
                                            color: _brandOrange,
                                            size: 15,
                                          ),
                                          SizedBox(width: 5),
                                          Text(
                                            'Logout',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w900,
                                              color: _brandOrange,
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
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // ── Helper: Top Feature Cards ──────────────────────────────────────────────
  Widget _buildTopFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _fieldBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: _iconBoxBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: _brandOrange, size: 22),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: _greySub,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Positioned(
              top: 14,
              right: 2,
              child: Icon(
                Icons.chevron_right_rounded,
                color: _brandOrange,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helper: Menu Row ───────────────────────────────────────────────────────
  Widget _buildMenuOptionRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final iconColor = isDestructive ? const Color(0xFFEF4444) : _brandOrange;
    final iconBg = isDestructive ? const Color(0xFFFEE2E2) : _iconBoxBg;
    final textColor = isDestructive ? const Color(0xFFEF4444) : _ink;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: textColor,
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
            Icon(
              Icons.chevron_right_rounded,
              color: isDestructive
                  ? const Color(0xFFEF4444)
                  : const Color(0xFFA0A5BA),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ── Helper: Delete Account Dialog ──────────────────────────────────────────
  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: const [
            Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFEF4444),
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              'Delete Account?',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A2E),
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete your account? This action is permanent and cannot be undone. All your profile data and saved subscriptions will be removed.',
          style: TextStyle(fontSize: 13.5, color: _greySub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: _greySub, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: _white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete Account',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final navigator = Navigator.of(context);
      await AuthService.instance.deleteAccount();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Your account has been deleted.'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (r) => false,
      );
    }
  }

  // ── Helper: Logout Dialog ──────────────────────────────────────────────────
  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Sign Out',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: _greySub)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _brandOrange,
              foregroundColor: _white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
  }

  // ── Helper: Bulleted Policy Row ────────────────────────────────────────────
  Widget _buildBulletPolicyRow({
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF9CA3AF),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                  letterSpacing: -0.1,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFA0A5BA),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ── Helper: Generic Policy Bottom Sheet Presenter ─────────────────────────
  void _showPolicyBottomSheet({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            // Top Drag handle
            Container(
              width: 40,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 14),
            // Header Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: _iconBoxBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: _brandOrange, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _ink,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded, color: _greySub),
                  ),
                ],
              ),
            ),
            const Divider(height: 20, thickness: 1, color: _fieldBorder),
            // Body Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 1. Terms & Conditions Sheet ───────────────────────────────────────────
  void _showTermsAndConditionsSheet(BuildContext context) {
    _showPolicyBottomSheet(
      context: context,
      title: 'Terms and Conditions',
      icon: Icons.article_outlined,
      children: const [
        Text(
          'Welcome to Hungrily Foods! By accessing or using our mobile application, services, and subscription plans, you agree to be bound by the following terms:',
          style: TextStyle(fontSize: 13.5, color: _greySub, height: 1.45),
        ),
        SizedBox(height: 14),
        _PolicySectionHeader(title: '1. User Account & Security'),
        _PolicyTextParagraph(
          text:
              'You are responsible for maintaining the confidentiality of your account credentials. You must immediately notify us of any unauthorized use of your account.',
        ),
        SizedBox(height: 12),
        _PolicySectionHeader(title: '2. Subscription & Orders'),
        _PolicyTextParagraph(
          text:
              'Subscription plans are location-based and subject to active radius constraints (up to 5 km). Daily meal deliveries will be scheduled according to selected time slots.',
        ),
        SizedBox(height: 12),
        _PolicySectionHeader(title: '3. Pricing & Payments'),
        _PolicyTextParagraph(
          text:
              'All prices are inclusive of applicable taxes unless stated otherwise. Payments can be made via UPI, Razorpay, Cashfree, or in-app Wallet.',
        ),
        SizedBox(height: 12),
        _PolicySectionHeader(title: '4. Service Modifications'),
        _PolicyTextParagraph(
          text:
              'We reserve the right to modify or discontinue any part of our service or subscription offerings at any time with prior notice to active subscribers.',
        ),
      ],
    );
  }

  // ── 2. Privacy Policy Sheet ────────────────────────────────────────────────
  void _showPrivacyPolicySheet(BuildContext context) {
    _showPolicyBottomSheet(
      context: context,
      title: 'Privacy Policy',
      icon: Icons.shield_outlined,
      children: const [
        Text(
          'Your privacy is important to us. This Privacy Policy explains how Hungrily Foods collects, uses, and safeguards your personal information.',
          style: TextStyle(fontSize: 13.5, color: _greySub, height: 1.45),
        ),
        SizedBox(height: 14),
        _PolicySectionHeader(title: 'Information We Collect'),
        _PolicyTextParagraph(
          text:
              '• Account Details: Name, email address, mobile number.\n• Location Data: Precise GPS coordinates and saved delivery addresses to calculate serviceability (within 5km).\n• Order History: Subscription choices, order details, and payment transaction IDs.',
        ),
        SizedBox(height: 12),
        _PolicySectionHeader(title: 'How We Use Your Data'),
        _PolicyTextParagraph(
          text:
              'We use your information strictly to process orders, assign delivery drivers, track active tiffin deliveries, send live notifications, and provide customer support.',
        ),
        SizedBox(height: 12),
        _PolicySectionHeader(title: 'Data Security'),
        _PolicyTextParagraph(
          text:
              'We employ industry-standard encryption protocols (SSL/HTTPS) and secure JWT authentication to ensure your personal and payment details remain safe.',
        ),
      ],
    );
  }

  // ── 3. Shipping Policy Sheet ───────────────────────────────────────────────
  void _showShippingPolicySheet(BuildContext context) {
    _showPolicyBottomSheet(
      context: context,
      title: 'Shipping & Delivery Policy',
      icon: Icons.local_shipping_outlined,
      children: const [
        Text(
          'Hungrily Foods provides fresh daily tiffin and meal deliveries directly to your doorstep. Please review our shipping policy details below:',
          style: TextStyle(fontSize: 13.5, color: _greySub, height: 1.45),
        ),
        SizedBox(height: 14),
        _PolicySectionHeader(title: 'Service Radius & Coverage'),
        _PolicyTextParagraph(
          text:
              'Deliveries are strictly fulfilled within a maximum radius of 5 km from partner messes/kitchens to ensure your food arrives fresh and piping hot.',
        ),
        SizedBox(height: 12),
        _PolicySectionHeader(title: 'Delivery Slots & Timing'),
        _PolicyTextParagraph(
          text:
              '• Lunch Slot: Delivered between 12:00 PM – 2:00 PM\n• Dinner Slot: Delivered between 7:30 PM – 9:30 PM\n• Real-time live tracking is available on the Home Dashboard during active deliveries.',
        ),
        SizedBox(height: 12),
        _PolicySectionHeader(title: 'Tiffin Container Return'),
        _PolicyTextParagraph(
          text:
              'For active tiffin subscriptions, customers must return the empty tiffin container to the delivery partner on the next delivery attempt via an in-app OTP verification.',
        ),
      ],
    );
  }

  // ── 4. Contact Us Sheet ────────────────────────────────────────────────────
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

  void _showContactUsSheet(BuildContext context) {
    _showPolicyBottomSheet(
      context: context,
      title: 'Contact Us',
      icon: Icons.headset_mic_rounded,
      children: [
        const Text(
          'Have questions, feedback, or need help with your order? Our dedicated support team is here to assist you.',
          style: TextStyle(fontSize: 13.5, color: _greySub, height: 1.45),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFEDD5), width: 1.2),
          ),
          child: Column(
            children: [
              _ContactInfoTile(
                icon: Icons.email_rounded,
                title: 'Email Support',
                value: 'info@hungrilyfoods.com',
                onTap: () => _launchSupportUrl('mailto:info@hungrilyfoods.com'),
              ),
              Divider(height: 16, color: Color(0xFFFFEDD5)),
              _ContactInfoTile(
                icon: Icons.phone_rounded,
                title: 'Call Support 1',
                value: '02269620545',
                onTap: () => _launchSupportUrl('tel:02269620545'),
              ),
              Divider(height: 16, color: Color(0xFFFFEDD5)),
              _ContactInfoTile(
                icon: Icons.phone_in_talk_rounded,
                title: 'Call Support 2',
                value: '02269710877',
                onTap: () => _launchSupportUrl('tel:02269710877'),
              ),
              Divider(height: 16, color: Color(0xFFFFEDD5)),
              _ContactInfoTile(
                icon: Icons.chat_rounded,
                iconColor: Color(0xFF25D366),
                title: 'WhatsApp Support',
                value: '8625018625',
                onTap: () => _launchSupportUrl('https://wa.me/918625018625?text=Hello%20Hungrily%20Support'),
              ),
              Divider(height: 16, color: Color(0xFFFFEDD5)),
              _ContactInfoTile(
                icon: Icons.access_time_filled_rounded,
                title: 'Support Hours',
                value: 'Mon – Sat: 7:00 AM – 10:00 PM',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _PolicySectionHeader(title: 'Office Address'),
        const _PolicyTextParagraph(
          text: 'Nagapur, Ahilya Nagar, Maharashtra, India',
        ),
      ],
    );
  }

  // ── 5. Cancellation & Refunds Sheet ───────────────────────────────────────
  void _showCancellationAndRefundsSheet(BuildContext context) {
    _showPolicyBottomSheet(
      context: context,
      title: 'Cancellation and Refunds',
      icon: Icons.assignment_return_outlined,
      children: const [
        Text(
          'We strive to give you the best food experience. Here is our policy regarding order cancellations, pauses, and refund requests:',
          style: TextStyle(fontSize: 13.5, color: _greySub, height: 1.45),
        ),
        SizedBox(height: 14),
        _PolicySectionHeader(title: 'Order Cancellations'),
        _PolicyTextParagraph(
          text:
              '• Instant Orders: Orders can be cancelled prior to mess acceptance.\n• Subscription Meals: You can pause or skip upcoming scheduled deliveries directly from the Manage Subscriptions tab before 10:00 AM for Lunch or 5:00 PM for Dinner.',
        ),
        SizedBox(height: 12),
        _PolicySectionHeader(title: 'Refund Process'),
        _PolicyTextParagraph(
          text:
              '• If an order is cancelled eligible for a refund, the amount will be credited back to your Hungrily Wallet instantly or to your original payment method within 3–5 business days.',
        ),
        SizedBox(height: 12),
        _PolicySectionHeader(title: 'Quality & Missing Items'),
        _PolicyTextParagraph(
          text:
              'In the rare event of quality issues or missing items, please reach out via Contact Us within 2 hours of delivery for quick resolution or full credit refund.',
        ),
      ],
    );
  }
}

// ── Policy Text Helper Widgets ────────────────────────────────────────────────

class _PolicySectionHeader extends StatelessWidget {
  final String title;
  const _PolicySectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1A1A2E),
      ),
    );
  }
}

class _PolicyTextParagraph extends StatelessWidget {
  final String text;
  const _PolicyTextParagraph({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF6B7280),
          height: 1.4,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

class _ContactInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? iconColor;
  final VoidCallback? onTap;

  const _ContactInfoTile({
    required this.icon,
    required this.title,
    required this.value,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final body = Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: (iconColor ?? const Color(0xFFF58220)).withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor ?? const Color(0xFFF58220), size: 19),
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
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
        ),
        if (onTap != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: (iconColor ?? const Color(0xFFF58220)).withOpacity(0.12),
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
                    color: iconColor ?? const Color(0xFFF58220),
                  ),
                ),
                const SizedBox(width: 3),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 11,
                  color: iconColor ?? const Color(0xFFF58220),
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
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: body,
        ),
      );
    }
    return body;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Clipper for Header Orange Background Curve
// ─────────────────────────────────────────────────────────────────────────────

class HeaderCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 35);

    // Organic S-wave curve dipping under text and sweeping around avatar
    path.cubicTo(
      size.width * 0.36,
      size.height + 40,
      size.width * 0.54,
      size.height - 85,
      size.width,
      size.height - 65,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}
