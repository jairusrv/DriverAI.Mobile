import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../data/models/restricted_hex_zone.dart';

class RestrictedHexZoneService {
  static const _storage =
      FlutterSecureStorage();

  static const _key =
      'restricted_hex_zones';

  Future<List<RestrictedHexZone>> getZones() async {
    final raw =
        await _storage.read(key: _key);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded =
        jsonDecode(raw) as List<dynamic>;

    return decoded
        .map(
          (e) => RestrictedHexZone.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();
  }

  Future<void> saveZones(
    List<RestrictedHexZone> zones,
  ) async {
    await _storage.write(
      key: _key,
      value: jsonEncode(
        zones
            .map((e) => e.toJson())
            .toList(),
      ),
    );
  }

  Future<void> deleteZone(
    String id,
  ) async {
    final zones = await getZones();

    zones.removeWhere(
      (z) => z.id == id,
    );

    await saveZones(zones);
  }
}