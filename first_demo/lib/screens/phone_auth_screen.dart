// lib/screens/phone_auth_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import 'home_shell.dart';

class PhoneAuthScreen extends StatefulWidget {
  final String role; // 'customer' or 'vendor'

  const PhoneAuthScreen({
    super.key,
    this.role = 'customer',
  });

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController    = TextEditingController();
  final _otpController      = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController    = TextEditingController();

  final _phoneFormKey       = GlobalKey<FormState>();
  final _profileFormKey     = GlobalKey<FormState>();

  int _step = 1; // 1 = Enter Phone, 2 = Enter OTP, 3 = New User Profile Setup
  bool _isLoading = false;

  // Countdown timers for OTP Expiry (10 min) & Resend Cooldown
  Timer? _resendTimer;
  Timer? _otpExpiryTimer;
  int _resendCooldownSeconds = 30;
  int _otpExpirySeconds = 600; // 10 minutes (600s)
  bool _canResend = false;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  // Design Tokens
  static const Color _brandOrange = Color(0xFFF58220);
  static const Color _bgWarm      = Color(0xFFFDFBF7);
  static const Color _white       = Colors.white;
  static const Color _ink         = Color(0xFF1A1A2E);
  static const Color _greySub     = Color(0xFF6B7280);
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
    _fullNameController.dispose();
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
      _showSnack('OTP has expired! Please click Resend to get a new OTP.', isError: true);
      return;
    }
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final result = await AuthService.instance.verifyWhatsAppOtp(
      phone: _phoneController.text.trim(),
      otp: otpText,
      role: widget.role,
      fullName: _step == 3 ? _fullNameController.text.trim() : null,
      email: _step == 3 ? _emailController.text.trim() : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      if (result.isNewUser && _step != 3) {
        // Prompt user to complete profile details
        _showSnack('OTP verified! Please enter your name to complete signup.', isError: false);
        setState(() {
          _step = 3;
        });
        _animCtrl.reset();
        _animCtrl.forward();
      } else {
        _showSnack(result.message, isError: false);
        await Future.delayed(const Duration(milliseconds: 400));
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
            'Enter Mobile Number',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: _ink,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'We will send a 6-digit verification code to your WhatsApp number.',
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
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15, fontWeight: FontWeight.normal, letterSpacing: 0),
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
            ),
            validator: (val) {
              if (val == null || val.trim().length != 10) {
                return 'Please enter a valid 10-digit mobile number';
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

  // ── Step 3: Complete Profile for New User ───────────────────────────────────
  Widget _buildProfileStep() {
    return Form(
      key: _profileFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Complete Profile',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: _ink,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Just one last step! Enter your name to get started.',
            style: TextStyle(
              fontSize: 14,
              color: _greySub,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),

          // Full Name
          TextFormField(
            controller: _fullNameController,
            keyboardType: TextInputType.name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _ink),
            decoration: const InputDecoration(
              labelText: 'Full Name *',
              prefixIcon: Icon(Icons.person_outline_rounded, color: _greySub),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter your full name';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),

          // Email (Optional)
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _ink),
            decoration: const InputDecoration(
              labelText: 'Email Address (Optional)',
              prefixIcon: Icon(Icons.email_outlined, color: _greySub),
            ),
          ),
          const SizedBox(height: 32),

          // Complete Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () {
                if (_profileFormKey.currentState?.validate() ?? false) {
                  _verifyOtp();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandOrange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 3,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text(
                      'Complete & Continue',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
