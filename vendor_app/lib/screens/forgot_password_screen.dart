// lib/screens/forgot_password_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _step = 1; // 1: Email Validation & Send OTP, 2: OTP Verification, 3: Reset Password

  final _emailController    = TextEditingController();
  final _otpController      = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController  = TextEditingController();

  Timer? _emailDebounce;
  bool _isCheckingEmail = false;
  bool _isEmailValid    = false;
  String? _emailStatusMessage;

  bool _isSendingOtp   = false;
  bool _isVerifyingOtp = false;
  bool _isResetting    = false;

  bool _obscurePass    = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailDebounce?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // ── Automatic Debounced Email Verification ─────────────────────────────────
  void _onEmailChanged(String val) {
    if (_emailDebounce?.isActive ?? false) _emailDebounce!.cancel();

    final email = val.trim();
    if (email.isEmpty) {
      setState(() {
        _isEmailValid = false;
        _isCheckingEmail = false;
        _emailStatusMessage = null;
      });
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      setState(() {
        _isEmailValid = false;
        _isCheckingEmail = false;
        _emailStatusMessage = 'Please enter a valid email address.';
      });
      return;
    }

    setState(() {
      _isCheckingEmail = true;
      _emailStatusMessage = null;
    });

    _emailDebounce = Timer(const Duration(milliseconds: 500), () async {
      final res = await AuthService.instance.checkEmail(email);

      if (!mounted) return;
      setState(() {
        _isCheckingEmail = false;
        if (res.success) {
          _isEmailValid = true;
          _emailStatusMessage = 'Email is valid and registered.';
        } else {
          _isEmailValid = false;
          _emailStatusMessage = 'Email is not valid';
        }
      });
    });
  }

  // ── Step 1: Send OTP Button ────────────────────────────────────────────────
  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (!_isEmailValid || email.isEmpty) return;

    setState(() => _isSendingOtp = true);

    final res = await AuthService.instance.sendResetOTP(email);

    if (!mounted) return;
    setState(() => _isSendingOtp = false);

    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor: AppColors.success,
        ),
      );
      setState(() => _step = 2);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ── Step 2: Verify OTP Button ──────────────────────────────────────────────
  Future<void> _verifyOtp() async {
    final email = _emailController.text.trim();
    final otp   = _otpController.text.trim();

    if (otp.isEmpty || otp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the OTP code sent to your email.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isVerifyingOtp = true);

    final res = await AuthService.instance.verifyResetOTP(email, otp);

    if (!mounted) return;
    setState(() => _isVerifyingOtp = false);

    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP Verified! Enter your new password.'),
          backgroundColor: AppColors.success,
        ),
      );
      setState(() => _step = 3);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ── Step 3: Reset Password ────────────────────────────────────────────────
  Future<void> _resetPassword() async {
    final email       = _emailController.text.trim();
    final otp         = _otpController.text.trim();
    final newPassword = _passwordController.text;
    final confirm     = _confirmController.text;

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (newPassword != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isResetting = true);

    final res = await AuthService.instance.resetPassword(email, otp, newPassword);

    if (!mounted) return;
    setState(() => _isResetting = false);

    if (res.success) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
              SizedBox(width: 10),
              Text('Success', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Your password has been reset successfully. Please log in with your new password.',
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(ctx); // Close dialog
                Navigator.pop(context); // Back to Login Screen
              },
              child: const Text('Go to Login', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hPad = Responsive.hPad(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Forgot Password',
          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header Icon & Title ───────────
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _step == 1
                        ? Icons.mark_email_read_rounded
                        : _step == 2
                            ? Icons.pin_drop_rounded
                            : Icons.lock_reset_rounded,
                    size: 38,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _step == 1
                    ? 'Reset Vendor Password'
                    : _step == 2
                        ? 'Enter Verification Code'
                        : 'Generate New Password',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _step == 1
                    ? 'Enter your vendor email address. We will verify your account and send an OTP code.'
                    : _step == 2
                        ? 'We have sent a 6-digit OTP code to ${_emailController.text.trim()}'
                        : 'Create a new strong password for your vendor account.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 28),

              // ── STEP 1: AUTOMATIC EMAIL VALIDATION & SEND OTP ──────────
              if (_step == 1) ...[
                AppTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  hint: 'name@example.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: _onEmailChanged,
                  suffixWidget: _isCheckingEmail
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          ),
                        )
                      : _isEmailValid
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.success)
                          : null,
                ),
                if (_emailStatusMessage != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        _isEmailValid ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
                        color: _isEmailValid ? AppColors.success : AppColors.error,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _emailStatusMessage!,
                          style: TextStyle(
                            color: _isEmailValid ? AppColors.success : AppColors.error,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 28),

                // Send OTP Button
                AppPrimaryButton(
                  label: 'Send OTP Code',
                  icon: Icons.send_rounded,
                  isLoading: _isSendingOtp,
                  onPressed: (_isEmailValid && !_isSendingOtp) ? _sendOtp : null,
                ),
              ],

              // ── STEP 2: OTP VERIFICATION ─────────────────────────────────
              if (_step == 2) ...[
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
                  decoration: InputDecoration(
                    hintText: '000000',
                    counterText: '',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                AppPrimaryButton(
                  label: 'Verify OTP',
                  icon: Icons.verified_user_rounded,
                  isLoading: _isVerifyingOtp,
                  onPressed: _isVerifyingOtp ? null : _verifyOtp,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isSendingOtp ? null : _sendOtp,
                  child: const Text(
                    'Didn\'t receive OTP? Resend Code',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ],

              // ── STEP 3: GENERATE NEW PASSWORD ───────────────────────────
              if (_step == 3) ...[
                AppTextField(
                  controller: _passwordController,
                  label: 'New Password',
                  hint: 'Enter new password',
                  icon: Icons.lock_outline_rounded,
                  obscureText: _obscurePass,
                  suffixWidget: IconButton(
                    icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textHint),
                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _confirmController,
                  label: 'Confirm New Password',
                  hint: 'Re-enter new password',
                  icon: Icons.lock_outline_rounded,
                  obscureText: _obscureConfirm,
                  suffixWidget: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textHint),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                const SizedBox(height: 24),
                AppPrimaryButton(
                  label: 'Reset Password',
                  icon: Icons.check_circle_rounded,
                  isLoading: _isResetting,
                  onPressed: _isResetting ? null : _resetPassword,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
