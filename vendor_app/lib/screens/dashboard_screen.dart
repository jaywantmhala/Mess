// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import '../models/hotel.dart';
import '../services/hotel_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import 'add_hotel_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  List<Hotel> _hotels = [];
  bool _isLoading = true;

  late AnimationController _headerCtrl;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _headerFade =
        CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, -0.1), end: Offset.zero).animate(
            CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic));
    _loadHotels();
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHotels() async {
    setState(() => _isLoading = true);
    final hotels = await HotelService.instance.getHotels();
    if (mounted) {
      setState(() {
        _hotels = hotels;
        _isLoading = false;
      });
      _headerCtrl.forward(from: 0);
    }
  }

  Future<void> _editHotel(Hotel hotel) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddHotelScreen(hotel: hotel)),
    );
    if (updated == true) _loadHotels();
  }

  Future<void> _confirmDelete(Hotel hotel) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: AppColors.errorSurface,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Delete Listing?',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink)),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${hotel.hotelName}"? This action cannot be undone.',
          style: AppText.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: AppText.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final res = await HotelService.instance.deleteHotel(hotel.id);
      if (!mounted) return;
      if (res.success) {
        _showSuccess(res.message);
        _loadHotels();
      } else {
        setState(() => _isLoading = false);
        _showErrorDialog(res.message);
      }
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Text(message,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Error',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
        content: Text(message, style: AppText.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final w = mq.size.width;
    final isTablet = w >= 600;
    final hPad = Responsive.hPad(context);
    final bottomPad = mq.padding.bottom + 90; // clear floating navbar

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          _buildSliverAppBar(hPad, isTablet),
        ],
        body: _isLoading
            ? const _LoadingView()
            : RefreshIndicator(
                onRefresh: _loadHotels,
                color: AppColors.primary,
                backgroundColor: AppColors.surfaceCard,
                child: _hotels.isEmpty
                    ? _EmptyView(
                        onAddHotel: _navigateToAddHotel,
                        bottomPad: bottomPad,
                      )
                    : _HotelListView(
                        hotels: _hotels,
                        isTablet: isTablet,
                        hPad: hPad,
                        bottomPad: bottomPad,
                        onAddHotel: _navigateToAddHotel,
                        onEdit: _editHotel,
                        onDelete: _confirmDelete,
                      ),
              ),
      ),
    );
  }

  Future<void> _navigateToAddHotel() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddHotelScreen()),
    );
    if (added == true) _loadHotels();
  }

  Widget _buildSliverAppBar(double hPad, bool isTablet) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: AppColors.surfaceCard,
      surfaceTintColor: Colors.transparent,
      expandedHeight: isTablet ? 120 : 100,
      titleSpacing: hPad,
      leading: const SizedBox.shrink(),
      leadingWidth: 0,
      title: SlideTransition(
        position: _headerSlide,
        child: FadeTransition(
          opacity: _headerFade,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Vendor Dashboard',
                style: AppText.headingLarge.copyWith(
                  fontSize: isTablet ? 22 : 20,
                ),
              ),
              Text(
                '${_hotels.length} propert${_hotels.length == 1 ? 'y' : 'ies'} registered',
                style: AppText.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: AppColors.border),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.primary,
        strokeWidth: 2.5,
      ),
    );
  }
}

class _AddFAB extends StatelessWidget {
  final VoidCallback onTap;

  const _AddFAB({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.elevated,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.add_rounded, color: Colors.white, size: 22),
                SizedBox(width: 8),
                Text(
                  'Add Hotel',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onAddHotel;
  final double bottomPad;

  const _EmptyView({required this.onAddHotel, required this.bottomPad});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: EdgeInsets.only(bottom: bottomPad, top: 40, left: 24, right: 24),
          children: [
            const SizedBox(height: 60),
            Center(
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.elevated,
                ),
                child: const Icon(Icons.hotel_rounded,
                    size: 50, color: Colors.white),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'No Properties Yet',
              textAlign: TextAlign.center,
              style: AppText.headingMedium.copyWith(color: AppColors.ink),
            ),
            const SizedBox(height: 10),
            Text(
              'Start by adding your first hotel property\nto begin attracting guests.',
              textAlign: TextAlign.center,
              style: AppText.bodyMedium.copyWith(height: 1.6),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: AppPrimaryButton(
                label: 'Add Your First Hotel',
                icon: Icons.add_rounded,
                onPressed: onAddHotel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HotelListView extends StatelessWidget {
  final List<Hotel> hotels;
  final bool isTablet;
  final double hPad;
  final double bottomPad;
  final void Function(Hotel) onEdit;
  final void Function(Hotel) onDelete;
  final VoidCallback onAddHotel;

  const _HotelListView({
    required this.hotels,
    required this.isTablet,
    required this.hPad,
    required this.bottomPad,
    required this.onEdit,
    required this.onDelete,
    required this.onAddHotel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(hPad, 20, hPad, bottomPad),
          itemCount: hotels.length + 1,
          itemBuilder: (ctx, i) {
            if (i == 0) {
              return _InlineAddHotelCard(onTap: onAddHotel);
            }
            final hotelIndex = i - 1;
            return _HotelCard(
              hotel: hotels[hotelIndex],
              index: hotelIndex,
              onEdit: () => onEdit(hotels[hotelIndex]),
              onDelete: () => onDelete(hotels[hotelIndex]),
            );
          },
        ),
      ),
    );
  }
}

class _InlineAddHotelCard extends StatelessWidget {
  final VoidCallback onTap;
  const _InlineAddHotelCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.add_business_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add New Property', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Text('Tap here to list another hotel or restaurant.', style: TextStyle(fontSize: 13, color: AppColors.primary.withOpacity(0.8), fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HotelCard extends StatefulWidget {
  final Hotel hotel;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HotelCard({
    required this.hotel,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_HotelCard> createState() => _HotelCardState();
}

class _HotelCardState extends State<_HotelCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
            begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: 60 * widget.index), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.hotel;

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: AppShadows.card,
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image Banner (Compact) ──
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 110,
                  height: 110,
                  child: (h.photoUrl != null && h.photoUrl!.isNotEmpty)
                      ? Image.network(
                          h.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _CompactPlaceholder(),
                        )
                      : _CompactPlaceholder(),
                ),
              ),
              const SizedBox(width: 16),
              // ── Content ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + status
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            h.hotelName,
                            style: AppText.headingMedium.copyWith(fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusBadge(),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Info rows
                    _CompactInfoRow(icon: Icons.person_rounded, value: h.ownerName),
                    const SizedBox(height: 6),
                    _CompactInfoRow(icon: Icons.location_on_rounded, value: h.address),
                    
                    const SizedBox(height: 12),
                    Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: 12),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _ActionButton(
                          icon: Icons.edit_rounded,
                          color: const Color(0xFF3B82F6),
                          bgColor: const Color(0xFFEFF6FF),
                          tooltip: 'Edit',
                          onTap: widget.onEdit,
                        ),
                        const SizedBox(width: 8),
                        _ActionButton(
                          icon: Icons.delete_rounded,
                          color: AppColors.error,
                          bgColor: AppColors.errorSurface,
                          tooltip: 'Delete',
                          onTap: widget.onDelete,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primarySurface,
      child: Center(
        child: Icon(Icons.storefront_rounded, size: 36, color: AppColors.primary.withOpacity(0.5)),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.successSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.circle, color: AppColors.success, size: 7),
          SizedBox(width: 5),
          Text(
            'Active',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactInfoRow extends StatelessWidget {
  final IconData icon;
  final String value;

  const _CompactInfoRow({
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textHint),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }
}
