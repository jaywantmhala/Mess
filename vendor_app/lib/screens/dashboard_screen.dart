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
        vsync: this, duration: const Duration(milliseconds: 600));
    _headerFade =
        CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
            .animate(CurvedAnimation(
                parent: _headerCtrl, curve: Curves.easeOutCubic));
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.surfaceCard,
        title: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.errorSurface, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Text('Remove Listing?',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink))),
        ]),
        content: Text('Are you sure you want to remove "${hotel.hotelName}"? This cannot be undone.',
            style: AppText.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: AppText.bodyMedium.copyWith(fontWeight: FontWeight.w600))),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _isLoading = true);
      final res = await HotelService.instance.deleteHotel(hotel.id);
      if (!mounted) return;
      if (res.success) { _showSuccess(res.message); _loadHotels(); }
      else { setState(() => _isLoading = false); _showErrorDialog(res.message); }
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Container(width: 28, height: 28,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 16)),
        const SizedBox(width: 12),
        Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600))),
      ]),
      backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _showErrorDialog(String message) {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Error', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
      content: Text(message, style: AppText.bodyMedium),
      actions: [TextButton(onPressed: () => Navigator.pop(context),
          child: const Text('OK', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)))],
    ));
  }

  Future<void> _navigateToAddHotel() async {
    final added = await Navigator.push<bool>(
      context, MaterialPageRoute(builder: (_) => const AddHotelScreen()),
    );
    if (added == true) _loadHotels();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final hPad = Responsive.hPad(context);
    final bottomPad = mq.padding.bottom + 90;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))
          : RefreshIndicator(
              onRefresh: _loadHotels,
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceCard,
              displacement: 60,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                slivers: [
                  SliverToBoxAdapter(child: _buildHeroHeader(context)),
                  SliverToBoxAdapter(child: _buildStatsRow(hPad)),
                  if (_hotels.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Your Properties',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w800,
                                    color: AppColors.ink, letterSpacing: -0.3)),
                            GestureDetector(
                              onTap: _navigateToAddHotel,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: AppShadows.elevated,
                                ),
                                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.add_rounded, color: Colors.white, size: 16),
                                  SizedBox(width: 4),
                                  Text('Add', style: TextStyle(color: Colors.white,
                                      fontWeight: FontWeight.w700, fontSize: 13)),
                                ]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  _hotels.isEmpty
                      ? SliverFillRemaining(child: _buildEmptyView(bottomPad))
                      : SliverPadding(
                          padding: EdgeInsets.fromLTRB(hPad, 0, hPad, bottomPad),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) => _HotelCard(
                                hotel: _hotels[i], index: i,
                                onEdit: () => _editHotel(_hotels[i]),
                                onDelete: () => _confirmDelete(_hotels[i]),
                              ),
                              childCount: _hotels.length,
                            ),
                          ),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(children: [
        Positioned(top: -30, right: -40,
            child: Container(width: 180, height: 180,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.07)))),
        Positioned(bottom: 10, left: -20,
            child: Container(width: 120, height: 120,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05)))),
        Padding(
          padding: EdgeInsets.fromLTRB(24, topPad + 20, 24, 28),
          child: SlideTransition(
            position: _headerSlide,
            child: FadeTransition(
              opacity: _headerFade,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
                    ),
                    child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('ZenQube Vendor',
                        style: TextStyle(color: Colors.white.withOpacity(0.75),
                            fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                    const Text('Vendor Dashboard',
                        style: TextStyle(color: Colors.white, fontSize: 20,
                            fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                  ])),
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
                  ),
                ]),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 8, height: 8,
                        decoration: const BoxDecoration(color: Color(0xFF69F0AE), shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(
                      '${_hotels.length} propert${_hotels.length == 1 ? 'y' : 'ies'} active',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildStatsRow(double hPad) {
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 0),
      child: Row(children: [
        Expanded(child: _StatCard(label: 'Properties', value: '${_hotels.length}',
            icon: Icons.storefront_rounded, gradient: AppColors.primaryGradient, shadowColor: AppColors.primary)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: 'Open Now', value: '${_hotels.length}',
            icon: Icons.check_circle_outline_rounded, gradient: AppColors.statsGradient,
            shadowColor: const Color(0xFF00B894))),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: "Today's Orders", value: '—',
            icon: Icons.receipt_long_rounded, gradient: AppColors.accentGradient,
            shadowColor: AppColors.accent)),
      ]),
    );
  }

  Widget _buildEmptyView(double bottomPad) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomPad, top: 20, left: 32, right: 32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(gradient: AppColors.sunsetGradient,
                  shape: BoxShape.circle, boxShadow: AppShadows.elevated),
              child: const Icon(Icons.storefront_rounded, size: 54, color: Colors.white),
            ),
            const SizedBox(height: 28),
            const Text('No Properties Yet', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                    color: AppColors.ink, letterSpacing: -0.4)),
            const SizedBox(height: 10),
            const Text('Add your first hotel or restaurant\nto start receiving orders.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6)),
            const SizedBox(height: 32),
            AppPrimaryButton(label: 'Add Your First Property', icon: Icons.add_rounded,
                onPressed: _navigateToAddHotel),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat Card
// ─────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final LinearGradient gradient;
  final Color shadowColor;

  const _StatCard({required this.label, required this.value, required this.icon,
      required this.gradient, required this.shadowColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: shadowColor.withOpacity(0.28),
            blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 34, height: 34,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.white, size: 18)),
        const SizedBox(height: 10),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 22,
            fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1)),
        const SizedBox(height: 3),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white.withOpacity(0.8),
                fontSize: 11, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hotel Card
// ─────────────────────────────────────────────────────────────────────────────

class _HotelCard extends StatefulWidget {
  final Hotel hotel;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HotelCard({required this.hotel, required this.index,
      required this.onEdit, required this.onDelete});

  @override
  State<_HotelCard> createState() => _HotelCardState();
}

class _HotelCardState extends State<_HotelCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: 80 * widget.index), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final h = widget.hotel;
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: AppShadows.card,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildBanner(h.photoUrl),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Expanded(child: Text(h.hotelName,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                          color: AppColors.ink, letterSpacing: -0.3),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.successSurface, borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.success.withOpacity(0.3), width: 1),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.circle, color: AppColors.success, size: 7),
                      SizedBox(width: 5),
                      Text('Active', style: TextStyle(fontSize: 11,
                          fontWeight: FontWeight.w700, color: AppColors.success)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 6, children: [
                  _chip(Icons.person_outline_rounded, h.ownerName),
                  if ((h.city ?? '').isNotEmpty) _chip(Icons.location_city_rounded, h.city!),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.location_on_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 5),
                  Expanded(child: Text(h.address,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500, height: 1.4),
                      maxLines: 2, overflow: TextOverflow.ellipsis)),
                ]),
                const SizedBox(height: 14),
                Divider(height: 1, color: AppColors.border.withOpacity(0.7)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(child: Text(h.contactNo,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                              color: AppColors.inkMid),
                          maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ]),
                  )),
                  const SizedBox(width: 10),
                  _actionBtn(Icons.edit_rounded, const Color(0xFF3B82F6),
                      const Color(0xFFEFF6FF), 'Edit', widget.onEdit),
                  const SizedBox(width: 8),
                  _actionBtn(Icons.delete_rounded, AppColors.error,
                      AppColors.errorSurface, 'Remove', widget.onDelete),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildBanner(String? photoUrl) {
    final hasImage = photoUrl != null && photoUrl.isNotEmpty;
    return SizedBox(
      height: 160, width: double.infinity,
      child: hasImage
          ? Image.network(photoUrl, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholderBanner())
          : _placeholderBanner(),
    );
  }

  Widget _placeholderBanner() {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.sunsetGradient),
      child: Stack(children: [
        Positioned(top: 10, right: 20,
            child: Container(width: 80, height: 80,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08)))),
        Positioned(bottom: -15, right: 60,
            child: Container(width: 100, height: 100,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06)))),
        Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 56, height: 56,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 28)),
          const SizedBox(height: 8),
          Text('No Photo Added',
              style: TextStyle(color: Colors.white.withOpacity(0.8),
                  fontSize: 12, fontWeight: FontWeight.w500)),
        ])),
      ]),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
            color: AppColors.textSecondary)),
      ]),
    );
  }

  Widget _actionBtn(IconData icon, Color color, Color bg, String label, VoidCallback onTap) {
    return Material(
      color: bg, borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ]),
        ),
      ),
    );
  }
}
