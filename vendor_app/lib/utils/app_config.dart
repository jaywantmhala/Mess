import 'package:flutter/foundation.dart';

/// Set to true to run against local development server (10.44.177.233:8000).
/// Set to false to run against the live production server (hungrilyfoods.com).
const bool kUseLocalUrl = false;

const String _kLocalHostIp = '10.44.177.233:8000';
const String _kLocalHostWeb = '10.44.177.233:8000';
const String _kLocalHostAndroid = '10.44.177.233:8000';
const String _kLocalHostIos = '10.44.177.233:8000';
const String _kProdHost = 'hungrilyfoods.com';

String get kHost {
  if (kUseLocalUrl) {
    return _kLocalHostIp;
  }
  return _kProdHost;
}

String get kApiHost {
  if (kUseLocalUrl) {
    if (kHost.contains('loca.lt')) {
      return 'https://$kHost/api';
    }
    return 'http://$kHost/api';
  }
  return 'https://$kHost/api';
}

String get kBaseUrl => '$kApiHost/vendor';

String get kWebSocketUrl {
  if (kUseLocalUrl) {
    if (kHost.contains('loca.lt')) {
      return 'wss://$kHost/ws';
    }
    return 'ws://$kHost/ws';
  }
  return 'wss://$kHost/ws';
}

String get kEnvPrefix => kUseLocalUrl ? 'dev' : 'prod';

const String kAblyDevApiKey = 'oSsZ2A.MVAVyA:EhxvHAEsSfx49DDHPqZ9_u3d7LzUETbyXpQl0sjW1Nk';
const String kAblyProdApiKey = 'oSsZ2A.MVAVyA:EhxvHAEsSfx49DDHPqZ9_u3d7LzUETbyXpQl0sjW1Nk';

String get kAblyApiKey => kUseLocalUrl ? kAblyDevApiKey : kAblyProdApiKey;

String kVendorChannel(int vendorId) => '${kEnvPrefix}_vendor_$vendorId';
String kDriverChannel(int driverId) => '${kEnvPrefix}_driver_$driverId';
String kOrderChannel(int orderId) => '${kEnvPrefix}_order_$orderId';
String kHotelOrdersChannel(int hotelId) => '${kEnvPrefix}_hotel_${hotelId}_orders';
String kOrderChatChannel(int orderId) => '${kEnvPrefix}_order_${orderId}_chat';
String get kAblyChannelName => '${kEnvPrefix}_global_events';
