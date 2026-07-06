import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/wallet_service.dart';
import '../../models/customer.dart';
import '../wallet_screen.dart';
import '../welcome_screen.dart';
import '../your_orders_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  static const Color textDark = Color(0xFF1C1C1C);
  static const Color textGrey = Color(0xFF696969);
  static const Color coralPrimary = Color(0xFFFF6F5E);
  static const Color coralSoft = Color(0xFFFFEDE9);

  Customer? _customer;
  double? _walletBalance;
  bool _isLoading = true;

  // Preferences toggles state
  bool _isVeg = false;
  bool _allergyNuts = false;
  bool _allergyGluten = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    WalletService.instance.balanceNotifier.addListener(_onWalletBalanceChanged);
  }

  @override
  void dispose() {
    WalletService.instance.balanceNotifier.removeListener(_onWalletBalanceChanged);
    super.dispose();
  }

  void _onWalletBalanceChanged() {
    if (mounted) {
      setState(() {
        _walletBalance = WalletService.instance.balanceNotifier.value;
      });
    }
  }

  Future<void> _loadProfileData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final customer = await AuthService.instance.getSavedCustomer();
      final balanceData = await WalletService.instance.getBalance();
      if (mounted) {
        setState(() {
          _customer = customer;
          _walletBalance = balanceData.balance;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load profile data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getUserInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final name = _customer?.fullName ?? 'Valued Customer';
    final email = _customer?.email ?? 'customer@example.com';
    final initials = _getUserInitials(name);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: coralPrimary,
                ),
              )
            : RefreshIndicator(
                color: coralPrimary,
                onRefresh: _loadProfileData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header title
                      const Text(
                        'My Profile',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: textDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 1. Customer User Details Row
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFEEF0F4)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: coralSoft,
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: coralPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    email,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: textGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 2. My Wallet Section (Hero Card)
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const WalletScreen(),
                            ),
                          );
                          _loadProfileData(); // Reload balance when returning
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF8A7A), coralPrimary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: coralPrimary.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(
                                        Icons.account_balance_wallet_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'MY WALLET',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: Colors.white70,
                                    size: 14,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Available Balance',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _walletBalance != null
                                    ? '₹${_walletBalance!.toStringAsFixed(2)}'
                                    : '₹0.00',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2.5 Your Orders Option
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFEEF0F4)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.01),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: coralSoft,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              color: coralPrimary,
                              size: 20,
                            ),
                          ),
                          title: const Text(
                            'Your Orders',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: textDark,
                            ),
                          ),
                          subtitle: const Text(
                            'View your order history & status',
                            style: TextStyle(
                              fontSize: 11,
                              color: textGrey,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: textGrey,
                            size: 14,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const YourOrdersScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 3. Dietary Preferences Section
                      const Text(
                        'Dietary & Allergy Settings',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFEEF0F4)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.01),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildSwitchTile(
                              title: 'Veg Only menu',
                              subtitle: 'Filter all menu listings to vegetarian.',
                              value: _isVeg,
                              onChanged: (val) {
                                setState(() {
                                  _isVeg = val;
                                });
                              },
                            ),
                            const Divider(color: Color(0xFFEEF0F4), height: 1),
                            _buildSwitchTile(
                              title: 'Nut Allergy alert',
                              subtitle: 'Warn me if dishes contain peanuts or cashews.',
                              value: _allergyNuts,
                              onChanged: (val) {
                                setState(() {
                                  _allergyNuts = val;
                                });
                              },
                            ),
                            const Divider(color: Color(0xFFEEF0F4), height: 1),
                            _buildSwitchTile(
                              title: 'Gluten Intolerance',
                              subtitle: 'Highlight gluten-free alternatives.',
                              value: _allergyGluten,
                              onChanged: (val) {
                                setState(() {
                                  _allergyGluten = val;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 4. Logout Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent, width: 1.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Sign Out'),
                                content: const Text('Are you sure you want to sign out?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel', style: TextStyle(color: textGrey)),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Sign Out'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              final navigator = Navigator.of(context);
                              await AuthService.instance.logout();
                              navigator.pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => const WelcomeScreen(),
                                ),
                                (route) => false,
                              );
                            }
                          },
                          child: const Text(
                            'SIGN OUT OF PROFILE',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textDark),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11, color: textGrey),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: coralPrimary,
      activeTrackColor: coralPrimary.withOpacity(0.2),
      inactiveThumbColor: Colors.grey[400],
      inactiveTrackColor: Colors.grey[200],
    );
  }
}
