// lib/screens/add_hotel_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';
import '../services/hotel_service.dart';
import '../models/hotel.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import 'select_location_screen.dart';

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

  File? _imageFile;
  final _picker = ImagePicker();

  LatLng? _currentLocation;
  bool _isSubmitting = false;

  String? _placeId, _city, _area, _state, _country, _pincode, _landmark,
      _hotelAddress;

  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  bool get _isEdit => widget.hotel != null;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _fadeAnim =
        CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
            CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryCtrl.forward();

    if (widget.hotel != null) {
      final h = widget.hotel!;
      _ownerCtrl.text = h.ownerName;
      _mobileCtrl.text = h.mobileNumber;
      _emailCtrl.text = h.email;
      _hotelNameCtrl.text = h.hotelName;
      _addressCtrl.text = h.hotelAddress;
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
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked =
          await _picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        setState(() => _imageFile = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ImagePickerSheet(
        onCamera: () {
          Navigator.pop(context);
          _pickImage(ImageSource.camera);
        },
        onGallery: () {
          Navigator.pop(context);
          _pickImage(ImageSource.gallery);
        },
        onRemove: _imageFile != null
            ? () {
                Navigator.pop(context);
                setState(() => _imageFile = null);
              }
            : null,
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select your location on the map'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    String? photoUrl;
    if (_imageFile != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Uploading image...',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          duration: const Duration(seconds: 6),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ),
      );
      photoUrl = await CloudinaryService.uploadImage(_imageFile!);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (photoUrl == null) {
        setState(() => _isSubmitting = false);
        final cont = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Upload Failed',
                style: TextStyle(fontWeight: FontWeight.w700)),
            content: const Text(
                'Failed to upload image. Continue without a photo?',
                style: TextStyle(color: AppColors.textSecondary)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Continue',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
        if (cont != true) return;
      }
    }

    await _submitData(photoUrl);
  }

  Future<void> _submitData(String? photoUrl) async {
    final HotelResult res;
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
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(28),
              boxShadow: AppShadows.elevated,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated checkmark circle
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.success, Color(0xFF059669)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 40),
                ),
                const SizedBox(height: 22),
                Text(
                  _isEdit ? 'Updated!' : 'Registered!',
                  style: AppText.headingLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  _isEdit
                      ? '${_hotelNameCtrl.text} has been successfully updated.'
                      : '${_hotelNameCtrl.text} has been successfully listed.',
                  style: AppText.bodyMedium,
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

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        Navigator.pop(context); // close dialog
        Navigator.pop(context, true); // return success
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
        content: Text(message, style: AppText.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hPad = Responsive.hPad(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceCard,
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.all(10),
          child: _BackButton(),
        ),
        title: Text(
          _isEdit ? 'Edit Hotel' : 'Register Hotel',
          style: AppText.headingSmall,
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: Responsive.maxWidth(context)),
            child: SlideTransition(
              position: _slideAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                      horizontal: hPad, vertical: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Section Header ────────────────────────────
                        _SectionHeader(
                          icon: Icons.business_rounded,
                          title: 'Hotel Information',
                          subtitle: 'Basic details about your property',
                        ),
                        const SizedBox(height: 20),

                        // ── Hotel Name ────────────────────────────────
                        AppTextField(
                          controller: _hotelNameCtrl,
                          label: 'Hotel Name *',
                          hint: 'E.g. Grand Palace Hotel',
                          icon: Icons.hotel_rounded,
                          textInputAction: TextInputAction.next,
                          validator: (v) => v == null || v.isEmpty
                              ? 'Hotel name is required'
                              : null,
                        ),
                        const SizedBox(height: 18),

                        // ── Owner Name ────────────────────────────────
                        AppTextField(
                          controller: _ownerCtrl,
                          label: 'Owner Name *',
                          hint: 'E.g. Jane Doe',
                          icon: Icons.person_rounded,
                          textInputAction: TextInputAction.next,
                          validator: (v) => v == null || v.isEmpty
                              ? 'Owner name is required'
                              : null,
                        ),
                        const SizedBox(height: 18),

                        // ── Mobile ────────────────────────────────────
                        AppTextField(
                          controller: _mobileCtrl,
                          label: 'Mobile Number *',
                          hint: '+91 9876543210',
                          icon: Icons.phone_rounded,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          validator: (v) => v == null || v.isEmpty
                              ? 'Mobile number is required'
                              : null,
                        ),
                        const SizedBox(height: 18),

                        // ── Email ─────────────────────────────────────
                        AppTextField(
                          controller: _emailCtrl,
                          label: 'Hotel Email *',
                          hint: 'info@grandpalace.com',
                          icon: Icons.email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return 'Email is required';
                            if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$')
                                .hasMatch(v))
                              return 'Enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),

                        // ── Section: Location ─────────────────────────
                        _SectionHeader(
                          icon: Icons.location_on_rounded,
                          title: 'Location',
                          subtitle: 'Select your property on the map',
                        ),
                        const SizedBox(height: 16),

                        // Address tap-to-select
                        GestureDetector(
                          onTap: _selectLocation,
                          child: AbsorbPointer(
                            child: AppTextField(
                              controller: _addressCtrl,
                              label: 'Address *',
                              hint: 'Tap to select on map',
                              icon: Icons.location_on_rounded,
                              maxLines: 2,
                              readOnly: true,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Please select a location'
                                  : null,
                            ),
                          ),
                        ),

                        if (_currentLocation != null) ...[
                          const SizedBox(height: 12),
                          _LocationPreview(
                            lat: _currentLocation!.latitude,
                            lng: _currentLocation!.longitude,
                            address: _hotelAddress,
                          ),
                        ],

                        const SizedBox(height: 28),

                        // ── Section: Photo ────────────────────────────
                        _SectionHeader(
                          icon: Icons.photo_camera_rounded,
                          title: 'Property Photo',
                          subtitle: 'Upload a photo to attract more guests',
                        ),
                        const SizedBox(height: 16),

                        _PhotoPickerWidget(
                          imageFile: _imageFile,
                          existingPhotoUrl: widget.hotel?.photoUrl,
                          onTap: _showImagePicker,
                        ),

                        const SizedBox(height: 36),

                        // ── Submit ────────────────────────────────────
                        AppPrimaryButton(
                          label: _isEdit ? 'Save Changes' : 'Register Property',
                          icon: _isEdit
                              ? Icons.save_rounded
                              : Icons.check_circle_rounded,
                          isLoading: _isSubmitting,
                          onPressed: _isSubmitting ? null : _handleSubmit,
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
}

// ── Section Header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink)),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ],
    );
  }
}

// ── Location Preview ──────────────────────────────────────────────────────────
class _LocationPreview extends StatelessWidget {
  final double lat;
  final double lng;
  final String? address;

  const _LocationPreview({
    required this.lat,
    required this.lng,
    this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.primary.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.my_location_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location confirmed',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (address != null && address!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    address!,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Photo Picker Widget ───────────────────────────────────────────────────────
class _PhotoPickerWidget extends StatelessWidget {
  final File? imageFile;
  final String? existingPhotoUrl;
  final VoidCallback onTap;

  const _PhotoPickerWidget({
    this.imageFile,
    this.existingPhotoUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageFile != null ||
        (existingPhotoUrl != null && existingPhotoUrl!.isNotEmpty);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: hasImage ? Colors.transparent : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasImage
                ? Colors.transparent
                : AppColors.border,
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  imageFile != null
                      ? Image.file(imageFile!, fit: BoxFit.cover)
                      : Image.network(existingPhotoUrl!, fit: BoxFit.cover),
                  // Overlay with edit button
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.edit_rounded,
                              color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text('Change Photo',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.add_a_photo_rounded,
                        size: 26, color: AppColors.primary),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Upload Hotel Photo',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap to choose from camera or gallery',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Image Picker Bottom Sheet ─────────────────────────────────────────────────
class _ImagePickerSheet extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback? onRemove;

  const _ImagePickerSheet({
    required this.onCamera,
    required this.onGallery,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(28),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Choose Photo',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 18, color: AppColors.inkMid),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SheetOption(
                icon: Icons.camera_alt_rounded,
                iconColor: AppColors.primary,
                bgColor: AppColors.primarySurface,
                label: 'Take a Photo',
                subtitle: 'Use your camera',
                onTap: onCamera,
              ),
              const SizedBox(height: 12),
              _SheetOption(
                icon: Icons.photo_library_rounded,
                iconColor: const Color(0xFF8B5CF6),
                bgColor: const Color(0xFFF5F3FF),
                label: 'Choose from Gallery',
                subtitle: 'Browse your photos',
                onTap: onGallery,
              ),
              if (onRemove != null) ...[
                const SizedBox(height: 12),
                _SheetOption(
                  icon: Icons.delete_outline_rounded,
                  iconColor: AppColors.error,
                  bgColor: AppColors.errorSurface,
                  label: 'Remove Photo',
                  subtitle: 'Clear current image',
                  onTap: onRemove!,
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: iconColor)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
              const Spacer(),
              Icon(Icons.chevron_right_rounded,
                  color: iconColor.withOpacity(0.5), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.maybePop(context),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: AppColors.ink,
          ),
        ),
      ),
    );
  }
}
