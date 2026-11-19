// lib/screens/saved_addresses_screen.dart
import 'package:flutter/material.dart';
import '../models/address_data.dart';
import '../services/address_service.dart';
import '../utils/location_data.dart';
import 'select_address_screen.dart';

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  static const Color _brandOrange  = Color(0xFFF58220);
  static const Color _bgWarm       = Color(0xFFFAFAFA);
  static const Color _white        = Colors.white;
  static const Color _ink          = Color(0xFF1A1A2E);
  static const Color _greySub      = Color(0xFF6B7280);
  static const Color _cardBorder   = Color(0xFFE5E7EB);
  static const Color _redDark      = Color(0xFFDC2626);

  List<AddressData> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    LocationData.loadFromJson();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);
    try {
      final list = await AddressService.instance.getAddresses();
      if (mounted) {
        setState(() {
          _addresses = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDefault(AddressData addr) async {
    if (addr.id == null) {
      Navigator.pop(context, addr);
      return;
    }
    setState(() => _isLoading = true);
    await AddressService.instance.setDefaultAddress(addr.id!);
    final selected = addr.copyWith(isDefault: true);
    await AddressService.instance.cacheSelectedAddress(selected);
    if (mounted) {
      Navigator.pop(context, selected);
    }
  }

  Future<void> _deleteAddress(AddressData addr) async {
    if (addr.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Address?'),
        content: Text('Are you sure you want to delete this ${addr.tag.toLowerCase()} address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: _greySub)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _redDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final ok = await AddressService.instance.deleteAddress(addr.id!);
      if (ok) {
        setState(() {
          _addresses.removeWhere((a) => a.id == addr.id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Address deleted successfully.'),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete address. Please try again.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      await _loadAddresses();
    }
  }

  /// Reusable searchable picker bottom sheet with instant live search and optional custom input.
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
                  // Search Input Field
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
                        enabledBorder: OutlineInputBorder(
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

                  // List of filtered items
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: _brandOrange,
                                ),
                              ),
                              subtitle: const Text(
                                'Tap to set as custom area',
                                style: TextStyle(fontSize: 11, color: _greySub),
                              ),
                              onTap: () => Navigator.pop(ctx, filterQuery.trim()),
                            ),
                          );
                        }

                        final itemIndex = showCustomOption ? index - 1 : index;
                        final item = filtered[itemIndex];
                        final isSelected = item == selectedItem;

                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
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

  /// Unified location search modal searching across all Areas, Talukas, and Districts in Maharashtra.
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
                  // Search Input Field
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

                  // Results list
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

  /// Tap-friendly searchable selector tile with clear visual state.
  Widget _buildSearchableSelectTile({
    required String label,
    required String? value,
    required String placeholder,
    required IconData icon,
    required VoidCallback onTap,
    bool enabled = true,
    Widget? trailingWidget,
  }) {
    final bool hasValue = value != null && value.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: enabled ? _white : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasValue ? _brandOrange.withOpacity(0.5) : const Color(0xFFD1D5DB),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: enabled ? _brandOrange : _greySub, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hasValue ? value! : placeholder,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: hasValue ? FontWeight.w700 : FontWeight.w400,
                      color: hasValue ? _ink : const Color(0xFF9CA3AF),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (trailingWidget != null)
                  trailingWidget
                else
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    color: enabled ? _brandOrange : _greySub,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openAddressForm({AddressData? editAddress, AddressData? pickedMapAddress}) async {
    await LocationData.loadFromJson();
    AddressData initial = editAddress ?? pickedMapAddress ?? const AddressData(fullAddress: '');
    final nameCtrl = TextEditingController(text: initial.name);
    final mobileCtrl = TextEditingController(text: initial.mobileNumber);
    final houseCtrl = TextEditingController(text: initial.houseNo);
    final fullAddrCtrl = TextEditingController(text: initial.fullAddress);
    final landmarkCtrl = TextEditingController(text: initial.landmark);

    String selectedTag = (initial.tag.isNotEmpty ? initial.tag : 'HOME').toUpperCase();
    if (!['HOME', 'OFFICE', 'OTHER'].contains(selectedTag)) {
      selectedTag = 'HOME';
    }

    String selectedCountry = initial.country.isNotEmpty ? initial.country : LocationData.defaultCountry;
    String? selectedState = initial.state.isNotEmpty ? initial.state : null;
    String? selectedDistrict = initial.district.isNotEmpty ? initial.district : null;
    String? selectedTaluka = initial.taluka.isNotEmpty ? initial.taluka : null;
    String? selectedArea = initial.area.isNotEmpty ? initial.area : null;
    final areaCtrl = TextEditingController(text: initial.area);

    // Auto-detect or default state to Maharashtra
    if (selectedState == null || !LocationData.getStates(selectedCountry).contains(selectedState)) {
      if (initial.state.isNotEmpty && LocationData.getStates(selectedCountry).contains(initial.state)) {
        selectedState = initial.state;
      } else if (selectedCountry == 'India') {
        selectedState = 'Maharashtra';
      }
    }

    // Auto-match district, taluka, and area from initial location data (map picker or address string)
    if (selectedDistrict == null || selectedDistrict.isEmpty) {
      final match = LocationData.matchLocation(
        '${initial.city} ${initial.area} ${initial.landmark} ${initial.fullAddress}',
        defaultState: selectedState,
      );
      if (match != null) {
        selectedDistrict = match['district'];
        if ((selectedTaluka == null || selectedTaluka.isEmpty) &&
            match['taluka'] != null &&
            match['taluka']!.isNotEmpty) {
          final availableTalukas = LocationData.getTalukas(selectedDistrict!);
          if (availableTalukas.contains(match['taluka'])) {
            selectedTaluka = match['taluka'];
          }
        }
        if ((selectedArea == null || selectedArea.isEmpty) &&
            match['area'] != null &&
            match['area']!.isNotEmpty) {
          selectedArea = match['area'];
          areaCtrl.text = match['area']!;
        }
      }
    }

    String? formErrorMessage;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final keyboardPad = MediaQuery.of(context).viewInsets.bottom;
          return Container(
            padding: EdgeInsets.fromLTRB(20, 16, 20, keyboardPad + 20),
            decoration: const BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 16),
                  Text(
                    editAddress != null ? 'Edit Address' : 'Add New Address',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Save your address details for fast checkout.',
                    style: TextStyle(fontSize: 13, color: _greySub),
                  ),
                  const SizedBox(height: 16),

                  if (formErrorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: _redDark, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              formErrorMessage!,
                              style: const TextStyle(
                                color: _redDark,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Tag Selector Chips ──────────────────────────────────────
                  const Text(
                    'SAVE AS',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: _greySub,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: ['HOME', 'OFFICE', 'OTHER'].map((tagStr) {
                      final isSelected = selectedTag == tagStr;
                      IconData iconData = Icons.home_rounded;
                      if (tagStr == 'OFFICE') iconData = Icons.work_rounded;
                      if (tagStr == 'OTHER') iconData = Icons.location_on_rounded;

                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedTag = tagStr;
                              formErrorMessage = null;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? _brandOrange.withOpacity(0.12) : _bgWarm,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? _brandOrange : _cardBorder,
                                width: isSelected ? 1.8 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  iconData,
                                  size: 16,
                                  color: isSelected ? _brandOrange : _greySub,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  tagStr,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                    color: isSelected ? _brandOrange : _ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Receiver Name
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Receiver Name *',
                      prefixIcon: const Icon(Icons.person_outline_rounded, color: _brandOrange, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Receiver Phone
                  TextField(
                    controller: mobileCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Mobile Number *',
                      prefixIcon: const Icon(Icons.phone_outlined, color: _brandOrange, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // House / Flat No
                  TextField(
                    controller: houseCtrl,
                    decoration: InputDecoration(
                      labelText: 'House / Flat / Floor No.',
                      prefixIcon: const Icon(Icons.maps_home_work_outlined, color: _brandOrange, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Full Address
                  TextField(
                    controller: fullAddrCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Full Address *',
                      prefixIcon: const Icon(Icons.location_on_outlined, color: _brandOrange, size: 20),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.my_location_rounded, color: _brandOrange),
                        tooltip: 'Select on Map',
                        onPressed: () async {
                          final picked = await Navigator.push<AddressData>(
                            context,
                            MaterialPageRoute(builder: (_) => const SelectAddressScreen()),
                          );
                          if (picked != null) {
                            final match = LocationData.matchLocation(
                              '${picked.city} ${picked.area} ${picked.landmark} ${picked.fullAddress}',
                              defaultState: selectedState ?? 'Maharashtra',
                            );
                            setModalState(() {
                              fullAddrCtrl.text = picked.fullAddress;
                              initial = initial.copyWith(
                                fullAddress: picked.fullAddress,
                                area: picked.area,
                                city: picked.city,
                                state: picked.state,
                                pincode: picked.pincode,
                                latitude: picked.latitude,
                                longitude: picked.longitude,
                              );
                              if (picked.area.isNotEmpty) {
                                selectedArea = picked.area;
                                areaCtrl.text = picked.area;
                              }
                              if (picked.state.isNotEmpty &&
                                  LocationData.getStates(selectedCountry).contains(picked.state)) {
                                selectedState = picked.state;
                              }
                              if (match != null) {
                                selectedDistrict = match['district'];
                                if (match['taluka'] != null &&
                                    match['taluka']!.isNotEmpty &&
                                    LocationData.getTalukas(selectedDistrict!).contains(match['taluka'])) {
                                  selectedTaluka = match['taluka'];
                                }
                                if (match['area'] != null && match['area']!.isNotEmpty) {
                                  selectedArea = match['area'];
                                  areaCtrl.text = match['area']!;
                                }
                              }
                            });
                          }
                        },
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Landmark
                  TextField(
                    controller: landmarkCtrl,
                    decoration: InputDecoration(
                      labelText: 'Landmark (Optional)',
                      prefixIcon: const Icon(Icons.flag_outlined, color: _brandOrange, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Quick Location Search Banner ────────────────────────────
                  GestureDetector(
                    onTap: () async {
                      final result = await _showUnifiedLocationSearchModal(context);
                      if (result != null) {
                        setModalState(() {
                          if (result['state'] != null && result['state']!.isNotEmpty) {
                            selectedState = result['state'];
                          }
                          if (result['district'] != null && result['district']!.isNotEmpty) {
                            selectedDistrict = result['district'];
                          }
                          if (result['taluka'] != null && result['taluka']!.isNotEmpty) {
                            selectedTaluka = result['taluka'];
                          }
                          if (result['area'] != null && result['area']!.isNotEmpty) {
                            selectedArea = result['area'];
                            areaCtrl.text = result['area']!;
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
                              'Quick Search Location (Area / Taluka / District)...',
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
                  const SizedBox(height: 14),

                  // Country Selector
                  _buildSearchableSelectTile(
                    label: 'Country *',
                    value: selectedCountry,
                    placeholder: 'Select Country',
                    icon: Icons.public_rounded,
                    onTap: () async {
                      final picked = await _showSearchPicker(
                        context: context,
                        title: 'Select Country',
                        items: LocationData.countries,
                        selectedItem: selectedCountry,
                      );
                      if (picked != null) {
                        setModalState(() {
                          selectedCountry = picked;
                          selectedState = null;
                          selectedDistrict = null;
                          selectedTaluka = null;
                          selectedArea = null;
                          areaCtrl.clear();
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // State Selector
                  _buildSearchableSelectTile(
                    label: 'State *',
                    value: selectedState,
                    placeholder: 'Select State *',
                    icon: Icons.account_balance_rounded,
                    onTap: () async {
                      final states = LocationData.getStates(selectedCountry);
                      final picked = await _showSearchPicker(
                        context: context,
                        title: 'Select State',
                        items: states,
                        selectedItem: selectedState,
                      );
                      if (picked != null) {
                        setModalState(() {
                          selectedState = picked;
                          selectedDistrict = null;
                          selectedTaluka = null;
                          selectedArea = null;
                          areaCtrl.clear();
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // District Selector
                  _buildSearchableSelectTile(
                    label: 'District *',
                    value: selectedDistrict,
                    placeholder: selectedState == null ? 'Select State First' : 'Select District *',
                    icon: Icons.location_city_rounded,
                    enabled: selectedState != null,
                    onTap: () async {
                      final districts = LocationData.getDistricts(selectedState!);
                      final picked = await _showSearchPicker(
                        context: context,
                        title: 'Select District ($selectedState)',
                        items: districts,
                        selectedItem: selectedDistrict,
                      );
                      if (picked != null) {
                        setModalState(() {
                          selectedDistrict = picked;
                          selectedTaluka = null;
                          selectedArea = null;
                          areaCtrl.clear();
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Taluka Selector
                  _buildSearchableSelectTile(
                    label: 'Taluka *',
                    value: selectedTaluka,
                    placeholder: selectedDistrict == null ? 'Select District First' : 'Select Taluka *',
                    icon: Icons.holiday_village_rounded,
                    enabled: selectedDistrict != null,
                    onTap: () async {
                      final talukas = LocationData.getTalukas(selectedDistrict!);
                      final picked = await _showSearchPicker(
                        context: context,
                        title: 'Select Taluka ($selectedDistrict)',
                        items: talukas,
                        selectedItem: selectedTaluka,
                      );
                      if (picked != null) {
                        setModalState(() {
                          selectedTaluka = picked;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),

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
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                          ),
                          if (selectedDistrict != null)
                            GestureDetector(
                              onTap: () async {
                                final areas = LocationData.getAreas(selectedDistrict!);
                                final picked = await _showSearchPicker(
                                  context: context,
                                  title: 'Select Area ($selectedDistrict)',
                                  items: areas,
                                  selectedItem: areaCtrl.text.isNotEmpty ? areaCtrl.text : selectedArea,
                                  allowCustom: true,
                                  hintText: 'Search or enter area name...',
                                );
                                if (picked != null) {
                                  setModalState(() {
                                    selectedArea = picked;
                                    areaCtrl.text = picked;
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
                      const SizedBox(height: 6),
                      TextField(
                        controller: areaCtrl,
                        decoration: InputDecoration(
                          hintText: selectedDistrict == null
                              ? 'Select District first to pick area'
                              : 'Type or search Area (e.g. Kothrud, Hinjawadi...)',
                          prefixIcon: const Icon(Icons.near_me_outlined, color: _brandOrange, size: 20),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search_rounded, color: _brandOrange),
                            tooltip: 'Search & Pick Area',
                            onPressed: selectedDistrict == null
                                ? null
                                : () async {
                                    final areas = LocationData.getAreas(selectedDistrict!);
                                    final picked = await _showSearchPicker(
                                      context: context,
                                      title: 'Select Area ($selectedDistrict)',
                                      items: areas,
                                      selectedItem: areaCtrl.text.isNotEmpty ? areaCtrl.text : selectedArea,
                                      allowCustom: true,
                                      hintText: 'Search or enter area...',
                                    );
                                    if (picked != null) {
                                      setModalState(() {
                                        selectedArea = picked;
                                        areaCtrl.text = picked;
                                      });
                                    }
                                  },
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onChanged: (val) {
                          selectedArea = val;
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty) {
                          setModalState(() => formErrorMessage = 'Please enter receiver name');
                          return;
                        }
                        if (mobileCtrl.text.trim().isEmpty) {
                          setModalState(() => formErrorMessage = 'Please enter mobile number');
                          return;
                        }
                        if (fullAddrCtrl.text.trim().isEmpty) {
                          setModalState(() => formErrorMessage = 'Please enter full address');
                          return;
                        }
                        if (selectedState == null || selectedState!.trim().isEmpty) {
                          setModalState(() => formErrorMessage = 'Please select your State *');
                          return;
                        }
                        if (selectedDistrict == null || selectedDistrict!.trim().isEmpty) {
                          setModalState(() => formErrorMessage = 'Please select your District *');
                          return;
                        }
                        if (selectedTaluka == null || selectedTaluka!.trim().isEmpty) {
                          setModalState(() => formErrorMessage = 'Please select your Taluka *');
                          return;
                        }

                        final resolvedArea = areaCtrl.text.trim().isNotEmpty
                            ? areaCtrl.text.trim()
                            : (selectedArea?.trim() ?? initial.area);

                        final newAddr = AddressData(
                          id: editAddress?.id,
                          name: nameCtrl.text.trim(),
                          mobileNumber: mobileCtrl.text.trim(),
                          tag: selectedTag,
                          houseNo: houseCtrl.text.trim(),
                          fullAddress: fullAddrCtrl.text.trim(),
                          landmark: landmarkCtrl.text.trim(),
                          area: resolvedArea,
                          city: initial.city.isNotEmpty ? initial.city : (selectedDistrict ?? ''),
                          state: selectedState!,
                          district: selectedDistrict!,
                          taluka: selectedTaluka!,
                          country: selectedCountry,
                          pincode: initial.pincode,
                          latitude: initial.latitude,
                          longitude: initial.longitude,
                          isDefault: editAddress?.isDefault ?? false,
                        );

                        final res = await AddressService.instance.saveAddress(newAddr);
                        if (res.success) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(res.message),
                                backgroundColor: const Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            Navigator.pop(ctx);
                          }
                          if (mounted) {
                            _loadAddresses();
                          }
                        } else {
                          setModalState(() {
                            formErrorMessage = res.message;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _brandOrange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Save Address',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
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

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isWide = mq.size.width > 600;

    return Scaffold(
      backgroundColor: _bgWarm,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWide ? 540 : double.infinity),
            child: Column(
              children: [
                // ── Top Navigation Bar ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(Icons.chevron_left_rounded, color: _ink, size: 28),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Saved Addresses',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: _ink,
                                ),
                              ),
                              Text(
                                'Select or manage your locations',
                                style: TextStyle(fontSize: 12, color: _greySub),
                              ),
                            ],
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () async {
                          final picked = await Navigator.push<AddressData>(
                            context,
                            MaterialPageRoute(builder: (_) => const SelectAddressScreen()),
                          );
                          if (picked != null) {
                            _openAddressForm(pickedMapAddress: picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: _brandOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _brandOrange.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.add_location_alt_rounded, size: 16, color: _brandOrange),
                              SizedBox(width: 4),
                              Text(
                                'Add New',
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
                ),
                const Divider(height: 1, color: _cardBorder),

                // ── Addresses List ────────────────────────────────────────────
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: _brandOrange))
                      : _addresses.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.location_off_rounded, size: 54, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No Saved Addresses Found',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ink),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Add your home, office, or other locations.',
                                    style: TextStyle(fontSize: 13, color: _greySub),
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      final picked = await Navigator.push<AddressData>(
                                        context,
                                        MaterialPageRoute(builder: (_) => const SelectAddressScreen()),
                                      );
                                      if (picked != null) {
                                        _openAddressForm(pickedMapAddress: picked);
                                      }
                                    },
                                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                                    label: const Text('Add Address Now', style: TextStyle(color: Colors.white)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _brandOrange,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _addresses.length,
                              itemBuilder: (ctx, idx) {
                                final addr = _addresses[idx];
                                return _buildAddressCard(addr);
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressCard(AddressData addr) {
    IconData tagIcon = Icons.home_rounded;
    if (addr.tag == 'OFFICE') tagIcon = Icons.work_rounded;
    if (addr.tag == 'OTHER') tagIcon = Icons.location_on_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: addr.isDefault ? _brandOrange : _cardBorder,
          width: addr.isDefault ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _selectDefault(addr),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _brandOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(tagIcon, size: 14, color: _brandOrange),
                            const SizedBox(width: 5),
                            Text(
                              addr.tag,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                                color: _brandOrange,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (addr.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'DEFAULT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF166534),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Action Buttons: Edit & Delete
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: _greySub, size: 20),
                        onPressed: () => _openAddressForm(editAddress: addr),
                        tooltip: 'Edit Address',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: _redDark, size: 20),
                        onPressed: () => _deleteAddress(addr),
                        tooltip: 'Delete Address',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              if (addr.name.isNotEmpty || addr.mobileNumber.isNotEmpty) ...[
                Row(
                  children: [
                    if (addr.name.isNotEmpty)
                      Text(
                        addr.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                    if (addr.name.isNotEmpty && addr.mobileNumber.isNotEmpty)
                      const Text('  •  ', style: TextStyle(color: _greySub, fontSize: 12)),
                    if (addr.mobileNumber.isNotEmpty)
                      Text(
                        addr.mobileNumber,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: _greySub,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
              ],

              Text(
                addr.secondaryLabel,
                style: const TextStyle(
                  fontSize: 13,
                  color: _greySub,
                  height: 1.35,
                ),
              ),

              if (addr.area.isNotEmpty || addr.landmark.isNotEmpty) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (addr.area.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _brandOrange.withOpacity(0.3)),
                        ),
                        child: Text(
                          'Area: ${addr.area}',
                          style: const TextStyle(fontSize: 11.5, color: _brandOrange, fontWeight: FontWeight.w700),
                        ),
                      ),
                    if (addr.landmark.isNotEmpty)
                      Text(
                        'Landmark: ${addr.landmark}',
                        style: const TextStyle(fontSize: 12, color: _greySub, fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
