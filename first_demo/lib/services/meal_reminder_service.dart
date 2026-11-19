// lib/services/meal_reminder_service.dart
//
// Automatically shows a local notification at:
//   • Lunch  – 12:00 PM  (window: 11:30 AM – 12:30 PM)
//   • Dinner – 07:00 PM  (window: 06:30 PM – 07:30 PM)
//
// Before firing the notification it checks the customer's order history
// for today. If an order was already placed in that meal window the
// reminder is silently skipped.
//
// The service keeps a lightweight periodic timer (runs every 60 s while
// the app is alive).  Push a scheduled notification via
// flutter_local_notifications for exact-time firing even when the app
// is in the background.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import '../utils/app_config.dart';
import 'package:http/http.dart' as http;

// ──────────────────────────────────────────────────────────────────────────────
//  Meal window definitions
// ──────────────────────────────────────────────────────────────────────────────

enum _MealType { lunch, dinner }

class _MealWindow {
  final _MealType type;
  final int fireHour;    // hour at which the notification fires (24-h)
  final int fireMinute;
  final int windowStartHour; // orders placed >= this hour count as "in-window"
  final int windowStartMin;
  final int windowEndHour;   // orders placed <  this hour count as "in-window"
  final int windowEndMin;

  const _MealWindow({
    required this.type,
    required this.fireHour,
    required this.fireMinute,
    required this.windowStartHour,
    required this.windowStartMin,
    required this.windowEndHour,
    required this.windowEndMin,
  });

  String get label => type == _MealType.lunch ? 'Lunch' : 'Dinner';
  int get notificationId => type == _MealType.lunch ? 9001 : 9002;
  String get prefKey =>
      type == _MealType.lunch ? '_reminder_lunch_date' : '_reminder_dinner_date';
}

const _lunch = _MealWindow(
  type: _MealType.lunch,
  fireHour: 12,
  fireMinute: 0,
  windowStartHour: 7,
  windowStartMin: 0,
  windowEndHour: 14,
  windowEndMin: 0,
);

const _dinner = _MealWindow(
  type: _MealType.dinner,
  fireHour: 19,
  fireMinute: 0,
  windowStartHour: 16,
  windowStartMin: 0,
  windowEndHour: 22,
  windowEndMin: 0,
);

// ──────────────────────────────────────────────────────────────────────────────
//  Service
// ──────────────────────────────────────────────────────────────────────────────

class MealReminderService {
  MealReminderService._();
  static final MealReminderService instance = MealReminderService._();

  /// Same MethodChannel the FCM service uses for native custom notifications.
  static const MethodChannel _platformChannel =
      MethodChannel('com.zenqube.hungrilyfoods/notifications');

  Timer? _checkTimer;
  bool _initialised = false;

  // ── Public API ────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (kIsWeb) return;
    if (_initialised) return;
    _initialised = true;

    _startPeriodicCheck();

    if (kDebugMode) {
      print('[MealReminder] Service initialised. '
          'Lunch reminder at ${_lunch.fireHour}:${_lunch.fireMinute.toString().padLeft(2, '0')}, '
          'Dinner reminder at ${_dinner.fireHour}:${_dinner.fireMinute.toString().padLeft(2, '0')}');
    }
  }

  void dispose() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  // ── Periodic tick ─────────────────────────────────────────────────────────

  void _startPeriodicCheck() {
    // Fire immediately (catches the case where the app is opened at meal time)
    // then check every 60 seconds.
    _tick();
    _checkTimer = Timer.periodic(const Duration(seconds: 60), (_) => _tick());
  }

  Future<void> _tick() async {
    final now = DateTime.now();
    await _checkAndNotify(_lunch, now);
    await _checkAndNotify(_dinner, now);
  }

  // ── Core logic ────────────────────────────────────────────────────────────

  Future<void> _checkAndNotify(_MealWindow meal, DateTime now) async {
    // Only act inside a 60-second window around the trigger time
    // so we don't repeatedly show the same notification each minute.
    final fireTime = DateTime(
      now.year,
      now.month,
      now.day,
      meal.fireHour,
      meal.fireMinute,
    );

    final diff = now.difference(fireTime).inSeconds.abs();
    if (diff > 60) return; // Not in the fire window

    // Skip if we already fired this reminder today
    if (await _alreadyFiredToday(meal)) return;

    // Skip if user is not logged in
    final token = await AuthService.instance.getSavedToken();
    if (token == null || token.isEmpty) return;

    // Check if an order was placed in today's meal window
    final ordered = await _hasOrderedForMeal(meal, now, token);
    if (ordered) {
      // Customer already ordered – just mark as done so we don't check again
      await _markFiredToday(meal);
      if (kDebugMode) {
        print('[MealReminder] ${meal.label} – order found, skipping reminder.');
      }
      return;
    }

    // No order found → show reminder
    await _showReminder(meal);
    await _markFiredToday(meal);
  }

  // ── Check order history ──────────────────────────────────────────────────

  Future<bool> _hasOrderedForMeal(
      _MealWindow meal, DateTime now, String token) async {
    try {
      // Fetch today's orders using the existing history endpoint.
      // We grab the first page (most recent) – enough to cover today.
      final url = Uri.parse('$kBaseUrl/api/orders/history?page=1&limit=20');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] != true) return false;

      final dataMap = (body['data'] as Map<String, dynamic>?) ?? {};
      final orders = (dataMap['orders'] as List?) ?? [];

      final windowStart = DateTime(
        now.year,
        now.month,
        now.day,
        meal.windowStartHour,
        meal.windowStartMin,
      );
      final windowEnd = DateTime(
        now.year,
        now.month,
        now.day,
        meal.windowEndHour,
        meal.windowEndMin,
      );

      for (final order in orders) {
        final createdAtStr =
            (order as Map<String, dynamic>)['created_at'] as String?;
        if (createdAtStr == null) continue;

        DateTime? createdAt;
        try {
          createdAt = DateTime.parse(createdAtStr).toLocal();
        } catch (_) {
          continue;
        }

        if (createdAt.isAfter(windowStart) &&
            createdAt.isBefore(windowEnd)) {
          return true; // Found an order in this meal window
        }
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('[MealReminder] Error checking orders: $e');
      }
      // If we can't check, err on the side of caution and don't notify
      return false;
    }
  }

  // ── Show native notification (same style as order status) ─────────────────

  Future<void> _showReminder(_MealWindow meal) async {
    final isLunch = meal.type == _MealType.lunch;

    final title = isLunch
        ? '🍱 Time for Lunch!'
        : '🍽️ Time for Dinner!';
    final body = isLunch
        ? 'Haven\'t ordered lunch yet? Get a fresh meal delivered to your door!'
        : 'Haven\'t ordered dinner yet? Treat yourself to something delicious!';

    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _platformChannel.invokeMethod('showMealReminder', {
          'isLunch': isLunch,
          'title': title,
          'body': body,
        });
        if (kDebugMode) {
          print('[MealReminder] ${meal.label} native reminder shown.');
        }
        return;
      } catch (e) {
        debugPrint('[MealReminder] Native channel failed: $e');
      }
    }

    if (kDebugMode) {
      print('[MealReminder] ${meal.label} reminder – non-Android platform, skipped.');
    }
  }

  // ── SharedPreferences helpers ─────────────────────────────────────────────

  Future<bool> _alreadyFiredToday(_MealWindow meal) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(meal.prefKey);
    if (stored == null) return false;
    final today = _dateKey(DateTime.now());
    return stored == today;
  }

  Future<void> _markFiredToday(_MealWindow meal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(meal.prefKey, _dateKey(DateTime.now()));
  }

  String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
