import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/app_config.dart';
import '../services/auth_service.dart';
import '../services/razorpay_service.dart';

class PayUBankInfo {
  final String name;
  final String ifscPrefix;
  final String category;

  const PayUBankInfo({
    required this.name,
    required this.ifscPrefix,
    this.category = 'Bank',
  });
}

const List<PayUBankInfo> kPayUSupportedBanks = [
  PayUBankInfo(name: 'State Bank of India', ifscPrefix: 'SBIN', category: 'Public Sector'),
  PayUBankInfo(name: 'HDFC Bank', ifscPrefix: 'HDFC', category: 'Private Sector'),
  PayUBankInfo(name: 'ICICI Bank', ifscPrefix: 'ICIC', category: 'Private Sector'),
  PayUBankInfo(name: 'Axis Bank', ifscPrefix: 'UTIB', category: 'Private Sector'),
  PayUBankInfo(name: 'Punjab National Bank', ifscPrefix: 'PUNB', category: 'Public Sector'),
  PayUBankInfo(name: 'Bank of Baroda', ifscPrefix: 'BARB', category: 'Public Sector'),
  PayUBankInfo(name: 'Kotak Mahindra Bank', ifscPrefix: 'KKBK', category: 'Private Sector'),
  PayUBankInfo(name: 'IndusInd Bank', ifscPrefix: 'INDB', category: 'Private Sector'),
  PayUBankInfo(name: 'Canara Bank', ifscPrefix: 'CNRB', category: 'Public Sector'),
  PayUBankInfo(name: 'Union Bank of India', ifscPrefix: 'UBIN', category: 'Public Sector'),
  PayUBankInfo(name: 'Bank of India', ifscPrefix: 'BKID', category: 'Public Sector'),
  PayUBankInfo(name: 'Central Bank of India', ifscPrefix: 'CBIN', category: 'Public Sector'),
  PayUBankInfo(name: 'Indian Bank', ifscPrefix: 'IDIB', category: 'Public Sector'),
  PayUBankInfo(name: 'IDBI Bank', ifscPrefix: 'IBKL', category: 'Private Sector'),
  PayUBankInfo(name: 'Federal Bank', ifscPrefix: 'FDRL', category: 'Private Sector'),
  PayUBankInfo(name: 'YES Bank', ifscPrefix: 'YESB', category: 'Private Sector'),
  PayUBankInfo(name: 'Bandhan Bank', ifscPrefix: 'BAND', category: 'Private Sector'),
  PayUBankInfo(name: 'IDFC FIRST Bank', ifscPrefix: 'IDFB', category: 'Private Sector'),
  PayUBankInfo(name: 'AU Small Finance Bank', ifscPrefix: 'AUBL', category: 'Small Finance'),
  PayUBankInfo(name: 'Equitas Small Finance Bank', ifscPrefix: 'EQBL', category: 'Small Finance'),
  PayUBankInfo(name: 'Ujjivan Small Finance Bank', ifscPrefix: 'UJVN', category: 'Small Finance'),
  PayUBankInfo(name: 'Jana Small Finance Bank', ifscPrefix: 'JSFB', category: 'Small Finance'),
  PayUBankInfo(name: 'Paytm Payments Bank', ifscPrefix: 'PYTM', category: 'Payment Bank'),
  PayUBankInfo(name: 'Airtel Payments Bank', ifscPrefix: 'AIRP', category: 'Payment Bank'),
  PayUBankInfo(name: 'India Post Payments Bank', ifscPrefix: 'IPOS', category: 'Payment Bank'),
  PayUBankInfo(name: 'Fino Payments Bank', ifscPrefix: 'FINO', category: 'Payment Bank'),
  PayUBankInfo(name: 'Jio Payments Bank', ifscPrefix: 'JIOP', category: 'Payment Bank'),
  PayUBankInfo(name: 'Punjab & Sind Bank', ifscPrefix: 'PSIB', category: 'Public Sector'),
  PayUBankInfo(name: 'Indian Overseas Bank', ifscPrefix: 'IOBA', category: 'Public Sector'),
  PayUBankInfo(name: 'UCO Bank', ifscPrefix: 'UCBA', category: 'Public Sector'),
  PayUBankInfo(name: 'Bank of Maharashtra', ifscPrefix: 'MAHB', category: 'Public Sector'),
  PayUBankInfo(name: 'South Indian Bank', ifscPrefix: 'SIBL', category: 'Private Sector'),
  PayUBankInfo(name: 'Karur Vysya Bank', ifscPrefix: 'KVBL', category: 'Private Sector'),
  PayUBankInfo(name: 'RBL Bank', ifscPrefix: 'RATN', category: 'Private Sector'),
  PayUBankInfo(name: 'Jammu & Kashmir Bank', ifscPrefix: 'JAKA', category: 'Private Sector'),
  PayUBankInfo(name: 'Karnataka Bank', ifscPrefix: 'KARB', category: 'Private Sector'),
  PayUBankInfo(name: 'City Union Bank', ifscPrefix: 'CIUB', category: 'Private Sector'),
  PayUBankInfo(name: 'Tamilnad Mercantile Bank', ifscPrefix: 'TMBL', category: 'Private Sector'),
  PayUBankInfo(name: 'Standard Chartered Bank', ifscPrefix: 'SCBL', category: 'Foreign Bank'),
  PayUBankInfo(name: 'HSBC Bank', ifscPrefix: 'HSBC', category: 'Foreign Bank'),
  PayUBankInfo(name: 'Citibank', ifscPrefix: 'CITI', category: 'Foreign Bank'),
  PayUBankInfo(name: 'DBS Bank India', ifscPrefix: 'DBSS', category: 'Foreign Bank'),
  PayUBankInfo(name: 'Saraswat Co-operative Bank', ifscPrefix: 'SRCB', category: 'Co-operative'),
  PayUBankInfo(name: 'Cosmos Co-operative Bank', ifscPrefix: 'COSB', category: 'Co-operative'),
  PayUBankInfo(name: 'Abhyudaya Co-operative Bank', ifscPrefix: 'ABHY', category: 'Co-operative'),
  PayUBankInfo(name: 'SVC Co-operative Bank', ifscPrefix: 'SVCB', category: 'Co-operative'),
  PayUBankInfo(name: 'TJSB Sahakari Bank', ifscPrefix: 'TJSB', category: 'Co-operative'),
];

class BankDetailsScreen extends StatefulWidget {
  const BankDetailsScreen({super.key});

  @override
  State<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends State<BankDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _holderController = TextEditingController();
  final _bankController = TextEditingController();
  final _accountController = TextEditingController();
  final _ifscController = TextEditingController();
  final _bankFocusNode = FocusNode();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _payoutEnabled = false;

  String? _razorpayContactId;
  String? _razorpayFundAccountId;
  int? _lastLatencyMs;

  String? _ifscBranchDetails;
  bool _isCheckingIfsc = false;

  @override
  void initState() {
    super.initState();
    RazorpayService.warmup();
    _fetchBankDetails();
    _ifscController.addListener(_onIfscChanged);
  }

  @override
  void dispose() {
    _ifscController.removeListener(_onIfscChanged);
    _holderController.dispose();
    _bankController.dispose();
    _accountController.dispose();
    _ifscController.dispose();
    _bankFocusNode.dispose();
    super.dispose();
  }

  void _onIfscChanged() {
    final cleanIfsc = _ifscController.text.trim().toUpperCase();
    if (cleanIfsc.length == 11) {
      _lookupIfscDetails(cleanIfsc);
    } else {
      if (_ifscBranchDetails != null) {
        setState(() {
          _ifscBranchDetails = null;
        });
      }
    }
  }

  Future<void> _lookupIfscDetails(String ifsc) async {
    setState(() => _isCheckingIfsc = true);
    try {
      final res = await http
          .get(Uri.parse('https://ifsc.razorpay.com/$ifsc'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final data = jsonDecode(res.body);
        if (data is Map && data.containsKey('BANK')) {
          final bankName = data['BANK']?.toString() ?? '';
          final branch = data['BRANCH']?.toString() ?? '';
          final city = data['CITY']?.toString() ?? '';

          if (mounted) {
            setState(() {
              _isCheckingIfsc = false;
              if (bankName.isNotEmpty) {
                // Find matching bank in PayU supported banks if possible
                final match = kPayUSupportedBanks.firstWhere(
                  (b) => b.name.toLowerCase().contains(bankName.toLowerCase()) ||
                      bankName.toLowerCase().contains(b.name.toLowerCase()),
                  orElse: () => PayUBankInfo(name: bankName, ifscPrefix: ifsc.substring(0, 4)),
                );
                _bankController.text = match.name;
              }
              _ifscBranchDetails = '$branch, $city';
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('IFSC lookup network exception: $e');
    }

    // Fallback prefix match if online lookup fails
    if (ifsc.length >= 4) {
      final prefix = ifsc.substring(0, 4);
      final match = kPayUSupportedBanks.firstWhere(
        (b) => b.ifscPrefix == prefix,
        orElse: () => const PayUBankInfo(name: '', ifscPrefix: ''),
      );
      if (mounted) {
        setState(() {
          _isCheckingIfsc = false;
          if (match.name.isNotEmpty && _bankController.text.trim().isEmpty) {
            _bankController.text = match.name;
          }
        });
      }
    } else {
      if (mounted) {
        setState(() => _isCheckingIfsc = false);
      }
    }
  }

  Future<void> _fetchBankDetails() async {
    setState(() => _isLoading = true);
    try {
      final token = await AuthService.instance.getSavedToken();
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unauthorized. Please log in again.')),
          );
        }
        return;
      }

      final response = await http.get(
        Uri.parse('$kBaseUrl/get_bank_details'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final bank = data['data']['bank_details'] ?? {};
          _holderController.text = bank['account_holder_name'] ?? '';
          _bankController.text = bank['bank_name'] ?? '';
          final accLast4 = bank['account_last4'] ?? bank['account_number'] ?? '';
          _accountController.text = accLast4.isNotEmpty
              ? (accLast4.length <= 4 ? accLast4 : '•••• •••• ${accLast4.substring(accLast4.length - 4)}')
              : '';
          _ifscController.text = bank['ifsc_code'] ?? '';
          _payoutEnabled = bank['payout_enabled'] == true;
          _razorpayContactId = bank['razorpay_contact_id'] as String?;
          _razorpayFundAccountId = bank['razorpay_fund_account_id'] as String?;

          if (_ifscController.text.trim().length == 11) {
            _lookupIfscDetails(_ifscController.text.trim().toUpperCase());
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching bank details: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveBankDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final token = await AuthService.instance.getSavedToken();
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unauthorized. Please log in again.')),
          );
        }
        return;
      }

      // ── Optimized Millisecond Razorpay Fund Account Hit ─────────────
      String? contactId = _razorpayContactId;
      if (contactId == null || contactId.isEmpty) {
        final profile = await AuthService.instance.getSavedVendor();
        contactId = profile?.razorpayContactId;
      }

      String? createdFundAccountId;
      int? hitLatencyMs;

      if (contactId != null && contactId.isNotEmpty) {
        final rzpFund = await RazorpayService.createFundAccount(
          contactId: contactId,
          name: _holderController.text.trim(),
          ifsc: _ifscController.text.trim().toUpperCase(),
          accountNumber: _accountController.text.trim(),
        );
        if (rzpFund != null && rzpFund['id'] != null) {
          createdFundAccountId = rzpFund['id'] as String;
          hitLatencyMs = rzpFund['latency_ms'] as int?;
          _razorpayFundAccountId = createdFundAccountId;
          _lastLatencyMs = hitLatencyMs;
          debugPrint('⚡ Razorpay Fund Account ($createdFundAccountId) created in ${_lastLatencyMs}ms');
        }
      }

      final effectiveFundAccountId = createdFundAccountId ?? _razorpayFundAccountId;

      final payload = {
        'account_holder_name': _holderController.text.trim(),
        'bank_name': _bankController.text.trim(),
        'account_number': _accountController.text.trim(),
        'ifsc_code': _ifscController.text.trim().toUpperCase(),
        if (contactId != null && contactId.isNotEmpty)
          'razorpay_contact_id': contactId,
        if (effectiveFundAccountId != null && effectiveFundAccountId.isNotEmpty)
          'razorpay_fund_account_id': effectiveFundAccountId,
      };

      final response = await http.post(
        Uri.parse('$kBaseUrl/update_bank_details'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 12));

      if (response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Bank account details saved successfully!',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF059669),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                duration: const Duration(seconds: 3),
              ),
            );
            Navigator.pop(context);
          }
          return;
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'Failed to save bank details'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving bank details: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFD32F2F);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Bank Account Details',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF1F5F9), height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dynamic Bank Card Preview
                    AnimatedBuilder(
                      animation: Listenable.merge([
                        _holderController,
                        _bankController,
                        _accountController,
                        _ifscController,
                      ]),
                      builder: (context, _) => _buildVirtualBankCard(),
                    ),
                    const SizedBox(height: 20),

                    // Main Form Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.account_balance_rounded,
                                  color: primaryColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Settlement Account',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Enter details where daily payouts will be sent',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 20),

                          // Account Holder Name Field
                          _buildTextField(
                            controller: _holderController,
                            label: 'Account Holder Name',
                            hint: 'As registered in bank passbook',
                            icon: Icons.person_outline_rounded,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter account holder name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),

                          // Bank Name Autocomplete Field
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Bank Name',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 6),
                              RawAutocomplete<PayUBankInfo>(
                                textEditingController: _bankController,
                                focusNode: _bankFocusNode,
                                optionsBuilder: (TextEditingValue textEditingValue) {
                                  if (textEditingValue.text.isEmpty) {
                                    return kPayUSupportedBanks;
                                  }
                                  final query = textEditingValue.text.toLowerCase();
                                  return kPayUSupportedBanks.where((PayUBankInfo bank) {
                                    return bank.name.toLowerCase().contains(query) ||
                                        bank.ifscPrefix.toLowerCase().contains(query) ||
                                        bank.category.toLowerCase().contains(query);
                                  });
                                },
                                displayStringForOption: (PayUBankInfo option) => option.name,
                                onSelected: (PayUBankInfo selection) {
                                  _bankController.text = selection.name;
                                  if (_ifscController.text.trim().isEmpty) {
                                    _ifscController.text = selection.ifscPrefix;
                                    _ifscController.selection = TextSelection.fromPosition(
                                      TextPosition(offset: _ifscController.text.length),
                                    );
                                  }
                                },
                                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                  return TextFormField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Please select or enter bank name';
                                      }
                                      return null;
                                    },
                                    decoration: InputDecoration(
                                      hintText: 'Search or select bank (e.g. SBI, HDFC, ICICI)',
                                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
                                      prefixIcon: const Icon(Icons.account_balance_outlined, color: Color(0xFF64748B), size: 20),
                                      suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8), size: 22),
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: primaryColor, width: 1.6),
                                      ),
                                    ),
                                  );
                                },
                                optionsViewBuilder: (context, onSelected, options) {
                                  return Align(
                                    alignment: Alignment.topLeft,
                                    child: Material(
                                      elevation: 8,
                                      borderRadius: BorderRadius.circular(16),
                                      color: Colors.white,
                                      child: Container(
                                        width: MediaQuery.of(context).size.width - 40,
                                        constraints: const BoxConstraints(maxHeight: 280),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: const Color(0xFFE2E8F0)),
                                        ),
                                        child: ListView.separated(
                                          padding: const EdgeInsets.symmetric(vertical: 6),
                                          shrinkWrap: true,
                                          itemCount: options.length,
                                          separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                          itemBuilder: (BuildContext context, int index) {
                                            final PayUBankInfo option = options.elementAt(index);
                                            return ListTile(
                                              dense: true,
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                              leading: CircleAvatar(
                                                radius: 15,
                                                backgroundColor: const Color(0xFFF1F5F9),
                                                child: Text(
                                                  option.name[0],
                                                  style: const TextStyle(
                                                    color: Color(0xFF334155),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              title: Text(
                                                option.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                  color: Color(0xFF0F172A),
                                                ),
                                              ),
                                              subtitle: Text(
                                                'IFSC Prefix: ${option.ifscPrefix}',
                                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                              ),
                                              trailing: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF1F5F9),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  option.category,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF475569),
                                                  ),
                                                ),
                                              ),
                                              onTap: () => onSelected(option),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Account Number Field
                          _buildTextField(
                            controller: _accountController,
                            label: 'Account Number',
                            hint: 'Enter your bank account number',
                            icon: Icons.pin_outlined,
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter account number';
                              }
                              if (val.trim().length < 8) {
                                return 'Enter valid account number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),

                          // IFSC Code Field with Realtime Lookup
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'IFSC Code',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                  if (_isCheckingIfsc)
                                    const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _ifscController,
                                keyboardType: TextInputType.text,
                                textCapitalization: TextCapitalization.characters,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter IFSC code';
                                  }
                                  if (val.trim().length < 11) {
                                    return 'Enter valid 11-character IFSC code';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  hintText: 'e.g. SBIN0001234',
                                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
                                  prefixIcon: const Icon(Icons.qr_code_outlined, color: Color(0xFF64748B), size: 20),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: primaryColor, width: 1.6),
                                  ),
                                ),
                              ),
                              if (_ifscBranchDetails != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFA7F3D0)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Verified Branch: $_ifscBranchDetails',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF065F46),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Security Trust Banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock_outline_rounded,
                              color: Color(0xFF059669),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bank-Grade 256-bit Encryption',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Your bank details are encrypted and strictly used for weekly and daily earnings payouts.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveBankDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                          shadowColor: primaryColor.withValues(alpha: 0.35),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline_rounded, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Save Bank Details',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildVirtualBankCard() {
    final bankName = _bankController.text.trim();
    final holderName = _holderController.text.trim();
    final ifsc = _ifscController.text.trim().toUpperCase();
    final accountDisplay = _formatDisplayAccount(_accountController.text.trim());
    final isAccountActive = _payoutEnabled || (_razorpayFundAccountId != null && _razorpayFundAccountId!.isNotEmpty);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.account_balance_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Text(
                      bankName.isNotEmpty ? bankName.toUpperCase() : 'SETTLEMENT BANK',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.shield_rounded,
                      color: Color(0xFF34D399),
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isAccountActive ? 'Active for Payouts' : 'Instant Payouts',
                      style: const TextStyle(
                        color: Color(0xFF34D399),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            accountDisplay,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.2,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ACCOUNT HOLDER',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      holderName.isNotEmpty ? holderName.toUpperCase() : 'YOUR FULL NAME',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'IFSC CODE',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ifsc.isNotEmpty ? ifsc : '•••••••••••',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDisplayAccount(String raw) {
    if (raw.isEmpty) {
      return '••••  ••••  ••••  ••••';
    }
    if (raw.contains('•')) {
      return raw;
    }
    if (raw.length <= 4) {
      return '••••  ••••  ••••  $raw';
    }
    final last4 = raw.substring(raw.length - 4);
    return '••••  ••••  ••••  $last4';
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.words,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
            prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.6),
            ),
          ),
        ),
      ],
    );
  }
}
