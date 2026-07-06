import 'package:flutter/foundation.dart';

/// Shared application configuration constants.
/// Update [_baseIp] to match your server's IP/host.
const String _baseIp = '127.0.0.1'; // Localhost over adb reverse forwarding

final String kBaseUrl = kIsWeb ? 'http://localhost:8000' : 'http://$_baseIp:8000';
