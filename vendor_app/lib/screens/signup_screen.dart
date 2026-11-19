// lib/screens/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/location_data.dart';
import 'home_shell.dart';
import 'login_screen.dart';
import 'driver_signup_screen.dart';
import 'phone_auth_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _acceptPolicy = false;

  String _selectedCountry = LocationData.defaultCountry;
  String? _selectedState;
  String? _selectedDistrict;
  String? _selectedTaluka;
  String? _selectedArea;
  final _areaCtrl = TextEditingController();

  int _passwordStrength = 0;

  // Design Tokens matching 100% reference photo
  static const Color _brandOrange  = Color(0xFFF58220);
  static const Color _gradientEnd  = Color(0xFFE65100);
  static const Color _bgWarm       = Color(0xFFF6F8FA);
  static const Color _white        = Colors.white;
  static const Color _ink          = Color(0xFF1A1A2E);
  static const Color _greySub      = Color(0xFF8A8FA8);
  static const Color _fieldBorder  = Color(0xFFE5E7EB);
  static const Color _iconBoxBg    = Color(0xFFFFF0E6);

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    LocationData.loadFromJson();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
            CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
    _passwordCtrl.addListener(_checkPasswordStrength);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _areaCtrl.dispose();
    super.dispose();
  }

  void _checkPasswordStrength() {
    final p = _passwordCtrl.text;
    int score = 0;
    if (p.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(p)) score++;
    if (RegExp(r'[0-9]').hasMatch(p)) score++;
    if (RegExp(r'[!@#\$&*~]').hasMatch(p)) score++;
    setState(() => _passwordStrength = score);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _handleSignup() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedState == null || _selectedState!.isEmpty) {
      _showSnackBar('Please select your State.');
      return;
    }
    if (_selectedDistrict == null || _selectedDistrict!.isEmpty) {
      _showSnackBar('Please select your District.');
      return;
    }
    if (_selectedTaluka == null || _selectedTaluka!.isEmpty) {
      _showSnackBar('Please select your Taluka.');
      return;
    }
    if (!_acceptPolicy) {
      _showSnackBar('Please accept the Policy and Terms to proceed.');
      return;
    }

    setState(() => _isLoading = true);

    final res = await AuthService.instance.signUp(
      fullName: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phoneNumber: _phoneCtrl.text.trim(),
      password: _passwordCtrl.text,
      confirmPassword: _confirmCtrl.text,
      country: _selectedCountry,
      state: _selectedState,
      district: _selectedDistrict,
      taluka: _selectedTaluka,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res.success) {
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (_, anim, __) => const HomeShell(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
        (route) => false,
      );
    } else {
      _showErrorDialog(res.message);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Registration Failed',
            style: TextStyle(fontWeight: FontWeight.w900, color: _ink)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK',
                style: TextStyle(color: _brandOrange, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgWarm,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Stack(
          children: [
            // ── 1. Top Orange Header Banner with Custom Curved Bottom Edge ───
            ClipPath(
              clipper: HeaderCurveClipper(),
              child: Container(
                height: 360,
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

            // ── 2. Top Header Text & 3D Hotel Storefront Illustration ───────
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 10, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hungrily Brand Logo
                          Image.asset(
                            'assets/images/hungrily_logo.png',
                            height: 90,
                            fit: BoxFit.contain,
                            errorBuilder: (ctx, _, __) => Container(
                              width: 64,
                              height: 64,
                              decoration: const BoxDecoration(
                                color: _white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.restaurant_rounded, color: _brandOrange, size: 32),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Join Hungrily!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _white.withOpacity(0.95),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Vendor Register',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: _white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Register your restaurant & start\nreceiving orders.',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: _white.withOpacity(0.90),
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),

                    // High-Res 3D Hotel Storefront Illustration
                    Image.asset(
                      'assets/images/hotel_storefront_3d.png',
                      height: 200,
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, _, __) => Image.asset(
                        'assets/images/hotel_illustration.png',
                        height: 200,
                        fit: BoxFit.contain,
                        errorBuilder: (c, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── 3. Floating White Curved Form Card ───────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 305, left: 18, right: 18, bottom: 24),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.065),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Full Name Input Box ────────────────────────────
                          const Text(
                            'Restaurant / Owner Name',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInputContainer(
                            icon: Icons.person_outline_rounded,
                            child: TextFormField(
                              controller: _nameCtrl,
                              textInputAction: TextInputAction.next,
                              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: _ink),
                              decoration: const InputDecoration(
                                hintText: 'Enter restaurant or full name',
                                hintStyle: TextStyle(color: Color(0xFFA0A5BA), fontSize: 14, fontWeight: FontWeight.w400),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 10),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Full name is required';
                                if (v.length < 2) return 'Name must be at least 2 characters';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 18),

                          // ── Mobile Number Input Box (Mandatory) ────────────
                          const Text(
                            'Mobile Number *',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInputContainer(
                            icon: Icons.phone_iphone_rounded,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: const BoxDecoration(
                                    border: Border(right: BorderSide(color: Color(0xFFE5E7EB), width: 1.2)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Text('🇮🇳', style: TextStyle(fontSize: 17)),
                                      SizedBox(width: 4),
                                      Text('+91', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _ink)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: TextFormField(
                                    controller: _phoneCtrl,
                                    keyboardType: TextInputType.phone,
                                    textInputAction: TextInputAction.next,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(10),
                                    ],
                                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: _ink, letterSpacing: 0.8),
                                    decoration: const InputDecoration(
                                      hintText: 'Enter 10-digit mobile number',
                                      hintStyle: TextStyle(color: Color(0xFFA0A5BA), fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) return 'Mobile number is mandatory';
                                      final clean = v.trim();
                                      if (clean.length != 10) return 'Enter a valid 10-digit mobile number';
                                      if (!RegExp(r'^[6-9]\d{9}$').hasMatch(clean)) return 'Enter a valid Indian mobile number';
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // ── Email Address Input Box ────────────────────────
                          const Text(
                            'Email Address',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInputContainer(
                            icon: Icons.mail_outline_rounded,
                            child: TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: _ink),
                              decoration: const InputDecoration(
                                hintText: 'Enter your email',
                                hintStyle: TextStyle(color: Color(0xFFA0A5BA), fontSize: 14, fontWeight: FontWeight.w400),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 10),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Email is required';
                                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return 'Enter a valid email';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 18),

                          // ── Quick Location Search Banner ────────────────────────────
                          GestureDetector(
                            onTap: () async {
                              final result = await _showUnifiedLocationSearchModal(context);
                              if (result != null) {
                                setState(() {
                                  if (result['state'] != null && result['state']!.isNotEmpty) {
                                    _selectedState = result['state'];
                                  }
                                  if (result['district'] != null && result['district']!.isNotEmpty) {
                                    _selectedDistrict = result['district'];
                                  }
                                  if (result['taluka'] != null && result['taluka']!.isNotEmpty) {
                                    _selectedTaluka = result['taluka'];
                                  }
                                  if (result['area'] != null && result['area']!.isNotEmpty) {
                                    _selectedArea = result['area'];
                                    _areaCtrl.text = result['area']!;
                                  }
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: _brandOrange.withOpacity(0.35), width: 1.2),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.search_rounded, color: _brandOrange, size: 20),
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
                                      color: _brandOrange,
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
                          const SizedBox(height: 18),

                          // ── Searchable Location Selection ────────────────────────────
                          const Text(
                            'Select Country',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildSearchableSelectContainer(
                            icon: Icons.public_rounded,
                            value: _selectedCountry,
                            hintText: 'Select Country',
                            onTap: () async {
                              final picked = await _showSearchPicker(
                                context: context,
                                title: 'Select Country',
                                items: LocationData.countries,
                                selectedItem: _selectedCountry,
                              );
                              if (picked != null) {
                                setState(() {
                                  _selectedCountry = picked;
                                  _selectedState = null;
                                  _selectedDistrict = null;
                                  _selectedTaluka = null;
                                  _selectedArea = null;
                                  _areaCtrl.clear();
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 18),

                          const Text(
                            'Select State',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildSearchableSelectContainer(
                            icon: Icons.map_rounded,
                            value: _selectedState,
                            hintText: 'Select State',
                            onTap: () async {
                              final states = LocationData.getStates(_selectedCountry);
                              final picked = await _showSearchPicker(
                                context: context,
                                title: 'Select State',
                                items: states,
                                selectedItem: _selectedState,
                              );
                              if (picked != null) {
                                setState(() {
                                  _selectedState = picked;
                                  _selectedDistrict = null;
                                  _selectedTaluka = null;
                                  _selectedArea = null;
                                  _areaCtrl.clear();
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 18),

                          const Text(
                            'Select District',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildSearchableSelectContainer(
                            icon: Icons.location_city_rounded,
                            value: _selectedDistrict,
                            hintText: _selectedState == null ? 'Select State First' : 'Select District',
                            enabled: _selectedState != null,
                            onTap: () async {
                              final districts = LocationData.getDistricts(_selectedState!);
                              final picked = await _showSearchPicker(
                                context: context,
                                title: 'Select District ($_selectedState)',
                                items: districts,
                                selectedItem: _selectedDistrict,
                              );
                              if (picked != null) {
                                setState(() {
                                  _selectedDistrict = picked;
                                  _selectedTaluka = null;
                                  _selectedArea = null;
                                  _areaCtrl.clear();
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 18),

                          const Text(
                            'Select Taluka',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildSearchableSelectContainer(
                            icon: Icons.holiday_village_rounded,
                            value: _selectedTaluka,
                            hintText: _selectedDistrict == null ? 'Select District First' : 'Select Taluka',
                            enabled: _selectedDistrict != null,
                            onTap: () async {
                              final talukas = LocationData.getTalukas(_selectedDistrict!);
                              final picked = await _showSearchPicker(
                                context: context,
                                title: 'Select Taluka ($_selectedDistrict)',
                                items: talukas,
                                selectedItem: _selectedTaluka,
                              );
                              if (picked != null) {
                                setState(() {
                                  _selectedTaluka = picked;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 18),

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
                                  if (_selectedDistrict != null)
                                    GestureDetector(
                                      onTap: () async {
                                        final areas = LocationData.getAreas(_selectedDistrict!);
                                        final picked = await _showSearchPicker(
                                          context: context,
                                          title: 'Select Area ($_selectedDistrict)',
                                          items: areas,
                                          selectedItem: _areaCtrl.text.isNotEmpty ? _areaCtrl.text : _selectedArea,
                                          allowCustom: true,
                                          hintText: 'Search or enter area name...',
                                        );
                                        if (picked != null) {
                                          setState(() {
                                            _selectedArea = picked;
                                            _areaCtrl.text = picked;
                                          });
                                        }
                                      },
                                      child: Row(
                                        children: const [
                                          Icon(Icons.list_alt_rounded, size: 14, color: _brandOrange),
                                          SizedBox(width: 4),
                                          Text(
                                            'Browse Areas',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: _brandOrange,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _buildInputContainer(
                                icon: Icons.near_me_outlined,
                                suffix: IconButton(
                                  icon: const Icon(Icons.search_rounded, color: _brandOrange),
                                  tooltip: 'Search & Pick Area',
                                  onPressed: _selectedDistrict == null
                                      ? null
                                      : () async {
                                          final areas = LocationData.getAreas(_selectedDistrict!);
                                          final picked = await _showSearchPicker(
                                            context: context,
                                            title: 'Select Area ($_selectedDistrict)',
                                            items: areas,
                                            selectedItem: _areaCtrl.text.isNotEmpty ? _areaCtrl.text : _selectedArea,
                                            allowCustom: true,
                                            hintText: 'Search or enter area...',
                                          );
                                          if (picked != null) {
                                            setState(() {
                                              _selectedArea = picked;
                                              _areaCtrl.text = picked;
                                            });
                                          }
                                        },
                                ),
                                child: TextFormField(
                                  controller: _areaCtrl,
                                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: _ink),
                                  decoration: InputDecoration(
                                    hintText: _selectedDistrict == null
                                        ? 'Select District first to pick area'
                                        : 'Type or search Area (e.g. Kothrud, Hinjawadi...)',
                                    hintStyle: const TextStyle(color: Color(0xFFA0A5BA), fontSize: 13, fontWeight: FontWeight.w400),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  onChanged: (val) {
                                    _selectedArea = val;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          if (false) ...[
                          const Text(
                            'Select Country',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildDropdownContainer<String>(
                            icon: Icons.public_rounded,
                            value: _selectedCountry,
                            hintText: 'Select Country',
                            items: LocationData.countries,
                            onChanged: (val) {
                              if (val != null && val != _selectedCountry) {
                                setState(() {
                                  _selectedCountry = val;
                                  _selectedState = null;
                                  _selectedDistrict = null;
                                  _selectedTaluka = null;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 18),

                          // ── Select State Dropdown ───────────────────────────
                          const Text(
                            'Select State',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildDropdownContainer<String>(
                            icon: Icons.map_rounded,
                            value: _selectedState,
                            hintText: 'Select State',
                            items: LocationData.getStates(_selectedCountry),
                            onChanged: (val) {
                              if (val != _selectedState) {
                                setState(() {
                                  _selectedState = val;
                                  _selectedDistrict = null;
                                  _selectedTaluka = null;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 18),

                          // ── Select District Dropdown ────────────────────────
                          const Text(
                            'Select District',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildDropdownContainer<String>(
                            icon: Icons.location_city_rounded,
                            value: _selectedDistrict,
                            hintText: _selectedState == null ? 'Select State First' : 'Select District',
                            enabled: _selectedState != null,
                            items: _selectedState != null ? LocationData.getDistricts(_selectedState!) : [],
                            onChanged: (val) {
                              if (val != _selectedDistrict) {
                                setState(() {
                                  _selectedDistrict = val;
                                  _selectedTaluka = null;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 18),

                          // ── Select Taluka Dropdown ──────────────────────────
                          const Text(
                            'Select Taluka',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildDropdownContainer<String>(
                            icon: Icons.holiday_village_rounded,
                            value: _selectedTaluka,
                            hintText: _selectedDistrict == null ? 'Select District First' : 'Select Taluka',
                            enabled: _selectedDistrict != null,
                            items: _selectedDistrict != null ? LocationData.getTalukas(_selectedDistrict!) : [],
                            onChanged: (val) {
                              setState(() {
                                _selectedTaluka = val;
                              });
                            },
                          ),
                          const SizedBox(height: 18),

                          ],

                          // ── Password Input Box ─────────────────────────────
                          const Text(
                            'Password',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInputContainer(
                            icon: Icons.lock_outline_rounded,
                            suffix: GestureDetector(
                              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: const Color(0xFFA0A5BA),
                                  size: 20,
                                ),
                              ),
                            ),
                            child: TextFormField(
                              controller: _passwordCtrl,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.next,
                              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: _ink),
                              decoration: const InputDecoration(
                                hintText: 'Enter password',
                                hintStyle: TextStyle(color: Color(0xFFA0A5BA), fontSize: 14, fontWeight: FontWeight.w400),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 10),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Password is required';
                                if (v.length < 8) return 'Must be at least 8 characters';
                                return null;
                              },
                            ),
                          ),
                          if (_passwordCtrl.text.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _PasswordStrengthBar(strength: _passwordStrength),
                          ],
                          const SizedBox(height: 18),

                          // ── Confirm Password Input Box ─────────────────────
                          const Text(
                            'Confirm Password',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInputContainer(
                            icon: Icons.lock_reset_rounded,
                            suffix: GestureDetector(
                              onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Icon(
                                  _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: const Color(0xFFA0A5BA),
                                  size: 20,
                                ),
                              ),
                            ),
                            child: TextFormField(
                              controller: _confirmCtrl,
                              obscureText: _obscureConfirm,
                              textInputAction: TextInputAction.done,
                              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: _ink),
                              decoration: const InputDecoration(
                                hintText: 'Re-enter password',
                                hintStyle: TextStyle(color: Color(0xFFA0A5BA), fontSize: 14, fontWeight: FontWeight.w400),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 10),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Please confirm your password';
                                if (v != _passwordCtrl.text) return 'Passwords do not match';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 18),

                          // ── Terms & Policy Checkbox Row ────────────────────
                          Row(
                            children: [
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: Checkbox(
                                  value: _acceptPolicy,
                                  activeColor: _brandOrange,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  side: const BorderSide(color: Color(0xFFCCCCCC), width: 1.5),
                                  onChanged: (v) => setState(() => _acceptPolicy = v ?? false),
                                ),
                              ),
                              const SizedBox(width: 10),
                              RichText(
                                text: const TextSpan(
                                  text: 'I accept the ',
                                  style: TextStyle(fontSize: 13, color: _ink, fontWeight: FontWeight.w500),
                                  children: [
                                    TextSpan(
                                      text: 'Policy',
                                      style: TextStyle(color: _brandOrange, fontWeight: FontWeight.w800),
                                    ),
                                    TextSpan(text: ' and '),
                                    TextSpan(
                                      text: 'Terms',
                                      style: TextStyle(color: _brandOrange, fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // ── Register Button ───────────────────────────────
                          GestureDetector(
                            onTap: _isLoading ? null : _handleSignup,
                            child: Container(
                              height: 54,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_brandOrange, _gradientEnd],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: _brandOrange.withOpacity(0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(color: _white, strokeWidth: 2.5),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          Text(
                                            'Register Restaurant',
                                            style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w900,
                                              color: _white,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(Icons.arrow_forward_rounded, color: _white, size: 20),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ── "or" Divider Circle ───────────────────────────
                          Row(
                            children: [
                              const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: _white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
                                ),
                                child: const Center(
                                  child: Text(
                                    'or',
                                    style: TextStyle(fontSize: 11.5, color: _greySub, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ── Sign Up with Phone OTP Button ────────────────
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PhoneAuthScreen(role: 'vendor')),
                            ),
                            child: Container(
                              height: 52,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFF25D366),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF25D366).withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.phone_iphone_rounded, color: Colors.white, size: 21),
                                  SizedBox(width: 8),
                                  Text(
                                    'Sign Up with Phone OTP',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15.5,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ── Already Have An Account? Sign In ──────────────
                          Center(
                            child: GestureDetector(
                              onTap: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                              ),
                              child: RichText(
                                text: const TextSpan(
                                  text: "Already have an account? ",
                                  style: TextStyle(color: _greySub, fontSize: 13.5, fontWeight: FontWeight.w500),
                                  children: [
                                    TextSpan(
                                      text: 'Sign In',
                                      style: TextStyle(
                                        color: _brandOrange,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // ── Register as Driver Outlined Pill Button ────────
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const DriverSignupScreen()),
                            ),
                            child: Container(
                              height: 48,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF8F4),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: const Color(0xFFFFDBC8), width: 1.2),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.two_wheeler_rounded, color: _brandOrange, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Register as Driver',
                                    style: TextStyle(
                                      color: _brandOrange,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14.5,
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputContainer({required IconData icon, required Widget child, Widget? suffix}) {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _fieldBorder, width: 1.2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _iconBoxBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _brandOrange, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(child: child),
          if (suffix != null) suffix,
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
            color: hasVal ? _brandOrange.withOpacity(0.5) : _fieldBorder,
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
                color: enabled ? _iconBoxBg : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: enabled ? _brandOrange : _greySub, size: 21),
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
              color: enabled ? _brandOrange : const Color(0xFFA0A5BA),
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
                          icon: const Icon(Icons.close_rounded, color: _greySub),
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
                        prefixIcon: const Icon(Icons.search_rounded, color: _brandOrange, size: 22),
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
                          borderSide: const BorderSide(color: _brandOrange, width: 1.5),
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
                              border: Border.all(color: _brandOrange.withOpacity(0.5)),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.add_circle_outline_rounded, color: _brandOrange),
                              title: Text(
                                'Use "${filterQuery.trim()}"',
                                style: const TextStyle(fontWeight: FontWeight.w700, color: _brandOrange),
                              ),
                              subtitle: const Text('Tap to set as custom area', style: TextStyle(fontSize: 11, color: _greySub)),
                              onTap: () => Navigator.pop(ctx, filterQuery.trim()),
                            ),
                          );
                        }

                        final itemIndex = showCustomOption ? index - 1 : index;
                        final item = filtered[itemIndex];
                        final isSelected = item == selectedItem;

                        return ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          tileColor: isSelected ? _brandOrange.withOpacity(0.08) : null,
                          title: Text(
                            item,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                              color: isSelected ? _brandOrange : _ink,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_rounded, color: _brandOrange, size: 20)
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
                          style: const TextStyle(color: _greySub, fontSize: 13),
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
                          icon: const Icon(Icons.close_rounded, color: _greySub),
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
                        prefixIcon: const Icon(Icons.search_rounded, color: _brandOrange, size: 22),
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
                          borderSide: const BorderSide(color: _brandOrange, width: 1.5),
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
                                    style: const TextStyle(color: _greySub, fontSize: 14),
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
                                      style: const TextStyle(fontSize: 12, color: _greySub),
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

  Widget _buildDropdownContainer<T>({
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
        border: Border.all(color: _fieldBorder, width: 1.2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: enabled ? _iconBoxBg : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: enabled ? _brandOrange : _greySub, size: 21),
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
                  color: enabled ? _brandOrange : const Color(0xFFA0A5BA),
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

// ─────────────────────────────────────────────────────────────────────────────
// Custom Clipper for Header Orange Background Curve
// ─────────────────────────────────────────────────────────────────────────────

class HeaderCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 35);

    // Pronounced, deep organic S-wave curve dipping down under text and sweeping high under hotel building
    path.cubicTo(
      size.width * 0.36, size.height + 55,
      size.width * 0.54, size.height - 125,
      size.width, size.height - 95,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// Password Strength Indicator Bar
// ─────────────────────────────────────────────────────────────────────────────

class _PasswordStrengthBar extends StatelessWidget {
  final int strength;
  const _PasswordStrengthBar({required this.strength});

  Color get _color {
    switch (strength) {
      case 0:
      case 1:
        return AppColors.error;
      case 2:
        return AppColors.warning;
      case 3:
        return const Color(0xFF3B82F6);
      default:
        return AppColors.success;
    }
  }

  String get _label {
    switch (strength) {
      case 0:
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      default:
        return 'Strong';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            final active = i < strength;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 4,
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                decoration: BoxDecoration(
                  color: active ? _color : AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Text(
          'Password strength: $_label',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _color,
          ),
        ),
      ],
    );
  }
}
