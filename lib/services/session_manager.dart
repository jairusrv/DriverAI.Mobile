import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/constants/shared_prefs_keys.dart';
import 'fuel_price_session_service.dart';

class SessionManager {
  static const FlutterSecureStorage _storage =
      FlutterSecureStorage();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    await FuelPriceSessionService.getPrices();

    _initialized = true;
  }

  static Future<String?> getToken() async {
    return await _storage.read(
      key: SharedPrefsKeys.token,
    );
  }

  static Future<int?> getUserId() async {
    final value = await _storage.read(
      key: SharedPrefsKeys.userId,
    );

    if (value == null) return null;

    return int.tryParse(value);
  }

  static Future<double> getFuelPrice(
    String fuelType,
  ) async {
    return await FuelPriceSessionService
        .getPriceFor(fuelType);
  }

  static Future<void> clear() async {
    _initialized = false;

    await FuelPriceSessionService.clear();

    await _storage.deleteAll();
  }
}