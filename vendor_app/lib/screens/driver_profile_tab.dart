// lib/screens/driver_profile_tab.dart
import 'package:flutter/material.dart';
import '../models/driver.dart';
import '../services/driver_auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import 'login_screen.dart';

class DriverProfileTab extends StatefulWidget {
  const DriverProfileTab({super.key});

  @override
  State<DriverProfileTab> createState() => _DriverProfileTabState();
}

class _DriverProfileTabState extends State<DriverProfileTab> {
  Driver? _driver;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final driver = await DriverAuthService.instance.getSavedDriver();
    if (mounted) {
      setState(() {
        _driver = driver;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to sign out of your driver account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Offline status update first
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
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text(
          'Driver Profile',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile Header / Avatar
            Center(
              child: Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                      boxShadow: AppShadows.elevated,
                    ),
                    child: const Icon(
                      Icons.sports_motorsports_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _driver?.fullName ?? 'Driver Partner',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.ink),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: (_driver?.isOnline == true ? AppColors.success : Colors.grey).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _driver?.isOnline == true ? 'ONLINE' : 'OFFLINE',
                      style: TextStyle(
                        color: _driver?.isOnline == true ? AppColors.success : Colors.grey,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Profile info items card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.015),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildProfileItem(Icons.email_outlined, 'Email Address', _driver?.email ?? '-'),
                  const Divider(height: 24),
                  _buildProfileItem(Icons.phone_outlined, 'Phone Number', _driver?.phoneNumber ?? '-'),
                  const Divider(height: 24),
                  _buildProfileItem(Icons.motorcycle_rounded, 'Vehicle Registration', _driver?.vehicleNumber ?? '-'),
                ],
              ),
            ),
            const SizedBox(height: 36),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink)),
            ],
          ),
        ),
      ],
    );
  }
}
