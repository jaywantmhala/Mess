// lib/screens/tabs/profile_tab.dart
import 'package:flutter/material.dart';
import '../../models/vendor.dart';
import '../../services/auth_service.dart';
import '../../services/hotel_service.dart';
import '../../theme/app_theme.dart';
import '../welcome_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab>
    with SingleTickerProviderStateMixin {
  Vendor? _vendor;
  int _hotelCount = 0;
  bool _isLoading = true;

  late AnimationController _entryCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _loadProfileData();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    final vendor = await AuthService.instance.getSavedVendor();
    final hotels = await HotelService.instance.getHotels();
    if (mounted) {
      setState(() {
        _vendor = vendor;
        _hotelCount = hotels.length;
        _isLoading = false;
      });
      _entryCtrl.forward();
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.errorSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded,
                  color: AppColors.error, size: 18),
            ),
            const SizedBox(width: 12),
            const Text('Sign Out?',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink)),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out of your account?',
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out',
                style: TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.instance.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (_, anim, __) => const WelcomeScreen(),
          transitionDuration: const Duration(milliseconds: 380),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final hPad = Responsive.hPad(context);
    final bottomPad = mq.padding.bottom + 90;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2.5))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                // ── Sliver header / hero ─────────────────────────────
                SliverToBoxAdapter(
                  child: SlideTransition(
                    position: _slide,
                    child: FadeTransition(
                      opacity: _fade,
                      child: _ProfileHero(
                        vendor: _vendor,
                        hotelCount: _hotelCount,
                      ),
                    ),
                  ),
                ),

                // ── Body content ─────────────────────────────────────
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                      hPad, 0, hPad, bottomPad),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      FadeTransition(
                        opacity: _fade,
                        child: Column(
                          children: [
                            // Stats row
                            _StatsRow(hotelCount: _hotelCount),
                            const SizedBox(height: 24),

                            // Account detail card
                            _AccountInfoCard(vendor: _vendor),
                            const SizedBox(height: 24),

                            // Sign out
                            _SignOutButton(onSignOut: _handleLogout),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}

// ── Profile Hero ─────────────────────────────────────────────────────────────
class _ProfileHero extends StatelessWidget {
  final Vendor? vendor;
  final int hotelCount;

  const _ProfileHero({this.vendor, required this.hotelCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
          child: Column(
            children: [
              // Avatar
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.4), width: 2.5),
                ),
                child: const Icon(Icons.store_rounded,
                    size: 42, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                vendor?.fullName ?? 'Vendor Name',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                vendor?.email ?? 'email@example.com',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.82),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.verified_rounded,
                        size: 14, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Verified Partner',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
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
}

// ── Stats Row ─────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final int hotelCount;

  const _StatsRow({required this.hotelCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Row(
        children: [
          _StatCard(
            value: '$hotelCount',
            label: 'Registered Hotels',
            icon: Icons.hotel_rounded,
            color: AppColors.primary,
            bgColor: AppColors.primarySurface,
          ),
          const SizedBox(width: 14),
          _StatCard(
            value: 'Active',
            label: 'Account Status',
            icon: Icons.verified_user_rounded,
            color: AppColors.success,
            bgColor: AppColors.successSurface,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Account Info Card ─────────────────────────────────────────────────────────
class _AccountInfoCard extends StatelessWidget {
  final Vendor? vendor;

  const _AccountInfoCard({this.vendor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          _InfoTile(
            icon: Icons.calendar_month_rounded,
            iconBg: const Color(0xFFEFF6FF),
            iconColor: const Color(0xFF3B82F6),
            title: 'Member Since',
            trailing: vendor?.createdAt.split(' ').first ?? 'N/A',
          ),
          Divider(height: 1, indent: 68, color: AppColors.border),
          _InfoTile(
            icon: Icons.shield_rounded,
            iconBg: AppColors.successSurface,
            iconColor: AppColors.success,
            title: 'Account Authority',
            trailing: 'Verified Partner',
            trailingColor: AppColors.success,
          ),
          Divider(height: 1, indent: 68, color: AppColors.border),
          _InfoTile(
            icon: Icons.email_rounded,
            iconBg: AppColors.primarySurface,
            iconColor: AppColors.primary,
            title: 'Email',
            trailing: vendor?.email ?? '—',
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String trailing;
  final Color? trailingColor;

  const _InfoTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.trailing,
    this.trailingColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink),
            ),
          ),
          Text(
            trailing,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: trailingColor ?? AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sign Out Button ───────────────────────────────────────────────────────────
class _SignOutButton extends StatelessWidget {
  final VoidCallback onSignOut;

  const _SignOutButton({required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.errorSurface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onSignOut,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: AppColors.error.withOpacity(0.2), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
              SizedBox(width: 10),
              Text(
                'Sign Out',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
