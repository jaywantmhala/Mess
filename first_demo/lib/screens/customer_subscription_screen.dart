// lib/screens/customer_subscription_screen.dart

import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';

import 'package:audioplayers/audioplayers.dart';

import '../services/hotel_service.dart';

import '../services/address_service.dart';

import '../services/payu_service.dart';

import '../services/payu_checkout_screen.dart';

import '../services/wallet_service.dart';

import '../models/subscription_plan.dart';



class CustomerSubscriptionScreen extends StatefulWidget {

const CustomerSubscriptionScreen({super.key});



@override

State<CustomerSubscriptionScreen> createState() => _CustomerSubscriptionScreenState();

}



class _CustomerSubscriptionScreenState extends State<CustomerSubscriptionScreen> {

// ── Design Tokens matching reference photo 100% ────────────────────────────

static const Color _brandOrange  = Color(0xFFF58220);

static const Color _bgWarm       = Color(0xFFFAFAFA);

static const Color _white        = Colors.white;

static const Color _ink          = Color(0xFF1A1A2E);

static const Color _greySub      = Color(0xFF6B7280);

static const Color _cardBorder   = Color(0xFFE5E7EB);

static const Color _activeBg     = Color(0xFFFFF7ED);

static const Color _popularTag   = Color(0xFFFFF0E6);



List<SubscriptionPlan> _plans = [];

ServiceLocation? _serviceLocation;

Map<String, dynamic>? _currentSub;

int _selectedIndex = 0; // Default selected plan: Monthly Plan

bool _isLoading = true;

bool _isSubmitting = false;



@override

void initState() {

super.initState();

_fetchPlans();

}



Future<void> _fetchPlans() async {

setState(() => _isLoading = true);



// 1. Fetch current subscription

try {

final currentResult = await HotelService.instance.getCurrentSubscription();

_currentSub = currentResult?['subscription'];

} catch (e) {

debugPrint('Error fetching current subscription: $e');

}



// 2. Fetch plans list

try {

final addr = await AddressService.instance.getAddress();

double lat = 18.5204, lng = 73.8567;

String? pincode;

String? fullAddr;

if (addr != null && addr.latitude != 0.0) {

lat = addr.latitude;

lng = addr.longitude;

pincode = addr.pincode;

fullAddr = addr.fullAddress;

}



final result = await HotelService.instance.getServiceablePlans(

latitude: lat,

longitude: lng,

pincode: pincode,

address: fullAddr,

);



if (mounted && result.plans.isNotEmpty) {

setState(() {

_plans = result.plans;

_serviceLocation = result.serviceLocation;

_isLoading = false;

});

return;

}

} catch (e) {

debugPrint('Error fetching serviceable plans: $e');

}



// Fallback default plans

if (mounted) {

setState(() {

_plans = [

const SubscriptionPlan(

id: 1,

subAreaId: 1,

planName: 'Monthly Plan',

price: 199.0,

duration: 30,

totalDeliveries: 30,

mealsPerDay: 1,

mealType: 'VEG',

deliveryTimeSlot: 'LUNCH',

discount: 0.0,

deliveryCharge: 0.0,

isActive: true,

description: '30 Days Validity',

),

const SubscriptionPlan(

id: 2,

subAreaId: 1,

planName: 'Quarterly Plan',

price: 499.0,

duration: 90,

totalDeliveries: 90,

mealsPerDay: 1,

mealType: 'VEG',

deliveryTimeSlot: 'LUNCH',

discount: 0.0,

deliveryCharge: 0.0,

isActive: true,

description: '90 Days Validity',

),

const SubscriptionPlan(

id: 3,

subAreaId: 1,

planName: 'Yearly Plan',

price: 1499.0,

duration: 365,

totalDeliveries: 365,

mealsPerDay: 1,

mealType: 'VEG',

deliveryTimeSlot: 'LUNCH',

discount: 0.0,

deliveryCharge: 0.0,

isActive: true,

description: '365 Days Validity',

),

];

_isLoading = false;

});

}

}



Widget _buildServiceAreaInfoCard(ServiceLocation sl) {

final areaTiffin = sl.tiffinCharge > 0 ? sl.tiffinCharge : 50.0;

return Container(

padding: const EdgeInsets.all(16),

decoration: BoxDecoration(

color: _white,

borderRadius: BorderRadius.circular(18),

border: Border.all(color: const Color(0xFFFED7AA), width: 1.2),

boxShadow: [

BoxShadow(

color: const Color(0xFFF58220).withOpacity(0.06),

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

width: 38,

height: 38,

decoration: BoxDecoration(

color: const Color(0xFFFFF7ED),

borderRadius: BorderRadius.circular(10),

),

child: const Center(

child: Icon(Icons.location_on_rounded, color: _brandOrange, size: 20),

),

),

const SizedBox(width: 10),

Expanded(

child: Column(

crossAxisAlignment: CrossAxisAlignment.start,

children: [

Row(

children: [

Flexible(

child: Text(

sl.locationName.isNotEmpty ? sl.locationName : 'Service Area',

style: const TextStyle(

fontSize: 16,

fontWeight: FontWeight.w900,

color: _ink,

),

overflow: TextOverflow.ellipsis,

),

),

const SizedBox(width: 6),

Container(

padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),

decoration: BoxDecoration(

color: const Color(0xFFEFF6FF),

borderRadius: BorderRadius.circular(6),

),

child: const Text(

'Coverage Zone',

style: TextStyle(

fontSize: 10,

fontWeight: FontWeight.w700,

color: Color(0xFF2563EB),

),

),

),

],

),

if (sl.address.isNotEmpty) ...[

const SizedBox(height: 2),

Text(

sl.address,

maxLines: 1,

overflow: TextOverflow.ellipsis,

style: const TextStyle(

fontSize: 12,

color: _greySub,

fontWeight: FontWeight.w500,

),

),

],

],

),

),

],

),

const SizedBox(height: 12),

Container(

padding: const EdgeInsets.all(12),

decoration: BoxDecoration(

color: const Color(0xFFFFFBEB),

borderRadius: BorderRadius.circular(12),

border: Border.all(color: const Color(0xFFFDE68A)),

),

child: Row(

children: [

Expanded(

child: Column(

crossAxisAlignment: CrossAxisAlignment.start,

children: [

Row(

children: [

const Icon(Icons.radar_rounded, size: 14, color: Color(0xFFB45309)),

const SizedBox(width: 4),

Text(

'${sl.radiusKm.toStringAsFixed(1)} km radius (${sl.distanceKm > 0 ? "${sl.distanceKm.toStringAsFixed(1)} km away" : "Coverage Area"})',

style: const TextStyle(

fontSize: 11.5,

fontWeight: FontWeight.w700,

color: Color(0xFF92400E),

),

),

],

),

if (sl.latitude != 0.0 && sl.longitude != 0.0) ...[

const SizedBox(height: 4),

Text(

'Coordinates: ${sl.latitude.toStringAsFixed(4)}, ${sl.longitude.toStringAsFixed(4)}',

style: TextStyle(

fontSize: 10,

color: Colors.amber.shade900.withOpacity(0.85),

fontWeight: FontWeight.w600,

),

),

],

],

),

),

Container(

padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),

decoration: BoxDecoration(

color: sl.hasDiscount ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),

borderRadius: BorderRadius.circular(8),

border: Border.all(color: sl.hasDiscount ? const Color(0xFF86EFAC) : const Color(0xFFFCD34D)),

),

child: Column(

crossAxisAlignment: CrossAxisAlignment.end,

children: [

Row(

mainAxisSize: MainAxisSize.min,

children: [

Text(

'Area Tiffin Fee',

style: TextStyle(

fontSize: 9.5,

fontWeight: FontWeight.w600,

color: sl.hasDiscount ? const Color(0xFF166534) : const Color(0xFF92400E),

),

),

if (sl.hasDiscount) ...[

const SizedBox(width: 4),

Container(

padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),

decoration: BoxDecoration(

color: const Color(0xFF16A34A),

borderRadius: BorderRadius.circular(4),

),

child: Text(

'${sl.discountPercentage.toStringAsFixed(0)}% OFF',

style: const TextStyle(

fontSize: 8.5,

fontWeight: FontWeight.w800,

color: Colors.white,

),

),

),

],

],

),

const SizedBox(height: 2),

Row(

mainAxisSize: MainAxisSize.min,

children: [

if (sl.hasDiscount) ...[

Text(

'₹${sl.originalTiffinCharge.toStringAsFixed(0)}',

style: const TextStyle(

fontSize: 11,

fontWeight: FontWeight.w600,

color: Color(0xFF9CA3AF),

decoration: TextDecoration.lineThrough,

),

),

const SizedBox(width: 4),

],

Text(

'₹${areaTiffin.toStringAsFixed(0)} / order',

style: TextStyle(

fontSize: 14,

fontWeight: FontWeight.w900,

color: sl.hasDiscount ? const Color(0xFF15803D) : const Color(0xFFB45309),

),

),

],

),

],

),

),

],

),

),

const SizedBox(height: 8),

Row(

children: const [

Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFF059669)),

SizedBox(width: 5),

Expanded(

child: Text(

'Tiffin charge is deducted from your wallet for each order placed in this area.',

style: TextStyle(

fontSize: 11,

fontWeight: FontWeight.w600,

color: Color(0xFF059669),

),

),

),

],

),

],

),

);

}



Widget _buildCurrentSubscriptionCard(Map<String, dynamic> sub) {

final planName = sub['plan_name'] ?? 'Subscription Plan';

final status = (sub['status'] ?? 'EXPIRED').toString().toUpperCase();

final remaining = sub['remaining_deliveries'] ?? 0;

final total = sub['total_deliveries'] ?? 0;

final endDateStr = sub['end_date'] ?? '';

final planId = sub['plan_id'] as int? ?? 1;



final bool isExpired = status == 'EXPIRED';

final Color cardBg = isExpired ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4);

final Color borderCol = isExpired ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC);

final Color textCol = isExpired ? const Color(0xFF991B1B) : const Color(0xFF166534);

final Color badgeBg = isExpired ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7);



// Calculate days left

final endDate = DateTime.tryParse(sub['end_date'] ?? '');

final int? daysLeft = endDate?.difference(DateTime.now()).inDays;



return Container(

decoration: BoxDecoration(

color: cardBg,

borderRadius: BorderRadius.circular(20),

border: Border.all(color: borderCol, width: 1.5),

boxShadow: [

BoxShadow(

color: Colors.black.withOpacity(0.02),

blurRadius: 10,

offset: const Offset(0, 4),

),

],

),

padding: const EdgeInsets.all(16),

child: Column(

crossAxisAlignment: CrossAxisAlignment.start,

children: [

Row(

mainAxisAlignment: MainAxisAlignment.spaceBetween,

children: [

Expanded(

child: Text(

planName,

style: const TextStyle(

fontSize: 17,

fontWeight: FontWeight.w900,

color: _ink,

),

),

),

Container(

padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),

decoration: BoxDecoration(

color: badgeBg,

borderRadius: BorderRadius.circular(12),

),

child: Text(

status,

style: TextStyle(

fontSize: 11,

fontWeight: FontWeight.w800,

color: textCol,

letterSpacing: 0.5,

),

),

),

],

),

const SizedBox(height: 8),

Text(

isExpired

? 'This plan has expired. Please renew below to continue service.'

: 'Valid until $endDateStr  |  $remaining of $total deliveries left',

style: const TextStyle(

fontSize: 13,

fontWeight: FontWeight.w500,

color: _greySub,

),

),

if (!isExpired && daysLeft != null) ...[

const SizedBox(height: 8),

Container(

padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),

decoration: BoxDecoration(

color: daysLeft <= 3 ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),

borderRadius: BorderRadius.circular(8),

border: Border.all(

color: daysLeft <= 3 ? Colors.red.withOpacity(0.3) : Colors.orange.withOpacity(0.3),

),

),

child: Text(

daysLeft <= 0 ? 'Expires today' : '$daysLeft days left',

style: TextStyle(

color: daysLeft <= 3 ? Colors.red : Colors.orange.shade700,

fontSize: 11,

fontWeight: FontWeight.w700,

),

),

),

],

const SizedBox(height: 16),

GestureDetector(

onTap: _isSubmitting ? null : () => _processPaymentForPlan(planId),

child: Container(

height: 40,

width: double.infinity,

decoration: BoxDecoration(

color: isExpired ? const Color(0xFFEF4444) : _brandOrange,

borderRadius: BorderRadius.circular(14),

boxShadow: [

BoxShadow(

color: (isExpired ? const Color(0xFFEF4444) : _brandOrange).withOpacity(0.2),

blurRadius: 8,

offset: const Offset(0, 3),

),

],

),

child: Center(

child: _isSubmitting

? const SizedBox(

width: 18,

height: 18,

child: CircularProgressIndicator(color: _white, strokeWidth: 2),

)

: Text(

isExpired ? 'Renew This Plan Now' : 'Extend / Renew This Plan',

style: const TextStyle(

fontSize: 13.5,

fontWeight: FontWeight.w800,

color: _white,

),

),

),

),

),

],

),

);

}



Future<void> _processPayment() async {

if (_plans.isEmpty || _selectedIndex >= _plans.length) return;

final selectedPlan = _plans[_selectedIndex];

await _processPaymentForPlan(selectedPlan.id);

}



  Future<void> _processPaymentForPlan(int planId) async {
    SubscriptionPlan? targetPlan;
    for (final p in _plans) {
      if (p.id == planId) {
        targetPlan = p;
        break;
      }
    }
    if (targetPlan == null && _plans.isNotEmpty) {
      final safeIdx = _selectedIndex.clamp(0, _plans.length - 1);
      targetPlan = _plans[safeIdx];
    }
    if (targetPlan == null) return;

    setState(() => _isSubmitting = true);

    try {
      // Step 1: Create PayU Payment Order on Backend (Live API)
      final orderResult = await PayUService.instance.createOrder(targetPlan.id);

      if (!orderResult.success || orderResult.orderId == null) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(orderResult.message ?? 'Failed to initiate PayU payment.'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
        return;
      }

      // Step 2: Build PayU Checkout Options
      final options = PayUService.instance.buildCheckoutOptions(
        orderId: orderResult.orderId!,
        keyId: orderResult.keyId ?? PayUService.payuMerchantKey,
        amountPaise: orderResult.amountPaise ?? (targetPlan.price * 100).toInt(),
        planName: targetPlan.planName,
        customerName: orderResult.customerName,
        customerEmail: orderResult.customerEmail,
        customerPhone: orderResult.customerPhone,
        hash: orderResult.hash,
        action: orderResult.action,
        surl: orderResult.surl,
        furl: orderResult.furl,
        udf1: orderResult.udf1,
        udf2: orderResult.udf2,
      );
      options['plan_id'] = targetPlan.id;

      if (!mounted) return;

      // Step 3: Launch Live PayU Gateway Checkout
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => PayUCheckoutScreen(
            options: options,
            onSuccess: (verifyResult) async {
              await _handlePaymentSuccess(orderResult.orderId!, targetPlan!);
            },
            onError: (errorMsg) {
              if (!mounted) return;
              setState(() => _isSubmitting = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Payment Failed: '),
                  backgroundColor: const Color(0xFFEF4444),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              );
            },
            onCancelled: () {
              if (!mounted) return;
              setState(() => _isSubmitting = false);
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: '),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
  }

  Future<void> _handlePaymentSuccess(String orderId, SubscriptionPlan selectedPlan) async {
    if (!mounted) return;

    // Refresh wallet balance in app state
    try {
      await WalletService.instance.getBalance();
    } catch (_) {}

    // Play success chime sound safely
    try {
      final player = AudioPlayer();
      if (!kIsWeb) {
        await player.setAudioContext(AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gainTransient,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {AVAudioSessionOptions.mixWithOthers},
          ),
        ));
      }
      await player.setVolume(1.0);
      await player.play(AssetSource('sounds/success.mp3'));
    } catch (e) {
      debugPrint('Audio chime playback skipped: ');
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 Payment Verified! Subscribed to .'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );

    Navigator.pop(context, true);
  }

@override

Widget build(BuildContext context) {

final mq = MediaQuery.of(context);

final isWide = mq.size.width > 600;

final selectedPlan = _plans.isNotEmpty && _selectedIndex < _plans.length

? _plans[_selectedIndex]

: null;



return Scaffold(

backgroundColor: _bgWarm,

body: SafeArea(

child: _isLoading

? const Center(child: CircularProgressIndicator(color: _brandOrange))

: Center(

child: ConstrainedBox(

constraints: BoxConstraints(maxWidth: isWide ? 540 : double.infinity),

child: Column(

children: [

// ── Top Header Navigation Bar ──────────────────────────────

Padding(

padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),

child: Row(

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

'Choose Your Plan',

style: TextStyle(

fontSize: 20,

fontWeight: FontWeight.w900,

color: _ink,

letterSpacing: -0.3,

),

),

SizedBox(height: 2),

Text(

'Select a plan to unlock top messes in your area',

style: TextStyle(

fontSize: 12.5,

color: _greySub,

fontWeight: FontWeight.w500,

),

),

],

),

],

),

),



// ── Scrollable Plan Cards List ─────────────────────────────

Expanded(

child: ListView(

physics: const ClampingScrollPhysics(),

padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

children: [

if (_serviceLocation != null) ...[

_buildServiceAreaInfoCard(_serviceLocation!),

const SizedBox(height: 14),

],

if (_currentSub != null) ...[

_buildCurrentSubscriptionCard(_currentSub!),

const SizedBox(height: 16),

const Padding(

padding: EdgeInsets.symmetric(horizontal: 4),

child: Text(

'Available Renewal & Upgrade Plans',

style: TextStyle(

fontSize: 15,

fontWeight: FontWeight.w800,

color: _ink,

),

),

),

const SizedBox(height: 10),

],

...List.generate(_plans.length, (index) {

final plan = _plans[index];

final isSelected = index == _selectedIndex;

return Padding(

padding: const EdgeInsets.only(bottom: 14),

child: _buildPlanCard(plan, isSelected, index),

);

}),

],

),

),



// ── Bottom Fixed Payment Section ───────────────────────────

Container(

padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),

decoration: BoxDecoration(

color: _white,

border: Border(top: BorderSide(color: _cardBorder, width: 1)),

boxShadow: [

BoxShadow(

color: Colors.black.withOpacity(0.04),

blurRadius: 10,

offset: const Offset(0, -3),

),

],

),

child: Column(

mainAxisSize: MainAxisSize.min,

children: [

// Trust / Guarantee Features Row

Row(

mainAxisAlignment: MainAxisAlignment.spaceEvenly,

children: [

_buildTrustBadge(Icons.shield_outlined, 'Secure Payment'),

Container(height: 12, width: 1, color: _cardBorder),

_buildTrustBadge(Icons.refresh_rounded, 'Cancel Anytime'),

Container(height: 12, width: 1, color: _cardBorder),

_buildTrustBadge(Icons.local_offer_outlined, 'Best Price'),

],

),

const SizedBox(height: 14),



// Main CTA Orange Button: Continue to Pay ₹199 >

GestureDetector(

onTap: _isSubmitting ? null : _processPayment,

child: Container(

height: 52,

width: double.infinity,

decoration: BoxDecoration(

color: _brandOrange,

borderRadius: BorderRadius.circular(20),

boxShadow: [

BoxShadow(

color: _brandOrange.withOpacity(0.35),

blurRadius: 12,

offset: const Offset(0, 4),

),

],

),

child: _isSubmitting

? const Center(

child: SizedBox(

width: 22,

height: 22,

child: CircularProgressIndicator(color: _white, strokeWidth: 2.5),

),

)

: Row(

mainAxisAlignment: MainAxisAlignment.center,

children: [

const Text(

'Continue to Pay',

style: TextStyle(

fontSize: 16,

fontWeight: FontWeight.w900,

color: _white,

),

),

const SizedBox(width: 8),

Text(

selectedPlan != null ? '₹${selectedPlan.price.toStringAsFixed(0)}' : '₹199',

style: const TextStyle(

fontSize: 16,

fontWeight: FontWeight.w900,

color: _white,

),

),

const SizedBox(width: 6),

const Icon(Icons.chevron_right_rounded, color: _white, size: 20),

],

),

),

),

],

),

),

],

),

),

),

),

);

}



// ── Helper: Single Subscription Option Card ────────────────────────────────

Widget _buildPlanCard(SubscriptionPlan plan, bool isSelected, int index) {

return GestureDetector(

onTap: () => setState(() => _selectedIndex = index),

child: Stack(

clipBehavior: Clip.none,

children: [

Container(

padding: const EdgeInsets.all(16),

decoration: BoxDecoration(

color: isSelected ? _activeBg : _white,

borderRadius: BorderRadius.circular(18),

border: Border.all(

color: isSelected ? _brandOrange : _cardBorder,

width: isSelected ? 1.6 : 1.2,

),

boxShadow: [

BoxShadow(

color: isSelected ? _brandOrange.withOpacity(0.08) : Colors.black.withOpacity(0.025),

blurRadius: 10,

offset: const Offset(0, 3),

),

],

),

child: Column(

crossAxisAlignment: CrossAxisAlignment.start,

children: [

// Title, Subtitle, Price & Radio Icon

Row(

crossAxisAlignment: CrossAxisAlignment.start,

children: [

Expanded(

child: Column(

crossAxisAlignment: CrossAxisAlignment.start,

children: [

Text(

plan.planName,

style: const TextStyle(

fontSize: 17,

fontWeight: FontWeight.w900,

color: _ink,

),

),

const SizedBox(height: 2),

Text(

plan.duration > 0 ? '${plan.duration} Days Validity' : (plan.description ?? 'Validity details'),

style: const TextStyle(

fontSize: 12,

color: _greySub,

fontWeight: FontWeight.w500,

),

),

const SizedBox(height: 6),

Container(

padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),

decoration: BoxDecoration(

color: const Color(0xFFF1F5F9),

borderRadius: BorderRadius.circular(6),

border: Border.all(color: const Color(0xFFE2E8F0)),

),

child: Row(

mainAxisSize: MainAxisSize.min,

children: [

const Icon(Icons.restaurant_rounded, size: 12, color: Color(0xFF475569)),

const SizedBox(width: 4),

Text(

'${plan.totalDeliveries} Meals • ${plan.mealType}',

style: const TextStyle(

fontSize: 11,

fontWeight: FontWeight.w700,

color: Color(0xFF334155),

),

),

],

),

),

],

),

),

Column(

crossAxisAlignment: CrossAxisAlignment.end,

children: [

Text(

'₹${plan.price.toStringAsFixed(0)}',

style: const TextStyle(

fontSize: 20,

fontWeight: FontWeight.w900,

color: _ink,

),

),

const SizedBox(height: 6),



// Radio Icon Button

Container(

width: 22,

height: 22,

decoration: BoxDecoration(

shape: BoxShape.circle,

border: Border.all(

color: isSelected ? _brandOrange : _greySub.withOpacity(0.5),

width: isSelected ? 6 : 1.5,

),

color: _white,

),

),

],

),

],

),

const SizedBox(height: 12),



// Feature Bullet List

...[

'Access to all messes in your area',

'Area tiffin charge (₹${((_serviceLocation != null && _serviceLocation!.tiffinCharge > 0) ? _serviceLocation!.tiffinCharge : (plan.tiffinCharge > 0 ? plan.tiffinCharge : 50.0)).toStringAsFixed(0)}${(_serviceLocation?.hasDiscount == true || plan.hasDiscount) ? " • ${(_serviceLocation?.hasDiscount == true ? _serviceLocation!.discountPercentage : plan.discountPercentage).toStringAsFixed(0)}% OFF" : ""}) deducted from wallet per order',

'Unlimited orders',

'Exclusive offers & discounts',

].map(

(feature) => Padding(

padding: const EdgeInsets.only(bottom: 6),

child: Row(

children: [

const Icon(Icons.check_rounded, color: _brandOrange, size: 16),

const SizedBox(width: 8),

Expanded(

child: Text(

feature,

style: const TextStyle(

fontSize: 12.5,

color: _greySub,

fontWeight: FontWeight.w500,

),

),

),

],

),

),

),

],

),

),



// Top Right Tag Badge: "Most Popular"

if (index == 0)

Positioned(

top: -1,

right: 1,

child: Container(

padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),

decoration: BoxDecoration(

color: _popularTag,

borderRadius: const BorderRadius.only(

topRight: Radius.circular(16),

bottomLeft: Radius.circular(12),

),

border: Border.all(color: const Color(0xFFFFE8DD), width: 1),

),

child: const Text(

'Most Popular',

style: TextStyle(

fontSize: 11,

fontWeight: FontWeight.w900,

color: _brandOrange,

),

),

),

),

],

),

);

}



// ── Helper: Bottom Trust Badge Item ────────────────────────────────────────

Widget _buildTrustBadge(IconData icon, String text) {

return Row(

mainAxisSize: MainAxisSize.min,

children: [

Icon(icon, color: _brandOrange, size: 14),

const SizedBox(width: 5),

Text(

text,

style: const TextStyle(

fontSize: 11.5,

fontWeight: FontWeight.w700,

color: _greySub,

),

),

],

);


}

}
