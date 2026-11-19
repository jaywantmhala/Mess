// lib/screens/phone_auth_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../utils/location_data.dart';
import 'home_shell.dart';
import 'login_screen.dart';

class PhoneAuthScreen extends StatefulWidget {
  final String role; // 'vendor'

  const PhoneAuthScreen({
    super.key,
    this.role = 'vendor',
  });

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _otpController   = TextEditingController();
  final _nameController  = TextEditingController();
  final _emailController = TextEditingController();

  final _phoneFormKey   = GlobalKey<FormState>();
  final _profileFormKey = GlobalKey<FormState>();

  int _step = 1; // 1 = Enter Phone, 2 = Enter OTP, 3 = Complete Profile
  bool _isLoading = false;

  // Countdown timers for OTP Expiry (10 min) & Resend Cooldown (30s)
  Timer? _resendTimer;
  Timer? _otpExpiryTimer;
  int _resendCooldownSeconds = 30;
  int _otpExpirySeconds = 600; // 10 minutes (600s)
  bool _canResend = false;

  // Location fields for new vendor registration
  final String _selectedCountry = LocationData.defaultCountry;
  String? _selectedState;
  String? _selectedDistrict;
  String? _selectedTaluka;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  // Design Tokens matching Hungrily Vendor branding
  static const Color _brandOrange   = Color(0xFFF58220);
  static const Color _bgWarm        = Color(0xFFF6F8FA);
  static const Color _white         = Colors.white;
  static const Color _ink           = Color(0xFF1A1A2E);
  static const Color _greySub       = Color(0xFF6B7280);
  static const Color _fieldBorder   = Color(0xFFE5E7EB);
  static const Color _iconBoxBg     = Color(0xFFFFF0E6);
  static const Color _whatsappGreen = Color(0xFF25D366);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _resendTimer?.cancel();
    _otpExpiryTimer?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  String _formatMinutesSeconds(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  void _startTimers() {
    _resendTimer?.cancel();
    _otpExpiryTimer?.cancel();

    setState(() {
      _otpExpirySeconds = 600; // 10 Minutes
      _resendCooldownSeconds = 30;
      _canResend = false;
    });

    // 10-Minute Expiry Countdown
    _otpExpiryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_otpExpirySeconds > 0) {
        setState(() => _otpExpirySeconds--);
      } else {
        timer.cancel();
      }
    });

    // 30-Second Resend Cooldown
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendCooldownSeconds > 1) {
        setState(() => _resendCooldownSeconds--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  Future<void> _requestOtp() async {
    if (!(_phoneFormKey.currentState?.validate() ?? false)) return;
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final result = await AuthService.instance.sendWhatsAppOtp(
      phone: _phoneController.text.trim(),
      role: widget.role,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      _showSnack(result.message, isError: false);
      setState(() {
        _step = 2;
      });
      _startTimers();
      _animCtrl.reset();
      _animCtrl.forward();
    } else {
      _showSnack(result.message, isError: true);
    }
  }

  Future<void> _verifyOtp() async {
    final otpText = _otpController.text.trim();
    if (otpText.length < 6) {
      _showSnack('Please enter full 6-digit verification OTP.', isError: true);
      return;
    }
    if (_otpExpirySeconds <= 0) {
      _showSnack('OTP has expired! Please click Resend to get a new code.', isError: true);
      return;
    }
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final result = await AuthService.instance.verifyWhatsAppOtp(
      phone: _phoneController.text.trim(),
      otp: otpText,
      role: widget.role,
      fullName: _step == 3 ? _nameController.text.trim() : null,
      email: _step == 3 ? _emailController.text.trim() : null,
      country: _step == 3 ? _selectedCountry : null,
      state: _step == 3 ? _selectedState : null,
      district: _step == 3 ? _selectedDistrict : null,
      taluka: _step == 3 ? _selectedTaluka : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      if (result.isNewUser && _step != 3) {
        // Vendor not registered yet -> ask to complete profile
        _showSnack('OTP verified! Please complete your vendor details.', isError: false);
        setState(() {
          _step = 3;
        });
        _animCtrl.reset();
        _animCtrl.forward();
      } else {
        _showSnack(result.message, isError: false);
        await Future.delayed(const Duration(milliseconds: 350));
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeShell()),
          (route) => false,
        );
      }
    } else {
      _showSnack(result.message, isError: true);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(msg, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        ]),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 4),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgWarm,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _ink, size: 20),
          onPressed: () {
            if (_step == 2) {
              setState(() => _step = 1);
            } else if (_step == 3) {
              setState(() => _step = 2);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: _step == 1
                  ? _buildPhoneStep()
                  : (_step == 2 ? _buildOtpStep() : _buildProfileStep()),
            ),
          ),
        ),
      ),
    );
  }

  // ── Step 1: Mobile Number Input ──────────────────────────────────────────────
  Widget _buildPhoneStep() {
    return Form(
      key: _phoneFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _whatsappGreen.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.chat_bubble_rounded, size: 16, color: _whatsappGreen),
                SizedBox(width: 6),
                Text(
                  'WhatsApp Authentication',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _whatsappGreen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Vendor Phone Login',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: _ink,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your mobile number to sign in or register your restaurant. We will send a 6-digit OTP on WhatsApp.',
            style: TextStyle(
              fontSize: 14,
              color: _greySub,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),

          // Phone Field Container
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _ink,
              letterSpacing: 1.2,
            ),
            decoration: InputDecoration(
              hintText: 'Enter 10-digit number',
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 15,
                fontWeight: FontWeight.normal,
                letterSpacing: 0,
              ),
              prefixIcon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                margin: const EdgeInsets.only(right: 12),
                decoration: const BoxDecoration(
                  border: Border(right: BorderSide(color: Color(0xFFE5E7EB), width: 1.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('🇮🇳', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 6),
                    Text('+91', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
                  ],
                ),
              ),
              filled: true,
              fillColor: _white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _fieldBorder, width: 1.2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _fieldBorder, width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _whatsappGreen, width: 1.8),
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Mobile number is mandatory';
              }
              final clean = val.trim();
              if (clean.length != 10) {
                return 'Please enter a valid 10-digit mobile number';
              }
              if (!RegExp(r'^[6-9]\d{9}$').hasMatch(clean)) {
                return 'Please enter a valid Indian mobile number';
              }
              return null;
            },
          ),
          const SizedBox(height: 28),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _requestOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: _whatsappGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 3,
                shadowColor: _whatsappGreen.withOpacity(0.4),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.mark_chat_unread_rounded, color: Colors.white, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'Get WhatsApp OTP',
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 28),

          // Switch to Email / Password
          Center(
            child: GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: RichText(
                text: const TextSpan(
                  text: 'Prefer password? ',
                  style: TextStyle(color: _greySub, fontSize: 13.5, fontWeight: FontWeight.w500),
                  children: [
                    TextSpan(
                      text: 'Sign in with Email',
                      style: TextStyle(
                        color: _brandOrange,
                        fontWeight: FontWeight.w800,
                        decoration: TextDecoration.underline,
                        decorationColor: _brandOrange,
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
  }

  // ── Step 2: OTP Verification ────────────────────────────────────────────────
  Widget _buildOtpStep() {
    final bool isExpired = _otpExpirySeconds <= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _brandOrange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.shield_rounded, size: 16, color: _brandOrange),
                  SizedBox(width: 6),
                  Text(
                    'Verification',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _brandOrange,
                    ),
                  ),
                ],
              ),
            ),

            // 10-Minute Expiry Timer Badge (mm:ss)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isExpired ? Colors.red.withOpacity(0.1) : _whatsappGreen.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isExpired ? Colors.red.shade300 : _whatsappGreen.withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 15,
                    color: isExpired ? Colors.red : _whatsappGreen,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isExpired ? 'OTP Expired' : 'Expires in ${_formatMinutesSeconds(_otpExpirySeconds)}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: isExpired ? Colors.red : _whatsappGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        const Text(
          'Enter 6-Digit OTP',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: _ink,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),

        RichText(
          text: TextSpan(
            text: 'Code sent via WhatsApp to ',
            style: const TextStyle(fontSize: 14, color: _greySub, height: 1.4),
            children: [
              TextSpan(
                text: '+91 ${_phoneController.text}',
                style: const TextStyle(fontWeight: FontWeight.w800, color: _ink),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // OTP Input Field
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: _ink,
            letterSpacing: 16.0,
          ),
          decoration: InputDecoration(
            hintText: '──────',
            hintStyle: TextStyle(color: Colors.grey.shade300, fontSize: 28, letterSpacing: 16.0),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
            filled: true,
            fillColor: _white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _fieldBorder, width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _fieldBorder, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _brandOrange, width: 1.8),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Resend Timer Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _canResend
                ? TextButton.icon(
                    onPressed: _isLoading ? null : _requestOtp,
                    icon: const Icon(Icons.refresh_rounded, size: 18, color: _brandOrange),
                    label: const Text(
                      'Resend Code via WhatsApp',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: _brandOrange,
                      ),
                    ),
                  )
                : Text(
                    'Resend code in ${_resendCooldownSeconds}s',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: _greySub,
                    ),
                  ),
            TextButton(
              onPressed: () => setState(() => _step = 1),
              child: const Text(
                'Change Phone',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _greySub,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Verify Button
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: (_isLoading || isExpired) ? null : _verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: _brandOrange,
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              shadowColor: _brandOrange.withOpacity(0.4),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Text(
                    isExpired ? 'OTP Expired - Resend New Code' : 'Verify & Continue',
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ── Step 3: Complete Profile for New Vendor ──────────────────────────────────
  Widget _buildProfileStep() {
    return Form(
      key: _profileFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Complete Vendor Profile',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: _ink,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Just a few details to register your restaurant & start receiving orders.',
            style: TextStyle(
              fontSize: 14,
              color: _greySub,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),

          // Restaurant / Owner Name
          const Text('Restaurant / Owner Name *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _ink)),
          const SizedBox(height: 8),
          _buildInputContainer(
            icon: Icons.person_outline_rounded,
            child: TextFormField(
              controller: _nameController,
              keyboardType: TextInputType.name,
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: _ink),
              decoration: const InputDecoration(
                hintText: 'Enter restaurant or full name',
                hintStyle: TextStyle(color: Color(0xFFA0A5BA), fontSize: 14, fontWeight: FontWeight.w400),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter your restaurant or owner name';
                }
                if (val.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 18),

          // Email Address
          const Text('Email Address *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _ink)),
          const SizedBox(height: 8),
          _buildInputContainer(
            icon: Icons.mail_outline_rounded,
            child: TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: _ink),
              decoration: const InputDecoration(
                hintText: 'Enter your email address',
                hintStyle: TextStyle(color: Color(0xFFA0A5BA), fontSize: 14, fontWeight: FontWeight.w400),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Email address is required';
                }
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(val.trim())) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 18),

          // State Dropdown
          const Text('Select State', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _ink)),
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

          // District Dropdown
          const Text('Select District', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _ink)),
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

          // Taluka Dropdown
          const Text('Select Taluka', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _ink)),
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
          const SizedBox(height: 32),

          // Complete Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      if (_profileFormKey.currentState?.validate() ?? false) {
                        _verifyOtp();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandOrange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 3,
                shadowColor: _brandOrange.withOpacity(0.4),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text(
                      'Complete & Start Selling',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInputContainer({required IconData icon, required Widget child}) {
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
        ],
      ),
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
