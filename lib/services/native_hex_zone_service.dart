import 'dart:convert';

import 'package:flutter/services.dart';

import '../data/models/restricted_hex_zone.dart';

class NativeHexZoneService {
  static const MethodChannel _channel =
      MethodChannel(
    'driverai/hex_zones',
  );

  static Future<void> syncZones(
    List<RestrictedHexZone> zones,
  ) async {
    await _channel.invokeMethod(
      'syncZones',
      jsonEncode(
        zones
            .map((e) => e.toJson())
            .toList(),
      ),
    );
  }
}