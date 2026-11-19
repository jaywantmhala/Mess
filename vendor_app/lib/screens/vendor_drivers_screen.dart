// lib/screens/vendor_drivers_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/vendor.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';

class VendorDriversScreen extends StatefulWidget {
  const VendorDriversScreen({super.key});

  @override
  State<VendorDriversScreen> createState() => _VendorDriversScreenState();
}

class _VendorDriversScreenState extends State<VendorDriversScreen> {
  static const Color _bg         = Color(0xFFFFF8F5);
  static const Color _orange     = Color(0xFFF58220);
  static const Color _green      = Color(0xFF28A745);
  static const Color _offlineGrey= Color(0xFF757575);
  static const Color _ink        = Color(0xFF1A1A2E);
  static const Color _grey       = Color(0xFF8A8FA8);
  static const Color _cardBg     = Colors.white;
  static const Color _whatsappGreen = Color(0xFF25D366);

  bool _isLoading = true;
  List<VendorDriver> _allDrivers = [];
  List<VendorDriver> _filteredDrivers = [];
  Vendor? _vendor;
  
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedFilter = 'All'; // 'All', 'Online', 'Offline'

  @override
  void initState() {
    super.initState();
    _loadVendorProfile();
    _fetchDrivers();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadVendorProfile() async {
    final v = await AuthService.instance.getSavedVendor();
    if (mounted) {
      setState(() => _vendor = v);
    }
  }

  /// Normalizes any phone number input to clean 10 digits
  static String normalizePhone(String raw) {
    String digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12 && digits.startsWith('91')) {
      digits = digits.substring(2);
    } else if (digits.length == 11 && digits.startsWith('0')) {
      digits = digits.substring(1);
    } else if (digits.length > 10) {
      digits = digits.substring(digits.length - 10);
    }
    return digits;
  }

  /// Checks if a driver with the given phone number already exists in the vendor's drivers
  VendorDriver? _findExistingDriverByPhone(String rawPhone) {
    final clean = normalizePhone(rawPhone);
    if (clean.length != 10) return null;
    for (final d in _allDrivers) {
      if (normalizePhone(d.phoneNumber) == clean) {
        return d;
      }
    }
    return null;
  }

  /// Checks if a driver with the given email already exists in the vendor's drivers
  VendorDriver? _findExistingDriverByEmail(String rawEmail) {
    final clean = rawEmail.trim().toLowerCase();
    if (clean.isEmpty) return null;
    for (final d in _allDrivers) {
      if (d.email.trim().toLowerCase() == clean) {
        return d;
      }
    }
    return null;
  }

  /// Generates the onboarding WhatsApp message containing driver credentials (unencrypted password)
  String _buildWhatsAppMessage({
    required String driverName,
    required String phone,
    required String password,
    required String vehicleNumber,
    String? vendorName,
    String? vendorPhone,
  }) {
    final cleanPhone = normalizePhone(phone);
    final vName = (vendorName != null && vendorName.trim().isNotEmpty) ? vendorName.trim() : 'Hungrily Partner';
    final vPhone = (vendorPhone != null && vendorPhone.trim().isNotEmpty) ? vendorPhone.trim() : '';

    return '''🎉 *HUNGRILY DRIVER ONBOARDING* 🎉

Hello *$driverName*,
Welcome to the Hungrily Delivery Team! Your driver account has been created by *$vName*.

Here are your login credentials for the *Hungrily Driver App*:

📱 *Mobile (Login ID):* +91 $cleanPhone
🔑 *Password:* $password
🛵 *Vehicle Number:* $vehicleNumber
🏢 *Mess / Vendor:* $vName

📲 *How to Log In & Start Delivering:*
1. Open the *Hungrily Driver App* on your mobile device.
2. Enter your Registered Mobile: +91 $cleanPhone
3. Enter your Password: $password
4. Tap *Login* and toggle *Go Online* to receive order deliveries!

⚠️ *Important Security Note:*
Please keep your credentials safe and do not share your password with anyone.

${vPhone.isNotEmpty ? '📞 *Vendor Support Contact:* +91 $vPhone\n' : ''}Wish you safe and happy deliveries with Hungrily! 🚀''';
  }

  /// Direct WhatsApp launcher using deep link with web fallback
  Future<void> _launchWhatsAppChat({
    required BuildContext context,
    required String phone,
    required String message,
  }) async {
    final clean = normalizePhone(phone);
    if (clean.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid 10-digit mobile number for WhatsApp'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final fullNumber = '91$clean';
    final encodedMsg = Uri.encodeComponent(message);

    final nativeUri = Uri.parse('whatsapp://send?phone=$fullNumber&text=$encodedMsg');
    final webUri = Uri.parse('https://wa.me/$fullNumber?text=$encodedMsg');

    try {
      final launched = await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
      if (launched) return;
    } catch (_) {}

    try {
      final launched = await launchUrl(webUri, mode: LaunchMode.externalApplication);
      if (launched) return;
    } catch (_) {}

    try {
      await launchUrl(webUri, mode: LaunchMode.platformDefault);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open WhatsApp: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Displays the interactive credentials dialog after a driver is created
  void _showDriverCreatedSuccessDialog({
    required BuildContext context,
    required String driverName,
    required String phoneNumber,
    required String password,
    required String vehicleNumber,
    required String email,
    bool whatsappSent = false,
    String? whatsappServerMessage,
  }) {
    bool showPassword = true;
    bool isResendingApi = false;
    bool currentWaSent = whatsappSent;
    String currentWaMsg = whatsappServerMessage ?? (whatsappSent ? 'Credentials dispatched via WhatsApp API.' : '');

    final whatsappMsg = _buildWhatsAppMessage(
      driverName: driverName,
      phone: phoneNumber,
      password: password,
      vehicleNumber: vehicleNumber,
      vendorName: _vendor?.fullName,
      vendorPhone: _vendor?.phoneNumber,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dlgCtx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Success Icon Badge
                      Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F5E9),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.check_circle_rounded, color: _green, size: 38),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Title & Subtitle
                      const Text(
                        'Driver Registered!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Account created for $driverName',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: _grey,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // WhatsApp Server API Broadcast Status Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: currentWaSent ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: currentWaSent ? const Color(0xFFA5D6A7) : const Color(0xFFFFCC80),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              currentWaSent ? Icons.mark_chat_read_rounded : Icons.mark_chat_unread_rounded,
                              size: 20,
                              color: currentWaSent ? _green : Colors.orange.shade800,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentWaSent
                                        ? 'WhatsApp API Broadcast: SENT'
                                        : 'WhatsApp API Status',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: currentWaSent ? const Color(0xFF1B5E20) : Colors.orange.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    currentWaSent
                                        ? 'Credentials & password dispatched to +91 $phoneNumber via WhatsApp API.'
                                        : (currentWaMsg.isNotEmpty ? currentWaMsg : 'Click "Resend via API" or open WhatsApp below.'),
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: currentWaSent ? const Color(0xFF2E7D32) : Colors.orange.shade900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Credentials Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF9F5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFFDEC9)),
                        ),
                        child: Column(
                          children: [
                            _buildCredRow(
                              icon: Icons.person_rounded,
                              label: 'Full Name',
                              value: driverName,
                            ),
                            const Divider(height: 14, color: Color(0xFFFFDEC9)),
                            _buildCredRow(
                              icon: Icons.phone_android_rounded,
                              label: 'Login Mobile',
                              value: '+91 $phoneNumber',
                            ),
                            const Divider(height: 14, color: Color(0xFFFFDEC9)),
                            _buildCredRow(
                              icon: Icons.lock_rounded,
                              label: 'Password (Original)',
                              value: showPassword ? password : '••••••••',
                              trailing: IconButton(
                                icon: Icon(
                                  showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  size: 18,
                                  color: _orange,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  setDlgState(() => showPassword = !showPassword);
                                },
                              ),
                            ),
                            const Divider(height: 14, color: Color(0xFFFFDEC9)),
                            _buildCredRow(
                              icon: Icons.two_wheeler_rounded,
                              label: 'Vehicle Number',
                              value: vehicleNumber,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Primary WhatsApp Button (Open App)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _launchWhatsAppChat(
                              context: ctx,
                              phone: phoneNumber,
                              message: whatsappMsg,
                            );
                          },
                          icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                          label: const Text(
                            'Open in WhatsApp (Direct Chat)',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _whatsappGreen,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Secondary API Broadcast Resend Button
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: isResendingApi
                              ? null
                              : () async {
                                  setDlgState(() => isResendingApi = true);
                                  final res = await OrderService.instance.sendDriverWhatsAppApi(
                                    phoneNumber: phoneNumber,
                                    message: whatsappMsg,
                                    driverName: driverName,
                                  );
                                  setDlgState(() {
                                    isResendingApi = false;
                                    currentWaSent = res['success'] == true;
                                    currentWaMsg = res['message'] ?? '';
                                  });

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(res['success'] == true
                                            ? '🚀 WhatsApp broadcast delivered via API!'
                                            : '⚠️ ${res['message']}'),
                                        backgroundColor: res['success'] == true ? _green : Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                          icon: isResendingApi
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: _orange),
                                )
                              : const Icon(Icons.cloud_upload_outlined, size: 18, color: _orange),
                          label: Text(
                            isResendingApi ? 'Dispatching via WhatsApp API...' : 'Resend via WhatsApp API',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: _orange,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _orange),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Tertiary Action Buttons: Copy & Done
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: whatsappMsg));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('📋 Credentials copied to clipboard!'),
                                    backgroundColor: _green,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy_rounded, size: 16, color: _ink),
                              label: const Text(
                                'Copy',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _ink,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 11),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(dlgCtx),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF0F1F5),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 11),
                              ),
                              child: const Text(
                                'Done',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _ink,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCredRow({
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _orange),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: _grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }

  Future<void> _fetchDrivers() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final list = await OrderService.instance.getVendorDrivers();
    if (mounted) {
      setState(() {
        _allDrivers = list;
        _applyFilters();
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filteredDrivers = _allDrivers.where((d) {
        // Status filter
        if (_selectedFilter == 'Online' && !d.isOnline) return false;
        if (_selectedFilter == 'Offline' && d.isOnline) return false;

        // Search query filter
        if (query.isNotEmpty) {
          final nameMatch = d.fullName.toLowerCase().contains(query);
          final vehicleMatch = d.vehicleNumber.toLowerCase().contains(query);
          final phoneMatch = d.phoneNumber.toLowerCase().contains(query);
          final emailMatch = d.email.toLowerCase().contains(query);
          return nameMatch || vehicleMatch || phoneMatch || emailMatch;
        }
        return true;
      }).toList();
    });
  }

  /// Interactive bottom sheet for sending a WhatsApp message to an existing driver
  void _showSendDriverWhatsAppModal(BuildContext context, VendorDriver driver) {
    final vName = (_vendor?.fullName != null && _vendor!.fullName.trim().isNotEmpty)
        ? _vendor!.fullName.trim()
        : 'Hungrily Partner';

    final defaultMsg =
        'Hello ${driver.fullName},\n\n'
        'This is a notification from $vName.\n'
        'Please check your Hungrily Driver App and set your status to Online when ready to accept delivery orders.\n\n'
        'Registered Mobile: +91 ${driver.phoneNumber}\n'
        'Vehicle: ${driver.vehicleNumber}';

    final textCtrl = TextEditingController(text: defaultMsg);
    bool isSending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
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
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8F5E9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.mark_chat_read_rounded, color: _whatsappGreen, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Send WhatsApp Message',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: _ink,
                                ),
                              ),
                              Text(
                                '${driver.fullName} (+91 ${driver.phoneNumber})',
                                style: const TextStyle(fontSize: 12.5, color: _grey, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Quick Templates:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _grey),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        ActionChip(
                          label: const Text('Go Online', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                          backgroundColor: const Color(0xFFFFF0E6),
                          onPressed: () {
                            setSheetState(() {
                              textCtrl.text =
                                  'Hello ${driver.fullName},\nPlease open the Hungrily Driver App and toggle "Go Online". Orders are waiting for delivery!';
                            });
                          },
                        ),
                        ActionChip(
                          label: const Text('Order Ready', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                          backgroundColor: const Color(0xFFE8F5E9),
                          onPressed: () {
                            setSheetState(() {
                              textCtrl.text =
                                  'Hello ${driver.fullName},\nNew order is ready for pickup at our kitchen ($vName). Please proceed immediately!';
                            });
                          },
                        ),
                        ActionChip(
                          label: const Text('Login Details Help', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                          backgroundColor: const Color(0xFFEDE7F6),
                          onPressed: () {
                            setSheetState(() {
                              textCtrl.text =
                                  'Hello ${driver.fullName},\nReminder for your Hungrily Driver App login:\n'
                                  '📱 Registered Mobile: +91 ${driver.phoneNumber}\n'
                                  '🛵 Vehicle: ${driver.vehicleNumber}\n'
                                  'Please log in with your account password or contact $vName if you need help.';
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Message Content:',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _ink),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: textCtrl,
                      maxLines: 5,
                      style: const TextStyle(fontSize: 13, color: _ink),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        hintText: 'Enter WhatsApp message for driver...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _orange, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: isSending
                            ? null
                            : () async {
                                final msgToSend = textCtrl.text.trim();
                                if (msgToSend.isEmpty) return;

                                setSheetState(() => isSending = true);
                                final res = await OrderService.instance.sendDriverWhatsAppApi(
                                  driverId: driver.id,
                                  phoneNumber: driver.phoneNumber,
                                  message: msgToSend,
                                  driverName: driver.fullName,
                                );
                                setSheetState(() => isSending = false);

                                if (context.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(res['success'] == true
                                          ? '🚀 WhatsApp broadcast delivered to ${driver.fullName}!'
                                          : '⚠️ ${res['message']}'),
                                      backgroundColor: res['success'] == true ? _green : Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                        icon: isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 20),
                        label: Text(
                          isSending ? 'Sending via WhatsApp API...' : 'Send via Server WhatsApp API',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _whatsappGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _launchWhatsAppChat(
                            context: context,
                            phone: driver.phoneNumber,
                            message: textCtrl.text.trim(),
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_outline_rounded, color: _ink, size: 18),
                        label: const Text(
                          'Open in WhatsApp (Direct Chat)',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _ink),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade400),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
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

  void _showFilterMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Drivers',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _ink),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.people_outline_rounded, color: _selectedFilter == 'All' ? _orange : _grey),
                title: const Text('All Drivers', style: TextStyle(fontWeight: FontWeight.w600)),
                trailing: _selectedFilter == 'All' ? const Icon(Icons.check_circle_rounded, color: _orange) : null,
                onTap: () {
                  setState(() => _selectedFilter = 'All');
                  _applyFilters();
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.circle_rounded, color: _green, size: 16),
                title: const Text('Online Drivers Only', style: TextStyle(fontWeight: FontWeight.w600)),
                trailing: _selectedFilter == 'Online' ? const Icon(Icons.check_circle_rounded, color: _orange) : null,
                onTap: () {
                  setState(() => _selectedFilter = 'Online');
                  _applyFilters();
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.circle_rounded, color: _offlineGrey, size: 16),
                title: const Text('Offline Drivers Only', style: TextStyle(fontWeight: FontWeight.w600)),
                trailing: _selectedFilter == 'Offline' ? const Icon(Icons.check_circle_rounded, color: _orange) : null,
                onTap: () {
                  setState(() => _selectedFilter = 'Offline');
                  _applyFilters();
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddDriverModal(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final vehicleCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool isSubmitting = false;
        bool obscurePassword = true;

        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
                top: 20,
                left: 20,
                right: 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0E6),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.person_add_alt_1_rounded, color: _orange, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Add Delivery Driver',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: _ink,
                                ),
                              ),
                              Text(
                                'Create driver account linked to your vendor',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      _buildModalField(
                        controller: nameCtrl,
                        label: 'Full Name',
                        hint: 'e.g. Rahul Sharma',
                        icon: Icons.person_outline_rounded,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter driver full name' : null,
                      ),
                      const SizedBox(height: 12),

                      _buildModalField(
                        controller: emailCtrl,
                        label: 'Email Address',
                        hint: 'e.g. rahul.driver@example.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || !v.contains('@')) return 'Enter a valid email address';
                          final existing = _findExistingDriverByEmail(v);
                          if (existing != null) {
                            return '⚠️ Email already registered to "${existing.fullName}"';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      _buildModalField(
                        controller: passCtrl,
                        label: 'Password',
                        hint: '••••••••',
                        icon: Icons.lock_outline_rounded,
                        obscureText: obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            color: _grey,
                            size: 20,
                          ),
                          onPressed: () => setModalState(() => obscurePassword = !obscurePassword),
                        ),
                        validator: (v) => (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
                      ),
                      const SizedBox(height: 12),

                      _buildModalField(
                        controller: vehicleCtrl,
                        label: 'Vehicle Number',
                        hint: 'e.g. MH 12 AB 1234',
                        icon: Icons.two_wheeler_rounded,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter vehicle registration number' : null,
                      ),
                      const SizedBox(height: 12),

                      _buildModalField(
                        controller: phoneCtrl,
                        label: 'Phone Number',
                        hint: 'e.g. 9876543210',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter mobile number';
                          final clean = normalizePhone(v);
                          if (clean.length != 10) return 'Enter a valid 10-digit mobile number';
                          if (!RegExp(r'^[6-9]\d{9}$').hasMatch(clean)) {
                            return 'Mobile number must start with 6, 7, 8, or 9';
                          }
                          final existing = _findExistingDriverByPhone(clean);
                          if (existing != null) {
                            return '⚠️ Phone already registered to "${existing.fullName}"';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;

                                  final cleanPhone = normalizePhone(phoneCtrl.text);
                                  final existingByPhone = _findExistingDriverByPhone(cleanPhone);
                                  if (existingByPhone != null) {
                                    ScaffoldMessenger.of(modalCtx).showSnackBar(
                                      SnackBar(
                                        content: Text('⚠️ Mobile $cleanPhone is already registered to "${existingByPhone.fullName}"'),
                                        backgroundColor: Colors.red.shade700,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    return;
                                  }

                                  final cleanEmail = emailCtrl.text.trim().toLowerCase();
                                  final existingByEmail = _findExistingDriverByEmail(cleanEmail);
                                  if (existingByEmail != null) {
                                    ScaffoldMessenger.of(modalCtx).showSnackBar(
                                      SnackBar(
                                        content: Text('⚠️ Email $cleanEmail is already registered to "${existingByEmail.fullName}"'),
                                        backgroundColor: Colors.red.shade700,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    return;
                                  }

                                  setModalState(() => isSubmitting = true);

                                  final driverName = nameCtrl.text.trim();
                                  final driverPass = passCtrl.text.trim();
                                  final driverVehicle = vehicleCtrl.text.trim().toUpperCase();

                                  final res = await OrderService.instance.addDriver(
                                    fullName: driverName,
                                    email: cleanEmail,
                                    password: driverPass,
                                    vehicleNumber: driverVehicle,
                                    phoneNumber: cleanPhone,
                                  );

                                  if (modalCtx.mounted) setModalState(() => isSubmitting = false);

                                  if (res['success'] == true) {
                                    if (modalCtx.mounted) Navigator.pop(modalCtx);
                                    _fetchDrivers();

                                    final bool waSent = res['whatsapp_sent'] == true;
                                    final String waMsg = res['whatsapp_message'] ?? '';

                                    // Display credential summary & WhatsApp trigger dialog
                                    if (mounted) {
                                      _showDriverCreatedSuccessDialog(
                                        context: this.context,
                                        driverName: driverName,
                                        phoneNumber: cleanPhone,
                                        password: driverPass,
                                        vehicleNumber: driverVehicle,
                                        email: cleanEmail,
                                        whatsappSent: waSent,
                                        whatsappServerMessage: waMsg.isNotEmpty ? waMsg : (waSent ? 'Delivered via Click2Api WhatsApp server' : ''),
                                      );
                                    }
                                  } else {
                                    if (modalCtx.mounted) {
                                      ScaffoldMessenger.of(modalCtx).showSnackBar(
                                        SnackBar(
                                          content: Text(res['message'] ?? 'Failed to add driver'),
                                          backgroundColor: Colors.red.shade600,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text(
                                  'Register Driver',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _ink),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
            prefixIcon: Icon(icon, color: _orange, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _orange, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Header ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  // Back Button (White card with orange arrow)
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.arrow_back_rounded, color: _orange, size: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Title & Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Drivers',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Manage your delivery drivers',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: _grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Notification Bell
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(Icons.notifications_outlined, color: _ink, size: 22),
                        Positioned(
                          top: 10,
                          right: 12,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: _orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Search Bar & Filter Row ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Search Bar Input
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        style: const TextStyle(fontSize: 13.5, color: _ink),
                        decoration: InputDecoration(
                          hintText: 'Search driver by name, vehicle or phone...',
                          hintStyle: const TextStyle(color: Color(0xFFA0A5BB), fontSize: 13),
                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFA0A5BB), size: 20),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? GestureDetector(
                                  onTap: () => _searchCtrl.clear(),
                                  child: const Icon(Icons.close_rounded, color: _grey, size: 18),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Filter Button
                  GestureDetector(
                    onTap: _showFilterMenu,
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.tune_rounded, color: _orange, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            _selectedFilter == 'All' ? 'Filter' : _selectedFilter,
                            style: const TextStyle(
                              color: _orange,
                              fontSize: 14,
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

            const SizedBox(height: 8),

            // ── Drivers List Body ────────────────────────────────────────────
            Expanded(
              child: Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: _fetchDrivers,
                    color: _orange,
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: _orange))
                        : _filteredDrivers.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
                                children: [
                                  Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFFFF0E6),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.two_wheeler_rounded,
                                            size: 48,
                                            color: _orange,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          _searchCtrl.text.isNotEmpty
                                              ? 'No Drivers Match Search'
                                              : 'No Drivers Registered Yet',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: _ink,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _searchCtrl.text.isNotEmpty
                                              ? 'Try searching with a different driver name, phone or vehicle number.'
                                              : 'Add your delivery drivers so you can assign ready orders directly to them.',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 13, color: _grey, height: 1.4),
                                        ),
                                        const SizedBox(height: 24),
                                        if (_searchCtrl.text.isEmpty)
                                          ElevatedButton.icon(
                                            onPressed: () => _showAddDriverModal(context),
                                            icon: const Icon(Icons.add_rounded, color: Colors.white),
                                            label: const Text(
                                              'Register First Driver',
                                              style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: _orange,
                                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                                itemCount: _filteredDrivers.length,
                                itemBuilder: (context, index) {
                                  final driver = _filteredDrivers[index];
                                  return _buildExactDriverCard(driver);
                                },
                              ),
                  ),

                  // ── Floating Action Button (Exact Match) ────────────────────
                  Positioned(
                    bottom: 20,
                    right: 16,
                    child: GestureDetector(
                      onTap: () => _showAddDriverModal(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          color: _orange,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _orange.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add_rounded, color: _orange, size: 20),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Add Driver',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExactDriverCard(VendorDriver driver) {
    final isOnline = driver.isOnline;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Avatar Circle with Status Dot
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF0E5),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.two_wheeler_rounded, color: _orange, size: 28),
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: isOnline ? _green : _offlineGrey,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // Middle Driver Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name & Status Pill
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        driver.fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Status Pill (Exact Match)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isOnline ? const Color(0xFFE8F5E9) : const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isOnline ? _green : _offlineGrey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isOnline ? _green : _offlineGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Vehicle Number
                Row(
                  children: [
                    const Icon(Icons.badge_outlined, size: 14, color: _grey),
                    const SizedBox(width: 6),
                    Text(
                      'Vehicle: ${driver.vehicleNumber}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: _grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Phone Number
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 14, color: _grey),
                    const SizedBox(width: 6),
                    Text(
                      driver.phoneNumber,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: _grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                // Email Address
                if (driver.email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.mail_outline_rounded, size: 14, color: _grey),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          driver.email,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: _grey,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // WhatsApp Quick Button
          GestureDetector(
            onTap: () => _showSendDriverWhatsAppModal(context, driver),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.chat_rounded, color: _whatsappGreen, size: 18),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 3-dots Menu Button
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FA),
              shape: BoxShape.circle,
            ),
            child: PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.more_vert_rounded, color: _grey, size: 18),
              onSelected: (value) async {
                if (value == 'whatsapp_api') {
                  _showSendDriverWhatsAppModal(context, driver);
                } else if (value == 'whatsapp_app') {
                  final msg = 'Hello ${driver.fullName},\nMessage from ${_vendor?.fullName ?? "Vendor"}:';
                  _launchWhatsAppChat(
                    context: context,
                    phone: driver.phoneNumber,
                    message: msg,
                  );
                } else if (value == 'edit') {
                  // Option for edit
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'whatsapp_api',
                  child: Row(
                    children: const [
                      Icon(Icons.mark_chat_read_rounded, size: 18, color: _whatsappGreen),
                      SizedBox(width: 8),
                      Text('Send WhatsApp via Server API', style: TextStyle(fontSize: 13, color: _ink)),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'whatsapp_app',
                  child: Row(
                    children: const [
                      Icon(Icons.chat_bubble_outline_rounded, size: 18, color: _whatsappGreen),
                      SizedBox(width: 8),
                      Text('Chat on WhatsApp App', style: TextStyle(fontSize: 13, color: _ink)),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: const [
                      Icon(Icons.edit_outlined, size: 18, color: _ink),
                      SizedBox(width: 8),
                      Text('Edit Driver', style: TextStyle(fontSize: 13, color: _ink)),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: const [
                      Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Driver', style: TextStyle(fontSize: 13, color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
