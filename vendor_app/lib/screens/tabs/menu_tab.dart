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

  void _showAddOrEditFoodDialog({MenuItem? existingItem}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: existingItem?.foodName);
    final descController = TextEditingController(text: existingItem?.description);
    final priceController = TextEditingController(
      text: existingItem != null ? existingItem.price.toStringAsFixed(0) : '',
    );
    String selectedType = existingItem?.foodType ?? 'VEG';
    String selectedSpice = existingItem?.spiceLevel ?? 'NONE';
    bool isPopular = existingItem?.isPopular ?? false;
    bool isAvailable = existingItem?.isAvailable ?? true;
    
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
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
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
                              setModalState(() {
                                pickedImage = File(picked.path);
                              });
                            }
                          },
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: pickedImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.file(pickedImage!, fit: BoxFit.cover),
                                  )
                                : (currentImageUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.network(currentImageUrl, fit: BoxFit.cover),
                                      )
                                    : const Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add_a_photo_rounded, color: Color(0xFF94A3B8), size: 32),
                                            SizedBox(height: 4),
                                            Text('Add Photo', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                                          ],
                                        ),
                                      )),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Food Name input
                      const Text('Dish Name *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: 'e.g. Paneer Tikka, Chicken Biryani',
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Dish name is required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Price input
                      const Text('Price (₹) *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'e.g. 220',
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Price is required';
                          if (double.tryParse(v) == null) return 'Enter a valid number';
                          return null;
                        },
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

                      // Dropdown selection - Dietary Type
                      const Text('Dietary Type *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'VEG', child: Text('Veg (Vegetarian)')),
                          DropdownMenuItem(value: 'NON-VEG', child: Text('Non-Veg')),
                        ],
                        onChanged: (val) {
                          if (val != null) selectedType = val;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Dropdown selection - Spice Level
                      const Text('Spice Level *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: selectedSpice,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'NONE', child: Text('None (Not Spicy)')),
                          DropdownMenuItem(value: 'LOW', child: Text('Low')),
                          DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
                          DropdownMenuItem(value: 'HIGH', child: Text('High (Very Spicy)')),
                        ],
                        onChanged: (val) {
                          if (val != null) selectedSpice = val;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Popular status switch
                      SwitchListTile(
                        title: const Text('Mark as Popular (Highly Reordered)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: const Text('This will display the "Highly reordered" badge on the card', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        value: isPopular,
                        activeColor: const Color(0xFFF07070),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) {
                          setModalState(() {
                            isPopular = val;
                          });
                        },
                      ),

                      // Availability status switch
                      SwitchListTile(
                        title: const Text('Item Available', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: const Text('Turn off if this item has ended for today', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        value: isAvailable,
                        activeColor: const Color(0xFF2563EB),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) {
                          setModalState(() {
                            isAvailable = val;
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  setModalState(() => isSaving = true);
                                  
                                  String? uploadedUrl = currentImageUrl;
                                  if (pickedImage != null) {
                                    uploadedUrl = await CloudinaryService.uploadImage(pickedImage!);
                                  }

                                  final MenuResult res;
                                  final double parsedPrice = double.parse(priceController.text);
                                  if (existingItem != null) {
                                    res = await MenuService.instance.editMenuItem(
                                      id: existingItem.id,
                                      foodName: nameController.text,
                                      description: descController.text,
                                      foodType: selectedType,
                                      price: parsedPrice,
                                      spiceLevel: selectedSpice,
                                      isPopular: isPopular,
                                      isAvailable: isAvailable,
                                      menuDate: _selectedDate,
                                      imageUrl: uploadedUrl,
                                    );
                                  } else {
                                    res = await MenuService.instance.addMenuItem(
                                      hotelId: _selectedHotel!.id,
                                      foodName: nameController.text,
                                      description: descController.text,
                                      foodType: selectedType,
                                      price: parsedPrice,
                                      spiceLevel: selectedSpice,
                                      isPopular: isPopular,
                                      isAvailable: isAvailable,
                                      menuDate: _selectedDate,
                                      imageUrl: uploadedUrl,
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
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
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
    final newAvailability = !item.isAvailable;
    final res = await MenuService.instance.editMenuItem(
      id: item.id,
      foodName: item.foodName,
      description: item.description,
      foodType: item.foodType,
      price: item.price,
      spiceLevel: item.spiceLevel,
      isPopular: item.isPopular,
      isAvailable: newAvailability,
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
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

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
                              color: const Color(0xFFFFF1F1), // soft red
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_circle_outline_rounded, color: Color(0xFFE23744), size: 24),
                                const SizedBox(width: 8),
                                const Text(
                                  'Add New Food Item',
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
                                        final item = _menuItems[index];
                                        return _buildZomatoFoodCard(item);
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
                    // Veg/Non-Veg + Spice level indicator
                    Row(
                      children: [
                        _buildVegIndicator(item.foodType),
                        if (item.spiceLevel != 'NONE') ...[
                          const SizedBox(width: 8),
                          _buildSpiceIndicator(item.spiceLevel),
                        ],
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
                    // Price
                    Text(
                      '₹${item.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
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
                                _showAddOrEditFoodDialog(existingItem: item);
                              } else if (val == 'delete') {
                                _confirmDeleteMenuItem(item);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_rounded, color: Color(0xFF475569), size: 16),
                                    SizedBox(width: 8),
                                    Text('Edit Dish', style: TextStyle(fontSize: 13)),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_rounded, color: Colors.redAccent, size: 16),
                                    SizedBox(width: 8),
                                    Text('Remove Dish', style: TextStyle(fontSize: 13, color: Colors.redAccent)),
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
              'You need to register a hotel first before you can manage its daily food menus.',
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
              label: const Text('Register Hotel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            'Tap "Add Food Item" below to create one.',
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
