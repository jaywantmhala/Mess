import 'package:flutter/foundation.dart';

/// Set to true to point all services to the local development server (10.44.177.233:8000).
/// Set to false to point all services to the live production server (https://hungrilyfoods.com).
const bool kUseLocalUrl = false;

const String _kLocalUrlIp = 'http://10.44.177.233:8000';
const String _kLocalUrlWeb = 'http://localhost:8000';
const String _kProdUrl = 'https://hungrilyfoods.com';

String get kBaseUrl {
  if (kUseLocalUrl) {
    if (kIsWeb) {
      return _kLocalUrlWeb;
    }
    return _kLocalUrlIp;
  }
  return _kProdUrl;
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
