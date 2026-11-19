// lib/screens/add_hotel_screen.dart
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';
import '../services/hotel_service.dart';
import '../models/hotel.dart';
import 'select_location_screen.dart';
import 'home_shell.dart';
import '../utils/location_data.dart';

class AddHotelScreen extends StatefulWidget {
  final Hotel? hotel;

  const AddHotelScreen({super.key, this.hotel});

  @override
  State<AddHotelScreen> createState() => _AddHotelScreenState();
}

class _AddHotelScreenState extends State<AddHotelScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _ownerCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _hotelNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _fssaiNoCtrl = TextEditingController();
  final _panNoCtrl = TextEditingController();
  final _aadharNoCtrl = TextEditingController();
  final _shopActNoCtrl = TextEditingController();
  final _udyamAadharNoCtrl = TextEditingController();
  final _gstNoCtrl = TextEditingController();

  Uint8List? _imageBytes;
  File? _imageFile;

  // Documents (Photos)
  Uint8List? _fssaiImageBytes; File? _fssaiImageFile;
  Uint8List? _panImageBytes; File? _panImageFile;
  Uint8List? _aadharImageBytes; File? _aadharImageFile;
  Uint8List? _shopActImageBytes; File? _shopActImageFile;
  Uint8List? _udyamImageBytes; File? _udyamImageFile;
  Uint8List? _gstImageBytes; File? _gstImageFile;

  final _picker = ImagePicker();

  LatLng? _currentLocation;
  bool _isSubmitting = false;
  int _currentStep = 0; // 0: Hotel Info & Location, 1: Property Photo
  String _serviceType = 'BOTH'; // 'DINING', 'DELIVERY', 'BOTH'
  String _foodType = 'BOTH'; // 'VEG', 'NON_VEG', 'BOTH'

  String? _placeId, _city, _area, _state, _country, _pincode, _landmark, _hotelAddress;

  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;

  bool get _isEdit => widget.hotel != null;

  // Design Tokens matching reference design photo exactly
  static const Color _brandOrange  = Color(0xFFF58220);
  static const Color _gradientEnd  = Color(0xFFE65100);
  static const Color _bgWarm       = Color(0xFFFAF8F5);
  static const Color _white        = Colors.white;
  static const Color _ink          = Color(0xFF1A1A2E);
  static const Color _greySub      = Color(0xFF8A8FA8);
  static const Color _greyHint     = Color(0xFFA0A5BA);
  static const Color _cardBorder   = Color(0xFFEEEEEE);

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeInOut);
    _entryCtrl.forward();

    if (widget.hotel != null) {
      final h = widget.hotel!;
      _ownerCtrl.text = h.ownerName;
      _mobileCtrl.text = h.mobileNumber;
      _emailCtrl.text = h.email;
      _hotelNameCtrl.text = h.hotelName;
      _addressCtrl.text = h.hotelAddress;
      _fssaiNoCtrl.text = h.fssaiNumber ?? '';
      _panNoCtrl.text = h.panNumber ?? '';
      _aadharNoCtrl.text = h.aadharNumber ?? '';
      _shopActNoCtrl.text = h.shopActNumber ?? '';
      _udyamAadharNoCtrl.text = h.udyamAadharNumber ?? '';
      _gstNoCtrl.text = h.gstNumber ?? '';
      _serviceType = h.serviceType.isNotEmpty ? h.serviceType : 'BOTH';
      _foodType = h.foodType.toUpperCase() == 'VEG' ? 'VEG' : 'BOTH';
      _hotelAddress = h.hotelAddress;
      _currentLocation = LatLng(h.latitude, h.longitude);
      _placeId = h.placeId;
      _city = h.city;
      _area = h.area;
      _state = h.state;
      _country = h.country;
      _pincode = h.pincode;
      _landmark = h.landmark;
    }
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _ownerCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    _hotelNameCtrl.dispose();
    _addressCtrl.dispose();
    _fssaiNoCtrl.dispose();
    _panNoCtrl.dispose();
    _aadharNoCtrl.dispose();
    _shopActNoCtrl.dispose();
    _udyamAadharNoCtrl.dispose();
    _gstNoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked =
          await _picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        final ext = picked.name.split('.').last.toLowerCase();
        if (ext != 'jpg' && ext != 'jpeg' && ext != 'png') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: const [
                    Icon(Icons.warning_amber_rounded, color: Colors.white),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Invalid format! Only JPG, JPEG, and PNG images are allowed.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.red.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
                duration: const Duration(seconds: 4),
              ),
            );
          }
          return;
        }

        final bytes = await picked.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageFile = kIsWeb ? null : File(picked.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _pickFssaiImage(ImageSource source) async {
    try {
      final picked =
          await _picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        final ext = picked.name.split('.').last.toLowerCase();
        if (ext != 'jpg' && ext != 'jpeg' && ext != 'png') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Invalid format! Only JPG, JPEG, and PNG images are allowed.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                backgroundColor: Colors.red.shade600,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }

        final bytes = await picked.readAsBytes();
        setState(() {
          _fssaiImageBytes = bytes;
          _fssaiImageFile = kIsWeb ? null : File(picked.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking FSSAI image: $e')),
        );
      }
    }
  }

  Future<void> _pickPanImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _panImageBytes = bytes;
          _panImageFile = kIsWeb ? null : File(picked.path);
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking PAN photo: $e')));
    }
  }

  Future<void> _pickAadharImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _aadharImageBytes = bytes;
          _aadharImageFile = kIsWeb ? null : File(picked.path);
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking Aadhaar photo: $e')));
    }
  }

  Future<void> _pickShopActImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _shopActImageBytes = bytes;
          _shopActImageFile = kIsWeb ? null : File(picked.path);
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking Shop Act photo: $e')));
    }
  }

  Future<void> _pickUdyamImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _udyamImageBytes = bytes;
          _udyamImageFile = kIsWeb ? null : File(picked.path);
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking Udyam Aadhaar photo: $e')));
    }
  }

  Future<void> _pickGstImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _gstImageBytes = bytes;
          _gstImageFile = kIsWeb ? null : File(picked.path);
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking GST photo: $e')));
    }
  }

  void _proceedToStep2() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select your mess location on the map'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _currentStep = 1);
    _entryCtrl.reset();
    _entryCtrl.forward();
  }

  Future<void> _handleSubmit() async {
    if (!mounted) return;

    // Validation: PAN Card Photo and Aadhaar Card Photo are Mandatory
    final hasPanPhoto = _panImageBytes != null || _panImageFile != null || (widget.hotel?.panPhotoUrl != null && widget.hotel!.panPhotoUrl!.isNotEmpty);
    if (!hasPanPhoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('PAN Card Photo is mandatory. Please upload your PAN card photo.'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final hasAadharPhoto = _aadharImageBytes != null || _aadharImageFile != null || (widget.hotel?.aadharPhotoUrl != null && widget.hotel!.aadharPhotoUrl!.isNotEmpty);
    if (!hasAadharPhoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Aadhaar Card Photo is mandatory. Please upload your Aadhaar card photo.'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    String? photoUrl;
    String? fssaiPhotoUrl;
    String? panPhotoUrl;
    String? aadharPhotoUrl;
    String? shopActPhotoUrl;
    String? udyamAadharPhotoUrl;
    String? gstPhotoUrl;

    try {
      if (_imageBytes != null) {
        photoUrl = await CloudinaryService.uploadImageBytes(_imageBytes!, filename: 'hotel_photo.jpg');
      } else if (_imageFile != null) {
        photoUrl = await CloudinaryService.uploadImage(_imageFile!);
      }

      if (_panImageBytes != null) {
        panPhotoUrl = await CloudinaryService.uploadImageBytes(_panImageBytes!, filename: 'pan_photo.jpg');
      } else if (_panImageFile != null) {
        panPhotoUrl = await CloudinaryService.uploadImage(_panImageFile!);
      }

      if (_aadharImageBytes != null) {
        aadharPhotoUrl = await CloudinaryService.uploadImageBytes(_aadharImageBytes!, filename: 'aadhar_photo.jpg');
      } else if (_aadharImageFile != null) {
        aadharPhotoUrl = await CloudinaryService.uploadImage(_aadharImageFile!);
      }

      if (_fssaiImageBytes != null) {
        fssaiPhotoUrl = await CloudinaryService.uploadImageBytes(_fssaiImageBytes!, filename: 'fssai_photo.jpg');
      } else if (_fssaiImageFile != null) {
        fssaiPhotoUrl = await CloudinaryService.uploadImage(_fssaiImageFile!);
      }

      if (_shopActImageBytes != null) {
        shopActPhotoUrl = await CloudinaryService.uploadImageBytes(_shopActImageBytes!, filename: 'shop_act_photo.jpg');
      } else if (_shopActImageFile != null) {
        shopActPhotoUrl = await CloudinaryService.uploadImage(_shopActImageFile!);
      }

      if (_udyamImageBytes != null) {
        udyamAadharPhotoUrl = await CloudinaryService.uploadImageBytes(_udyamImageBytes!, filename: 'udyam_photo.jpg');
      } else if (_udyamImageFile != null) {
        udyamAadharPhotoUrl = await CloudinaryService.uploadImage(_udyamImageFile!);
      }

      if (_gstImageBytes != null) {
        gstPhotoUrl = await CloudinaryService.uploadImageBytes(_gstImageBytes!, filename: 'gst_photo.jpg');
      } else if (_gstImageFile != null) {
        gstPhotoUrl = await CloudinaryService.uploadImage(_gstImageFile!);
      }
    } catch (e) {
      print('Cloudinary upload error: $e');
    }

    if (!mounted) return;
    await _submitData(
      photoUrl: photoUrl,
      fssaiPhotoUrl: fssaiPhotoUrl,
      panPhotoUrl: panPhotoUrl,
      aadharPhotoUrl: aadharPhotoUrl,
      shopActPhotoUrl: shopActPhotoUrl,
      udyamAadharPhotoUrl: udyamAadharPhotoUrl,
      gstPhotoUrl: gstPhotoUrl,
    );
  }

  Future<void> _submitData({
    String? photoUrl,
    String? fssaiPhotoUrl,
    String? panPhotoUrl,
    String? aadharPhotoUrl,
    String? shopActPhotoUrl,
    String? udyamAadharPhotoUrl,
    String? gstPhotoUrl,
  }) async {
    final HotelResult res;
    final fssaiNo = _fssaiNoCtrl.text.trim();
    final panNo = _panNoCtrl.text.trim();
    final aadharNo = _aadharNoCtrl.text.trim();
    final shopActNo = _shopActNoCtrl.text.trim();
    final udyamNo = _udyamAadharNoCtrl.text.trim();
    final gstNo = _gstNoCtrl.text.trim();

    if (_isEdit) {
      res = await HotelService.instance.editHotel(
        id: widget.hotel!.id,
        ownerName: _ownerCtrl.text,
        mobileNumber: _mobileCtrl.text,
        email: _emailCtrl.text,
        hotelName: _hotelNameCtrl.text,
        hotelAddress: _hotelAddress ?? _addressCtrl.text,
        latitude: _currentLocation!.latitude,
        longitude: _currentLocation!.longitude,
        placeId: _placeId,
        city: _city,
        area: _area,
        state: _state,
        country: _country,
        pincode: _pincode,
        landmark: _landmark,
        photoUrl: photoUrl,
        fssaiNumber: fssaiNo.isNotEmpty ? fssaiNo : null,
        fssaiPhotoUrl: fssaiPhotoUrl,
        panNumber: panNo.isNotEmpty ? panNo : null,
        panPhotoUrl: panPhotoUrl,
        aadharNumber: aadharNo.isNotEmpty ? aadharNo : null,
        aadharPhotoUrl: aadharPhotoUrl,
        shopActNumber: shopActNo.isNotEmpty ? shopActNo : null,
        shopActPhotoUrl: shopActPhotoUrl,
        udyamAadharNumber: udyamNo.isNotEmpty ? udyamNo : null,
        udyamAadharPhotoUrl: udyamAadharPhotoUrl,
        gstNumber: gstNo.isNotEmpty ? gstNo : null,
        gstPhotoUrl: gstPhotoUrl,
        serviceType: _serviceType,
        foodType: _foodType,
      );
    } else {
      res = await HotelService.instance.addHotel(
        ownerName: _ownerCtrl.text,
        mobileNumber: _mobileCtrl.text,
        email: _emailCtrl.text,
        hotelName: _hotelNameCtrl.text,
        hotelAddress: _hotelAddress ?? _addressCtrl.text,
        latitude: _currentLocation!.latitude,
        longitude: _currentLocation!.longitude,
        placeId: _placeId,
        city: _city,
        area: _area,
        state: _state,
        country: _country,
        pincode: _pincode,
        landmark: _landmark,
        photoUrl: photoUrl,
        fssaiNumber: fssaiNo.isNotEmpty ? fssaiNo : null,
        fssaiPhotoUrl: fssaiPhotoUrl,
        panNumber: panNo.isNotEmpty ? panNo : null,
        panPhotoUrl: panPhotoUrl,
        aadharNumber: aadharNo.isNotEmpty ? aadharNo : null,
        aadharPhotoUrl: aadharPhotoUrl,
        shopActNumber: shopActNo.isNotEmpty ? shopActNo : null,
        shopActPhotoUrl: shopActPhotoUrl,
        udyamAadharNumber: udyamNo.isNotEmpty ? udyamNo : null,
        udyamAadharPhotoUrl: udyamAadharPhotoUrl,
        gstNumber: gstNo.isNotEmpty ? gstNo : null,
        gstPhotoUrl: gstPhotoUrl,
        serviceType: _serviceType,
        foodType: _foodType,
      );
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (res.success) {
      SystemSound.play(SystemSoundType.alert);
      await _showSuccessDialog();
    } else {
      _showErrorDialog(res.message);
    }
  }

  Future<void> _showSuccessDialog() async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (_, __, ___) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.82,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF28A745), Color(0xFF1B5E20)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF28A745).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 22),
                Text(
                  _isEdit ? 'Updated!' : 'Registered!',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800, color: _ink),
                ),
                const SizedBox(height: 10),
                Text(
                  _isEdit
                      ? '${_hotelNameCtrl.text} has been successfully updated.'
                      : '${_hotelNameCtrl.text} has been successfully listed.',
                  style: const TextStyle(fontSize: 14, color: _greySub),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
      transitionBuilder: (_, anim, __, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
        child: FadeTransition(opacity: anim, child: child),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        Navigator.pop(context); // close dialog
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeShell()),
          (route) => false,
        ); // redirect to dashboard
      }
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Submission Failed',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(message, style: const TextStyle(color: _greySub)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK',
                style: TextStyle(color: _brandOrange, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgWarm,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: _currentStep == 0 ? _buildStep1Info(context) : _buildStep2Photo(context),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STEP 1: Hotel Information & Location
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildStep1Info(BuildContext context) {
    return Column(
      children: [
        // Top Header bar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, color: _ink, size: 28),
                onPressed: () => Navigator.maybePop(context),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    _isEdit ? 'Edit Mess' : 'Register Mess',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 48), // balance back button space
            ],
          ),
        ),

        // Scrollable Form Body
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    // ── Section 1: Mess Information ─────────────────────────
                    _buildSectionHeader(
                      icon: Icons.domain_rounded,
                      title: 'Mess Information',
                      subtitle: 'Basic details about your property',
                    ),
                    const SizedBox(height: 20),

                    // Mess Name
                    _buildCustomTextField(
                      controller: _hotelNameCtrl,
                      label: 'Mess Name *',
                      hint: 'E.g. Grand Mess',
                      icon: Icons.hotel_rounded,
                      textInputAction: TextInputAction.next,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Mess name is required'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Owner Name
                    _buildCustomTextField(
                      controller: _ownerCtrl,
                      label: 'Owner Name *',
                      hint: 'E.g. Jane Doe',
                      icon: Icons.person_rounded,
                      textInputAction: TextInputAction.next,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Owner name is required'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Mobile Number
                    _buildCustomTextField(
                      controller: _mobileCtrl,
                      label: 'Mobile Number *',
                      hint: '+91 9876543210',
                      icon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Mobile number is required'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Mess Email
                    _buildCustomTextField(
                      controller: _emailCtrl,
                      label: 'Mess Email *',
                      hint: 'info@grandmess.com',
                      icon: Icons.email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email is required';
                        if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$')
                            .hasMatch(v.trim())) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // ── Service Type / Order Mode Section ─────────────────────
                    _buildSectionHeader(
                      icon: Icons.storefront_rounded,
                      title: 'Service Type / Order Mode *',
                      subtitle: 'Select service options offered by this mess',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildServiceTypeCard('DINING', 'Dining', Icons.restaurant_rounded),
                        const SizedBox(width: 10),
                        _buildServiceTypeCard('DELIVERY', 'Delivery', Icons.delivery_dining_rounded),
                        const SizedBox(width: 10),
                        _buildServiceTypeCard('BOTH', 'Both', Icons.two_wheeler_rounded),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Food Category (Veg / Veg & Non-Veg) Section ───────────────
                    _buildSectionHeader(
                      icon: Icons.restaurant_menu_rounded,
                      title: 'Food Category *',
                      subtitle: 'Specify if your mess offers Pure Veg or Veg & Non-Veg',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildFoodTypeCard('VEG', 'Pure Veg', Icons.eco_rounded, const Color(0xFF2E7D32)),
                        const SizedBox(width: 12),
                        _buildFoodTypeCard('BOTH', 'Veg & Non-Veg', Icons.set_meal_rounded, _brandOrange),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Mandatory Identity Documents Section ─────────────────
                    _buildSectionHeader(
                      icon: Icons.verified_user_rounded,
                      title: 'Mandatory Identity Documents',
                      subtitle: 'PAN and Aadhaar details are required',
                    ),
                    const SizedBox(height: 16),

                    // PAN Card Number (Mandatory)
                    _buildCustomTextField(
                      controller: _panNoCtrl,
                      label: 'PAN Card Number *',
                      hint: 'E.g. ABCDE1234F',
                      icon: Icons.credit_card_rounded,
                      textInputAction: TextInputAction.next,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'PAN Card number is required'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Aadhaar Card Number (Mandatory)
                    _buildCustomTextField(
                      controller: _aadharNoCtrl,
                      label: 'Aadhaar Card Number *',
                      hint: 'E.g. 1234 5678 9012',
                      icon: Icons.fingerprint_rounded,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Aadhaar Card number is required'
                          : null,
                    ),
                    const SizedBox(height: 24),

                    // ── Optional Business Documents Section ───────────────────
                    _buildSectionHeader(
                      icon: Icons.assignment_turned_in_rounded,
                      title: 'Optional Business Documents',
                      subtitle: 'Additional licenses (GST, FSSAI, Shop Act, Udyam)',
                    ),
                    const SizedBox(height: 16),

                    // GST Number
                    _buildCustomTextField(
                      controller: _gstNoCtrl,
                      label: 'GST Number (Optional)',
                      hint: 'E.g. 27AAAAA0000A1Z5',
                      icon: Icons.receipt_long_rounded,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // FSSAI License No
                    _buildCustomTextField(
                      controller: _fssaiNoCtrl,
                      label: 'FSSAI License No. (Optional)',
                      hint: 'E.g. 12345678901234',
                      icon: Icons.badge_rounded,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Shop Act License No
                    _buildCustomTextField(
                      controller: _shopActNoCtrl,
                      label: 'Shop Act License No. (Optional)',
                      hint: 'E.g. MH-12-0012345',
                      icon: Icons.store_rounded,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Udyam Aadhaar No
                    _buildCustomTextField(
                      controller: _udyamAadharNoCtrl,
                      label: 'Udyam Aadhaar No. (Optional)',
                      hint: 'E.g. UDYAM-MH-00-1234567',
                      icon: Icons.business_center_rounded,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 28),

                    // ── Dashed Orange Divider with Location Pin Badge ────────
                    _buildDashedDividerWithBadge(),

                    const SizedBox(height: 28),

                    // ── Section 2: Location ──────────────────────────────────
                    _buildSectionHeader(
                      icon: Icons.location_on_rounded,
                      title: 'Location',
                      subtitle: 'Select your property on the map',
                    ),
                    const SizedBox(height: 16),

                    // Address Field Label
                    const Text(
                      'Address *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Interactive Map Preview Card
                    _buildMapCard(context),

                    const SizedBox(height: 32),

                    // Continue Button
                    _buildGradientButton(
                      label: 'Continue',
                      icon: Icons.check_circle_rounded,
                      onPressed: _proceedToStep2,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STEP 2: Property Photo
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildStep2Photo(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
                  // ── Top Header Banner with Hotel Illustration ─────────────
                  Stack(
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.none,
                    children: [
                      // Warm background header banner
                      Container(
                        width: double.infinity,
                        height: 220,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFFFFE8D6),
                              Color(0xFFFFF4EC),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 20),
                            child: Image.asset(
                              'assets/images/hotel_illustration.png',
                              fit: BoxFit.contain,
                              errorBuilder: (ctx, _, __) => const Icon(
                                Icons.hotel_rounded,
                                size: 100,
                                color: Color(0xFFF58220),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Top Left Back Button
                      Positioned(
                        top: 12,
                        left: 12,
                        child: GestureDetector(
                          onTap: () => setState(() => _currentStep = 0),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _white.withOpacity(0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.chevron_left_rounded,
                                color: _ink, size: 26),
                          ),
                        ),
                      ),

                      // Floating Camera Badge overlapping banner & white card
                      Positioned(
                        bottom: -36,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_brandOrange, _gradientEnd],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: _white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: _brandOrange.withOpacity(0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: const [
                              Icon(Icons.camera_alt_rounded,
                                  color: _white, size: 34),
                              Positioned(
                                top: 16,
                                right: 16,
                                child: Icon(Icons.add_rounded,
                                    color: _white, size: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 52),

                  // ── Title & Subtitle ────────────────────────────────────────
                  const Text(
                    'Property Photo',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Upload a photo to attract more guests',
                    style: TextStyle(
                      fontSize: 13,
                      color: _greySub,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Dashed Upload Container ─────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: CustomPaint(
                      painter: const DashedContainerPainter(
                        color: Color(0xFFFFD1B3),
                        strokeWidth: 1.8,
                        radius: 24,
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBF8),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: _imageBytes != null || _imageFile != null || (widget.hotel?.photoUrl != null && widget.hotel!.photoUrl!.isNotEmpty)
                            ? _buildImagePreview()
                            : _buildUploadPlaceholder(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Mandatory Identity Document Photos (PAN & Aadhaar) ─────
                  _buildDocumentUploadCard(
                    title: 'PAN Card Photo',
                    subtitle: 'Upload clear photo of PAN card',
                    isMandatory: true,
                    imageBytes: _panImageBytes,
                    imageFile: _panImageFile,
                    networkUrl: widget.hotel?.panPhotoUrl,
                    onPick: () => _pickPanImage(ImageSource.gallery),
                    accentColor: Colors.orange.shade700,
                    icon: Icons.credit_card_rounded,
                  ),

                  const SizedBox(height: 20),

                  _buildDocumentUploadCard(
                    title: 'Aadhaar Card Photo',
                    subtitle: 'Upload clear photo of Aadhaar card',
                    isMandatory: true,
                    imageBytes: _aadharImageBytes,
                    imageFile: _aadharImageFile,
                    networkUrl: widget.hotel?.aadharPhotoUrl,
                    onPick: () => _pickAadharImage(ImageSource.gallery),
                    accentColor: Colors.orange.shade700,
                    icon: Icons.fingerprint_rounded,
                  ),

                  const SizedBox(height: 28),

                  // ── Optional Document Photos (GST, FSSAI, Shop Act, Udyam) ──
                  _buildDocumentUploadCard(
                    title: 'GST Certificate Photo',
                    subtitle: 'Upload photo of GST certificate',
                    isMandatory: false,
                    imageBytes: _gstImageBytes,
                    imageFile: _gstImageFile,
                    networkUrl: widget.hotel?.gstPhotoUrl,
                    onPick: () => _pickGstImage(ImageSource.gallery),
                    accentColor: Colors.indigo.shade400,
                    icon: Icons.receipt_long_rounded,
                  ),

                  const SizedBox(height: 20),

                  _buildDocumentUploadCard(
                    title: 'FSSAI License Photo',
                    subtitle: 'Upload photo of FSSAI certificate',
                    isMandatory: false,
                    imageBytes: _fssaiImageBytes,
                    imageFile: _fssaiImageFile,
                    networkUrl: widget.hotel?.fssaiPhotoUrl,
                    onPick: () => _pickFssaiImage(ImageSource.gallery),
                    accentColor: Colors.indigo.shade400,
                    icon: Icons.badge_rounded,
                  ),

                  const SizedBox(height: 20),

                  _buildDocumentUploadCard(
                    title: 'Shop Act License Photo',
                    subtitle: 'Upload photo of Shop Act license',
                    isMandatory: false,
                    imageBytes: _shopActImageBytes,
                    imageFile: _shopActImageFile,
                    networkUrl: widget.hotel?.shopActPhotoUrl,
                    onPick: () => _pickShopActImage(ImageSource.gallery),
                    accentColor: Colors.indigo.shade400,
                    icon: Icons.store_rounded,
                  ),

                  const SizedBox(height: 20),

                  _buildDocumentUploadCard(
                    title: 'Udyam Aadhaar Photo',
                    subtitle: 'Upload photo of Udyam certificate',
                    isMandatory: false,
                    imageBytes: _udyamImageBytes,
                    imageFile: _udyamImageFile,
                    networkUrl: widget.hotel?.udyamAadharPhotoUrl,
                    onPick: () => _pickUdyamImage(ImageSource.gallery),
                    accentColor: Colors.indigo.shade400,
                    icon: Icons.business_center_rounded,
                  ),

                  const SizedBox(height: 24),

                  // ── Tip Section ─────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('💡', style: TextStyle(fontSize: 18)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Tip: A clear and attractive photo helps your property stand out and get more bookings.',
                            style: TextStyle(
                              fontSize: 12,
                              color: _greySub,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Register Property Button ───────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildGradientButton(
                      label: _isEdit ? 'Save Changes' : 'Register Property',
                      icon: Icons.check_circle_rounded,
                      isLoading: _isSubmitting,
                      onPressed: _isSubmitting ? null : _handleSubmit,
                    ),
                  ),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          );
  }

  // ── Helper UI Components ───────────────────────────────────────────────────

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _brandOrange,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _brandOrange.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: _white, size: 22),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _brandOrange,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: _greySub,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
        const SizedBox(height: 8),
        FormField<String>(
          validator: validator != null ? (_) => validator(controller.text) : null,
          builder: (state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: _white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: state.hasError ? const Color(0xFFE53935) : _cardBorder,
                      width: state.hasError ? 1.5 : 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: controller,
                    keyboardType: keyboardType,
                    textInputAction: textInputAction,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: _ink,
                    ),
                    onChanged: (val) {
                      state.didChange(val);
                    },
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        color: _greyHint,
                        fontWeight: FontWeight.w400,
                      ),
                      prefixIcon: Icon(icon, color: _brandOrange, size: 22),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 46,
                        minHeight: 46,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                    ),
                  ),
                ),
                if (state.hasError && state.errorText != null) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      state.errorText!,
                      style: const TextStyle(
                        color: Color(0xFFE53935),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildDashedDividerWithBadge() {
    return Row(
      children: [
        const Expanded(
          child: CustomPaint(
            painter: DashedLinePainter(color: Color(0xFFFFD1B3)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0E6),
              shape: BoxShape.circle,
              border: Border.all(color: _brandOrange.withOpacity(0.3), width: 1.5),
            ),
            child: const Icon(Icons.location_on_rounded,
                color: _brandOrange, size: 16),
          ),
        ),
        const Expanded(
          child: CustomPaint(
            painter: DashedLinePainter(color: Color(0xFFFFD1B3)),
          ),
        ),
      ],
    );
  }

  Widget _buildMapCard(BuildContext context) {
    final hasLoc = _currentLocation != null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Map graphic header
          GestureDetector(
            onTap: _selectLocation,
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
                color: Color(0xFFE8F1F5),
              ),
              child: Stack(
                alignment: Alignment.center,
                fit: StackFit.expand,
                children: [
                  // Vector map style graphic pattern background
                  CustomPaint(
                    painter: MapGraphicPainter(),
                  ),

                  // Center Pin Marker
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _brandOrange,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _brandOrange.withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: _white,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Address info & Action Button
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                if (hasLoc && _addressCtrl.text.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _addressCtrl.text,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                GestureDetector(
                  onTap: _selectLocation,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0E6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.gps_fixed_rounded,
                            color: _brandOrange, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Tap to select on map',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: _brandOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (hasLoc) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _cardBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.place_outlined, size: 16, color: _brandOrange),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  (_area != null && _area!.isNotEmpty) ? 'Area: $_area' : 'No area set',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: (_area != null && _area!.isNotEmpty) ? _ink : _greySub,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _pickHotelArea,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0E6),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _brandOrange.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.search_rounded, size: 14, color: _brandOrange),
                              SizedBox(width: 4),
                              Text(
                                'Set Area',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: _brandOrange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox.shrink(),
                if (false)
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    child: Row(
                      children: const [
                        Text(
                          'legacy',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
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
    );
  }

  Widget _buildDocumentUploadCard({
    required String title,
    required String subtitle,
    required bool isMandatory,
    required Uint8List? imageBytes,
    required File? imageFile,
    required String? networkUrl,
    required VoidCallback onPick,
    required Color accentColor,
    required IconData icon,
  }) {
    final hasPhoto = imageBytes != null || imageFile != null || (networkUrl != null && networkUrl.isNotEmpty);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              isMandatory ? '*' : '(Optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isMandatory ? const Color(0xFFE65100) : _greySub,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: _greySub,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: CustomPaint(
            painter: DashedContainerPainter(
              color: isMandatory ? const Color(0xFFFFB74D) : const Color(0xFFC7D2FE),
              strokeWidth: 1.8,
              radius: 18,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isMandatory ? const Color(0xFFFFFBF5) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
              ),
              child: hasPhoto
                  ? Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: imageBytes != null
                              ? Image.memory(imageBytes, width: 54, height: 54, fit: BoxFit.cover)
                              : imageFile != null
                                  ? Image.file(imageFile, width: 54, height: 54, fit: BoxFit.cover)
                                  : Image.network(networkUrl!, width: 54, height: 54, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$title Attached',
                                  style: const TextStyle(fontWeight: FontWeight.w700, color: _ink, fontSize: 13)),
                              const Text('Tap change to update photo', style: TextStyle(color: _greySub, fontSize: 11)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: onPick,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Text(
                              'Change',
                              style: TextStyle(
                                color: _brandOrange,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isMandatory ? const Color(0xFFFFF0E6) : const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, color: accentColor, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: _ink,
                                ),
                              ),
                              Text(
                                isMandatory ? 'Mandatory photo' : 'Optional photo',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isMandatory ? const Color(0xFFE65100) : _greySub,
                                  fontWeight: isMandatory ? FontWeight.w600 : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: onPick,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isMandatory ? _brandOrange : const Color(0xFFFFF0E6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.upload_file_rounded,
                                  size: 18,
                                  color: isMandatory ? _white : _brandOrange,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Choose',
                                  style: TextStyle(
                                    color: isMandatory ? _white : _brandOrange,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
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
      ],
    );
  }

  Widget _buildUploadPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 12),
        // Cloud upload icon with sparkles graphic
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0E6),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _brandOrange.withOpacity(0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.cloud_upload_rounded,
                color: _brandOrange,
                size: 46,
              ),
            ),
            const Positioned(
              top: -4,
              right: -4,
              child: Text('✨', style: TextStyle(fontSize: 16)),
            ),
            const Positioned(
              bottom: 4,
              left: -6,
              child: Text('✨', style: TextStyle(fontSize: 14)),
            ),
          ],
        ),

        const SizedBox(height: 20),
        const Text(
          'Upload Hotel Photo',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Tap to choose from camera or gallery',
          style: TextStyle(
            fontSize: 12.5,
            color: _greySub,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 24),

        // Action Pills Container
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPickPill(
                icon: Icons.camera_alt_rounded,
                label: 'Camera',
                onTap: () => _pickImage(ImageSource.camera),
              ),
              Container(
                height: 24,
                width: 1,
                color: const Color(0xFFEEEEEE),
                margin: const EdgeInsets.symmetric(horizontal: 14),
              ),
              _buildPickPill(
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                onTap: () => _pickImage(ImageSource.gallery),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildPickPill({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _brandOrange, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildImagePreview() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: _imageBytes != null
                ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                : (_imageFile != null
                    ? Image.file(_imageFile!, fit: BoxFit.cover)
                    : Image.network(widget.hotel!.photoUrl!, fit: BoxFit.cover)),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => _pickImage(ImageSource.gallery),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _brandOrange, width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.edit_rounded, size: 16, color: _brandOrange),
                    SizedBox(width: 8),
                    Text(
                      'Change Photo',
                      style: TextStyle(
                        color: _brandOrange,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_imageBytes != null || _imageFile != null) ...[
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => setState(() {
                  _imageBytes = null;
                  _imageFile = null;
                }),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200, width: 1.2),
                  ),
                  child: Icon(Icons.delete_outline_rounded,
                      color: Colors.red.shade600, size: 18),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildGradientButton({
    required String label,
    required IconData icon,
    bool isLoading = false,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_brandOrange, _gradientEnd],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _brandOrange.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: _white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: _brandOrange,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickHotelArea() async {
    await LocationData.loadFromJson();
    final district = _city ?? 'Pune';
    final areas = LocationData.getAreas(district);
    
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String filterQuery = '';
        final searchCtrl = TextEditingController();

        return StatefulBuilder(
          builder: (context, setPickerState) {
            final keyboardPad = MediaQuery.of(context).viewInsets.bottom;
            final filtered = areas.where((item) {
              return item.toLowerCase().contains(filterQuery.toLowerCase().trim());
            }).toList();

            final bool showCustom = filterQuery.trim().isNotEmpty &&
                !areas.any((i) => i.toLowerCase() == filterQuery.trim().toLowerCase());

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
                            'Select Area ($district)',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                            ),
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
                        hintText: 'Search or enter area name...',
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
                      itemCount: filtered.length + (showCustom ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (showCustom && index == 0) {
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

                        final itemIndex = showCustom ? index - 1 : index;
                        final item = filtered[itemIndex];
                        final isSelected = item == _area;

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
                ],
              ),
            );
          },
        );
      },
    );

    if (picked != null) {
      setState(() {
        _area = picked;
      });
    }
  }

  Future<void> _selectLocation() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const SelectLocationScreen()),
    );
    if (result != null) {
      setState(() {
        _addressCtrl.text = result['address'] as String;
        _hotelAddress = result['hotel_address'] as String?;
        _placeId = result['place_id'] as String?;
        _city = result['city'] as String?;
        _area = result['area'] as String?;
        _state = result['state'] as String?;
        _country = result['country'] as String?;
        _pincode = result['pincode'] as String?;
        _landmark = result['landmark'] as String?;
        _currentLocation = LatLng(
          result['latitude'] as double,
          result['longitude'] as double,
        );
      });
    }
  }

  Widget _buildServiceTypeCard(String value, String label, IconData icon) {
    final bool isSelected = _serviceType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _serviceType = value;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? _brandOrange.withOpacity(0.12) : _white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? _brandOrange : _cardBorder,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _brandOrange.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected ? _brandOrange : _greySub,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? _brandOrange : _ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoodTypeCard(String value, String label, IconData icon, Color color) {
    final bool isSelected = _foodType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _foodType = value;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : _white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : _cardBorder,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected ? color : _greySub,
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? color : _ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Painters for Pixel Perfect UI
// ─────────────────────────────────────────────────────────────────────────────

class DashedLinePainter extends CustomPainter {
  final Color color;
  const DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || size.width.isInfinite || size.height.isInfinite || size.width.isNaN || size.height.isNaN) {
      return;
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    double dashWidth = 5;
    double dashSpace = 4;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, size.height / 2),
          Offset(startX + dashWidth, size.height / 2), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DashedContainerPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;

  const DashedContainerPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.radius = 24,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || size.width.isInfinite || size.height.isInfinite || size.width.isNaN || size.height.isNaN) {
      return;
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final Path path = Path()..addRRect(rrect);
    final PathMetrics metrics = path.computeMetrics();

    for (final PathMetric metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final double len = (distance + 6 < metric.length) ? 6 : metric.length - distance;
        final Path extract = metric.extractPath(distance, distance + len);
        canvas.drawPath(extract, paint);
        distance += len + 4;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MapGraphicPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || size.width.isInfinite || size.height.isInfinite || size.width.isNaN || size.height.isNaN) {
      return;
    }
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke;

    final greenArea = Paint()
      ..color = const Color(0xFFD4EDDA)
      ..style = PaintingStyle.fill;

    final waterArea = Paint()
      ..color = const Color(0xFFCCE5FF)
      ..style = PaintingStyle.fill;

    // Water block on right
    final waterPath = Path()
      ..moveTo(size.width * 0.75, 0)
      ..quadraticBezierTo(size.width * 0.70, size.height * 0.5, size.width, size.height * 0.9)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(waterPath, waterArea);

    // Green park block
    final parkPath = Path()
      ..moveTo(0, size.height * 0.2)
      ..lineTo(size.width * 0.35, 0)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(parkPath, greenArea);

    // Roads
    canvas.drawLine(Offset(0, size.height * 0.6), Offset(size.width, size.height * 0.4), roadPaint);
    canvas.drawLine(Offset(size.width * 0.4, 0), Offset(size.width * 0.5, size.height), roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
