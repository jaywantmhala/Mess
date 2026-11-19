// lib/screens/tabs/menu_tab.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/hotel.dart';
import '../../models/menu_item.dart';
import '../../services/hotel_service.dart';
import '../../services/menu_service.dart';
import '../../services/cloudinary_service.dart';
import '../add_hotel_screen.dart';
import '../../widgets/custom_toast.dart';

class MenuTab extends StatefulWidget {
  const MenuTab({super.key});

  @override
  State<MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends State<MenuTab> {
  List<Hotel> _hotels = [];
  Hotel? _selectedHotel;
  List<MenuItem> _menuItems = [];
  bool _isLoadingHotels = false;
  bool _isLoadingMenu = false;
  
  int _selectedDateIndex = 0;
  late String _selectedDate;
  
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedDate = _formatDate(DateTime.now());
    _loadHotels();
  }

  Future<void> _loadHotels() async {
    setState(() => _isLoadingHotels = true);
    final hotels = await HotelService.instance.getHotels();
    setState(() {
      _hotels = hotels;
      if (_hotels.isNotEmpty) {
        _selectedHotel = _hotels.first;
      }
      _isLoadingHotels = false;
    });
    if (_selectedHotel != null) {
      _loadMenuItems();
    }
  }

  Future<void> _loadMenuItems() async {
    if (_selectedHotel == null) return;
    setState(() => _isLoadingMenu = true);
    final items = await MenuService.instance.getMenuItems(_selectedHotel!.id, _selectedDate);
    setState(() {
      _menuItems = items;
      _isLoadingMenu = false;
    });
  }

  String _formatDate(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }

  bool _isMenuLocked(MenuItem item) {
    final now = DateTime.now();
    final todayStr = _formatDate(now);
    final cmp = item.menuDate.compareTo(todayStr);
    if (cmp < 0) {
      return true; // Past dates are locked
    }
    if (cmp > 0) {
      return false; // Future dates are editable
    }
    // Today's date
    if (item.mealType.trim().toLowerCase() == 'lunch') {
      return now.hour >= 16; // Lunch closed at 4:00 PM
    }
    return false; // Dinner active until midnight
  }

  Widget _buildMealTypeBadge(String mealType, {bool isLocked = false}) {
    final isLunch = mealType.trim().toLowerCase() == 'lunch';
    final bgColor = isLunch ? const Color(0xFFFFF7ED) : const Color(0xFFF5F3FF);
    final borderColor = isLunch ? const Color(0xFFFFEDD5) : const Color(0xFFEDE9FE);
    final textColor = isLunch ? const Color(0xFFC2410C) : const Color(0xFF6D28D9);
    final icon = isLunch ? Icons.wb_sunny_rounded : Icons.nightlight_round;
    final label = isLunch ? 'Lunch' : 'Dinner';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: textColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
        if (isLocked) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_rounded, size: 11, color: Color(0xFF64748B)),
                SizedBox(width: 3),
                Text(
                  'Locked',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showAddOrEditFoodDialog({MenuItem? existingItem}) {
    if (existingItem != null && _isMenuLocked(existingItem)) {
      CustomToast.show(
        context,
        'This ${existingItem.mealType} menu cannot be edited because its meal time has passed.',
        isError: true,
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: existingItem?.foodName);
    final descController = TextEditingController(text: existingItem?.description);
    String selectedType = existingItem?.foodType ?? 'VEG';
    String selectedSpice = existingItem?.spiceLevel ?? 'NONE';
    String selectedMealType = existingItem?.mealType ?? (DateTime.now().hour < 16 ? 'Lunch' : 'Dinner');
    bool isPopular = existingItem?.isPopular ?? false;
    bool isAvailable = existingItem?.isAvailable ?? true;
    
    // Mandatory items controllers list
    List<TextEditingController> mandatoryControllers = existingItem != null && existingItem.mandatoryItems.isNotEmpty
        ? existingItem.mandatoryItems.map((s) => TextEditingController(text: s)).toList()
        : [TextEditingController()];

    // Dry Sabji (Sukhi Bhaji) & Gravy Sabji (Patal Bhaji) controllers
    List<TextEditingController> drySabjiControllers = [];
    List<TextEditingController> gravySabjiControllers = [];

    if (existingItem != null && existingItem.optionalItems.isNotEmpty) {
      for (var s in existingItem.optionalItems) {
        if (s.startsWith('Sukhi Bhaji: ') || s.startsWith('Dry Sabji: ')) {
          drySabjiControllers.add(TextEditingController(text: s.replaceFirst(RegExp(r'^(Sukhi Bhaji|Dry Sabji):\s*'), '')));
        } else if (s.startsWith('Patal Bhaji: ') || s.startsWith('Gravy Sabji: ')) {
          gravySabjiControllers.add(TextEditingController(text: s.replaceFirst(RegExp(r'^(Patal Bhaji|Gravy Sabji):\s*'), '')));
        } else {
          if (drySabjiControllers.length < 2) {
            drySabjiControllers.add(TextEditingController(text: s));
          } else {
            gravySabjiControllers.add(TextEditingController(text: s));
          }
        }
      }
    }

    if (drySabjiControllers.isEmpty) {
      drySabjiControllers = [TextEditingController(), TextEditingController()];
    }
    if (gravySabjiControllers.isEmpty) {
      gravySabjiControllers = [TextEditingController(), TextEditingController()];
    }

    File? pickedImage;
    String? currentImageUrl = existingItem?.imageUrl;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 40, height: 4,
                          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        existingItem != null ? 'Edit Food Item' : 'Add Food Item',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 16),
                      
                      // Image Picker View
                      Center(
                        child: GestureDetector(
                          onTap: () async {
                            final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                            if (picked != null) {
                              setModalState(() { pickedImage = File(picked.path); });
                            }
                          },
                          child: Container(
                            width: 120, height: 120,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: pickedImage != null
                                ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(pickedImage!, fit: BoxFit.cover))
                                : (currentImageUrl != null
                                    ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(currentImageUrl, fit: BoxFit.cover))
                                    : const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                        Icon(Icons.add_a_photo_rounded, color: Color(0xFF94A3B8), size: 32),
                                        SizedBox(height: 4),
                                        Text('Add Photo', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                                      ]))),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── MEAL SESSION SELECTOR (LUNCH / DINNER) ──────────────
                      Row(
                        children: [
                          const Text(
                            'Meal Timing / Session *',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                          if (existingItem != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.lock_rounded, size: 10, color: Color(0xFF64748B)),
                                  SizedBox(width: 3),
                                  Text(
                                    'Fixed once added',
                                    style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: existingItem == null
                                  ? () => setModalState(() => selectedMealType = 'Lunch')
                                  : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: selectedMealType == 'Lunch'
                                      ? const Color(0xFFFFF7ED)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selectedMealType == 'Lunch'
                                        ? const Color(0xFFEA580C)
                                        : const Color(0xFFE2E8F0),
                                    width: selectedMealType == 'Lunch' ? 1.8 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('🍛', style: TextStyle(fontSize: 16)),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Lunch',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: selectedMealType == 'Lunch' ? FontWeight.w700 : FontWeight.w500,
                                        color: selectedMealType == 'Lunch'
                                            ? const Color(0xFFEA580C)
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: existingItem == null
                                  ? () => setModalState(() => selectedMealType = 'Dinner')
                                  : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: selectedMealType == 'Dinner'
                                      ? const Color(0xFFEEF2FF)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selectedMealType == 'Dinner'
                                        ? const Color(0xFF4F46E5)
                                        : const Color(0xFFE2E8F0),
                                    width: selectedMealType == 'Dinner' ? 1.8 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('🌙', style: TextStyle(fontSize: 16)),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Dinner',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: selectedMealType == 'Dinner' ? FontWeight.w700 : FontWeight.w500,
                                        color: selectedMealType == 'Dinner'
                                            ? const Color(0xFF4F46E5)
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Dish Name input
                      const Text('Dish / Menu Name *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: 'e.g. Special Veg Thali, Deluxe Lunch',
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Dish name is required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Description input
                      const Text('Description', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: descController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Describe ingredients or taste details...',
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Dropdown selection - Dietary Type & Spice Level
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Dietary Type *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  value: selectedType,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'VEG', child: Text('Veg')),
                                    DropdownMenuItem(value: 'NON-VEG', child: Text('Non-Veg')),
                                  ],
                                  onChanged: (val) { if (val != null) selectedType = val; },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Spice Level *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  value: selectedSpice,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'NONE', child: Text('None')),
                                    DropdownMenuItem(value: 'LOW', child: Text('Low')),
                                    DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
                                    DropdownMenuItem(value: 'HIGH', child: Text('High')),
                                  ],
                                  onChanged: (val) { if (val != null) selectedSpice = val; },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── MANDATORY ITEMS SECTION ───────────────────────────
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.check_circle_outline_rounded, color: Color(0xFFE23744), size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Mandatory Items',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFE23744)),
                                ),
                                const Spacer(),
                                Text(
                                  'Included in meal',
                                  style: TextStyle(fontSize: 11, color: Colors.red.shade700, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...List.generate(mandatoryControllers.length, (index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: mandatoryControllers[index],
                                        decoration: InputDecoration(
                                          hintText: 'e.g. 4 Roti, Dal Fry, Jeera Rice',
                                          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                          filled: true,
                                          fillColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                    if (mandatoryControllers.length > 1)
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.redAccent),
                                        onPressed: () {
                                          setModalState(() {
                                            mandatoryControllers[index].dispose();
                                            mandatoryControllers.removeAt(index);
                                          });
                                        },
                                      ),
                                  ],
                                ),
                              );
                            }),
                            InkWell(
                              onTap: () {
                                setModalState(() {
                                  mandatoryControllers.add(TextEditingController());
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6.0),
                                child: Row(
                                  children: const [
                                    Icon(Icons.add_circle_outline_rounded, color: Color(0xFFE23744), size: 18),
                                    SizedBox(width: 6),
                                    Text('+ Add Mandatory Item', style: TextStyle(color: Color(0xFFE23744), fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── OPTIONAL ITEMS SECTION ────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF93C5FD)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.tune_rounded, color: Color(0xFF2563EB), size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Optional Items (Sabji Choices)',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                                ),
                                const Spacer(),
                                Text(
                                  'Customer chooses optional',
                                  style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // SUB-SECTION 1: Dry Sabji / Sukhi Bhaji
                            const Text(
                              'Dry Sabji / Sukhi Bhaji (Optional)',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 6),
                            ...List.generate(drySabjiControllers.length, (index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: drySabjiControllers[index],
                                        decoration: InputDecoration(
                                          hintText: index == 0 ? 'e.g. Aloo Bhendi / Dry Sabji 1' : 'e.g. Jeera Aloo / Dry Sabji 2',
                                          labelText: 'Dry Sabji ${index + 1}',
                                          labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                          filled: true,
                                          fillColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                    if (drySabjiControllers.length > 1)
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.redAccent),
                                        onPressed: () {
                                          setModalState(() {
                                            drySabjiControllers[index].dispose();
                                            drySabjiControllers.removeAt(index);
                                          });
                                        },
                                      ),
                                  ],
                                ),
                              );
                            }),
                            InkWell(
                              onTap: () {
                                setModalState(() {
                                  drySabjiControllers.add(TextEditingController());
                                });
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  children: [
                                    Icon(Icons.add_circle_outline_rounded, color: Color(0xFF2563EB), size: 16),
                                    SizedBox(width: 4),
                                    Text('+ Add Dry Sabji Option', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 14),
                            const Divider(height: 1),
                            const SizedBox(height: 12),

                            // SUB-SECTION 2: Gravy Sabji / Patal Bhaji
                            const Text(
                              'Gravy Sabji / Patal Bhaji (Optional)',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 6),
                            ...List.generate(gravySabjiControllers.length, (index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: gravySabjiControllers[index],
                                        decoration: InputDecoration(
                                          hintText: index == 0 ? 'e.g. Shev Bhaji / Gravy Sabji 1' : 'e.g. Paneer Masala / Gravy Sabji 2',
                                          labelText: 'Gravy Sabji ${index + 1}',
                                          labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                          filled: true,
                                          fillColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                    if (gravySabjiControllers.length > 1)
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.redAccent),
                                        onPressed: () {
                                          setModalState(() {
                                            gravySabjiControllers[index].dispose();
                                            gravySabjiControllers.removeAt(index);
                                          });
                                        },
                                      ),
                                  ],
                                ),
                              );
                            }),
                            InkWell(
                              onTap: () {
                                setModalState(() {
                                  gravySabjiControllers.add(TextEditingController());
                                });
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  children: [
                                    Icon(Icons.add_circle_outline_rounded, color: Color(0xFF2563EB), size: 16),
                                    SizedBox(width: 4),
                                    Text('+ Add Gravy Sabji Option', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Popular status switch
                      SwitchListTile(
                        title: const Text('Mark as Popular (Highly Reordered)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: const Text('Displays "Highly reordered" badge', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        value: isPopular,
                        activeColor: const Color(0xFFF07070),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) { setModalState(() { isPopular = val; }); },
                      ),

                      // Availability status switch
                      SwitchListTile(
                        title: const Text('Item Available', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: const Text('Turn off if this item has ended for today', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        value: isAvailable,
                        activeColor: const Color(0xFF2563EB),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) { setModalState(() { isAvailable = val; }); },
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isSaving ? null : () async {
                            if (!formKey.currentState!.validate()) return;
                            setModalState(() => isSaving = true);
                            
                            String? uploadedUrl = currentImageUrl;
                            if (pickedImage != null) {
                              uploadedUrl = await CloudinaryService.uploadImage(pickedImage!);
                            }

                            final mandatoryList = mandatoryControllers
                                .map((c) => c.text.trim())
                                .where((s) => s.isNotEmpty)
                                .toList();

                            final List<String> optionalList = [];
                            for (var c in drySabjiControllers) {
                              final t = c.text.trim();
                              if (t.isNotEmpty) optionalList.add('Sukhi Bhaji: $t');
                            }
                            for (var c in gravySabjiControllers) {
                              final t = c.text.trim();
                              if (t.isNotEmpty) optionalList.add('Patal Bhaji: $t');
                            }

                            final MenuResult res;
                            if (existingItem != null) {
                              res = await MenuService.instance.editMenuItem(
                                id: existingItem.id,
                                foodName: nameController.text,
                                description: descController.text,
                                foodType: selectedType,
                                price: 0,
                                spiceLevel: selectedSpice,
                                isPopular: isPopular,
                                isAvailable: isAvailable,
                                menuDate: _selectedDate,
                                mealType: existingItem.mealType,
                                imageUrl: uploadedUrl,
                                mandatoryItems: mandatoryList,
                                optionalItems: optionalList,
                              );
                            } else {
                              res = await MenuService.instance.addMenuItem(
                                hotelId: _selectedHotel!.id,
                                foodName: nameController.text,
                                description: descController.text,
                                foodType: selectedType,
                                price: 0,
                                spiceLevel: selectedSpice,
                                isPopular: isPopular,
                                isAvailable: isAvailable,
                                menuDate: _selectedDate,
                                mealType: selectedMealType,
                                imageUrl: uploadedUrl,
                                mandatoryItems: mandatoryList,
                                optionalItems: optionalList,
                              );
                            }

                            if (res.success) {
                              SystemSound.play(SystemSoundType.alert);
                              if (context.mounted) {
                                Navigator.pop(context);
                                CustomToast.show(context, res.message);
                              }
                              _loadMenuItems();
                            } else {
                              setModalState(() => isSaving = false);
                              if (context.mounted) {
                                CustomToast.show(context, res.message, isError: true);
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF07070),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isSaving
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(
                                  existingItem != null ? 'Save Changes' : 'Add to Menu',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
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

  Future<void> _toggleAvailability(MenuItem item) async {
    if (_isMenuLocked(item)) {
      if (mounted) {
        CustomToast.show(
          context,
          'This ${item.mealType} menu is locked because its meal time has passed.',
          isError: true,
        );
      }
      return;
    }
    final newAvailability = !item.isAvailable;
    final res = await MenuService.instance.editMenuItem(
      id: item.id,
      foodName: item.foodName,
      description: item.description,
      foodType: item.foodType,
      price: 0,
      spiceLevel: item.spiceLevel,
      isPopular: item.isPopular,
      isAvailable: newAvailability,
      mandatoryItems: item.mandatoryItems,
      optionalItems: item.optionalItems,
      menuDate: item.menuDate,
      imageUrl: item.imageUrl,
    );
    if (res.success) {
      _loadMenuItems();
      if (mounted) {
        CustomToast.show(
          context,
          newAvailability ? '"${item.foodName}" is now Available' : '"${item.foodName}" marked as Ended',
          isError: !newAvailability,
        );
      }
    } else {
      if (mounted) {
        CustomToast.show(context, res.message, isError: true);
      }
    }
  }

  void _confirmDeleteMenuItem(MenuItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Food Item?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to remove "${item.foodName}" from the daily menu?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final res = await MenuService.instance.deleteMenuItem(item.id);
              if (res.success) {
                if (context.mounted) {
                  CustomToast.show(context, res.message);
                }
                _loadMenuItems();
              } else {
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Error'),
                      content: Text(res.message),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
                      ],
                    ),
                  );
                }
              }
            },
            child: const Text('Remove', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFC),
      appBar: AppBar(
        title: const Text('Daily Food Menu', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: _isLoadingHotels
          ? const Center(child: CircularProgressIndicator())
          : _hotels.isEmpty
              ? _buildNoHotelsState()
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    // Hotel Selector Dropdown
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.storefront_rounded, color: Color(0xFFF07070)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<Hotel>(
                                value: _selectedHotel,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8)),
                                items: _hotels.map((h) {
                                  return DropdownMenuItem(
                                    value: h,
                                    child: Text(
                                      h.hotelName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (Hotel? val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedHotel = val;
                                    });
                                    _loadMenuItems();
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Horizontal Date Slider
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      child: _buildDateSlider(),
                    ),
                    
                    const SizedBox(height: 8),

                    // Add Menu Item Button (Sticky)
                    if (_selectedHotel != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: InkWell(
                          onTap: () => _showAddOrEditFoodDialog(),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_circle_outline_rounded, color: Color(0xFFE23744), size: 24),
                                SizedBox(width: 8),
                                Text(
                                  'Add New Food Item / Thali',
                                  style: TextStyle(
                                    color: Color(0xFFE23744),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 8),
                    
                    // Daily Menu Listing
                    Expanded(
                      child: _isLoadingMenu
                          ? const Center(child: CircularProgressIndicator())
                          : Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: _menuItems.isEmpty
                                  ? _buildEmptyMenuState()
                                  : ListView.builder(
                                      itemCount: _menuItems.length,
                                      itemBuilder: (context, index) {
                                        return _buildZomatoFoodCard(_menuItems[index]);
                                      },
                                    ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }



  Widget _buildDateSlider() {
    return SizedBox(
      height: 75,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final isSelected = _selectedDateIndex == index;
          final dayName = _getDayName(date.weekday);
          final dateNum = date.day.toString().padLeft(2, '0');
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDateIndex = index;
                _selectedDate = _formatDate(date);
              });
              _loadMenuItems();
            },
            child: Container(
              width: 58,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF07070) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? const Color(0xFFF07070) : const Color(0xFFE2E8F0),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFFF07070).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white70 : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateNum,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildZomatoFoodCard(MenuItem item) {
    final isLocked = _isMenuLocked(item);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side - food info details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Veg/Non-Veg + Spice level indicator + Meal Type badge
                    Row(
                      children: [
                        _buildVegIndicator(item.foodType),
                        if (item.spiceLevel != 'NONE') ...[
                          const SizedBox(width: 8),
                          _buildSpiceIndicator(item.spiceLevel),
                        ],
                        const SizedBox(width: 8),
                        _buildMealTypeBadge(item.mealType, isLocked: isLocked),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Food Name
                    Text(
                      item.foodName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.2,
                      ),
                    ),
                    // Popularity Badge ("Highly reordered")
                    if (item.isPopular) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            height: 4,
                            width: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Highly reordered',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    // Mandatory Items List (e.g. Rice + Chapati + Dal)
                    if (item.mandatoryItems.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.mandatoryItems.join(' + '),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                          height: 1.3,
                        ),
                      ),
                    ],

                    // Optional Items List (e.g. (Aloo Bhendi + Shev Bhaji))
                    if (item.optionalItems.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '(${item.optionalItems.map((s) => s.replaceAll(RegExp(r'^(Sukhi Bhaji|Dry Sabji|Patal Bhaji|Gravy Sabji):\s*', caseSensitive: false), '').trim()).where((s) => s.isNotEmpty).join(' + ')})',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB),
                          height: 1.3,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    // Description
                    if (item.description.isNotEmpty)
                      Text(
                        item.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 10),
                    // Aesthetic action buttons: Bookmark & Share
                    Row(
                      children: [
                        _buildCircleActionButton(Icons.bookmark_border_rounded),
                        const SizedBox(width: 12),
                        _buildCircleActionButton(Icons.reply_rounded, isMirror: true),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              
              // Right side - food photo & actions
              Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      // Photo
                      Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(item.imageUrl!, fit: BoxFit.cover),
                              )
                            : const Center(
                                child: Icon(
                                  Icons.restaurant_rounded,
                                  color: Color(0xFFCBD5E1),
                                  size: 40,
                                ),
                              ),
                      ),
                      // Availability Toggle Button (overlapping image bottom)
                      Positioned(
                        bottom: -15,
                        child: GestureDetector(
                          onTap: () => _toggleAvailability(item),
                          child: Container(
                            width: 112,
                            height: 36,
                            decoration: BoxDecoration(
                              color: item.isAvailable
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFFDC2626),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: (item.isAvailable
                                          ? const Color(0xFF2563EB)
                                          : const Color(0xFFDC2626))
                                      .withOpacity(0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  item.isAvailable
                                      ? Icons.check_circle_rounded
                                      : Icons.cancel_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  item.isAvailable ? 'AVAILABLE' : 'ENDED',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Vendor actions popup menu (placed at top-right of image)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF475569), size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onSelected: (val) {
                              if (val == 'edit') {
                                if (isLocked) {
                                  CustomToast.show(
                                    context,
                                    'This ${item.mealType} menu cannot be edited because its meal time has passed.',
                                    isError: true,
                                  );
                                  return;
                                }
                                _showAddOrEditFoodDialog(existingItem: item);
                              } else if (val == 'delete') {
                                if (isLocked) {
                                  CustomToast.show(
                                    context,
                                    'This ${item.mealType} menu cannot be removed because its meal time has passed.',
                                    isError: true,
                                  );
                                  return;
                                }
                                _confirmDeleteMenuItem(item);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(
                                      isLocked ? Icons.lock_outline_rounded : Icons.edit_rounded,
                                      color: isLocked ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isLocked ? 'Edit Dish (Locked)' : 'Edit Dish',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isLocked ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_rounded,
                                      color: isLocked ? const Color(0xFF94A3B8) : Colors.redAccent,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isLocked ? 'Remove Dish (Locked)' : 'Remove Dish',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isLocked ? const Color(0xFF94A3B8) : Colors.redAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'customisable',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const CustomDottedDivider(),
      ],
    );
  }

  Widget _buildVegIndicator(String type) {
    final isVeg = type == 'VEG';
    final color = isVeg ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: isVeg
          ? Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            )
          : CustomPaint(
              size: const Size(7, 7),
              painter: TrianglePainter(color: color),
            ),
    );
  }

  Widget _buildSpiceIndicator(String level) {
    String text = '';
    if (level == 'LOW') text = '🌶️';
    if (level == 'MEDIUM') text = '🌶️🌶️';
    if (level == 'HIGH') text = '🌶️🌶️🌶️';

    return Text(
      text,
      style: const TextStyle(fontSize: 13),
    );
  }

  Widget _buildCircleActionButton(IconData icon, {bool isMirror = false}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Transform(
        alignment: Alignment.center,
        transform: isMirror ? Matrix4.rotationY(3.14159) : Matrix4.identity(),
        child: Icon(
          icon,
          size: 18,
          color: const Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildNoHotelsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFF07070).withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.storefront_rounded, size: 48, color: Color(0xFFF07070)),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Properties Registered',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            Text(
              'You need to register a mess first before you can manage its daily food menus.',
              style: TextStyle(color: Colors.grey[600], height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final added = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddHotelScreen()),
                );
                if (added == true) {
                  _loadHotels();
                }
              },
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Register Mess', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF07070),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMenuState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu_rounded, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No food items added for this date',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap "+ Mandatory" or "+ Optional" to add items.',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}

// ── Custom Painters and Additional Helper Widgets ───────────────────────────

class TrianglePainter extends CustomPainter {
  final Color color;
  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CustomDottedDivider extends StatelessWidget {
  const CustomDottedDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final boxWidth = constraints.constrainWidth();
          const dashWidth = 4.0;
          const dashSpace = 4.0;
          final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(dashCount, (_) {
              return SizedBox(
                width: dashWidth,
                height: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Colors.grey[300]),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
