import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../data/datasources/remote/api_client.dart';
import '../data/datasources/remote/recope_api.dart';

class FuelPriceSessionService {
  static final Map<String, double> _memoryCache = {};

  static const FlutterSecureStorage _storage =
      FlutterSecureStorage();

  static const String _pricesKey =
      'fuel_prices_cache';

  static const String _dateKey =
      'fuel_prices_cache_date';

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  static Future<Map<String, double>> getPrices() async {
    if (_memoryCache.isNotEmpty) {
      return _memoryCache;
    }

    final savedDate = await _storage.read(
      key: _dateKey,
    );

    final savedPrices = await _storage.read(
      key: _pricesKey,
    );

    if (savedDate == _todayKey() &&
        savedPrices != null &&
        savedPrices.isNotEmpty) {
      final decoded =
          jsonDecode(savedPrices) as Map<String, dynamic>;

      decoded.forEach((key, value) {
        _memoryCache[key] =
            double.tryParse(value.toString()) ?? 0;
      });

      return _memoryCache;
    }

    final api = RecopeApi(
      ApiClient().dio,
    );

    final response = await api.getFuelPrices();

    if (response.success &&
        response.data != null) {
      for (final item in response.data!) {
        final key =
            _normalizeFuelType(item.fuelType);

        if (key == 'super' ||
            key == 'regular' ||
            key == 'diesel') {
          _memoryCache[key] = item.price;
        }
      }
    }

    await _storage.write(
      key: _dateKey,
      value: _todayKey(),
    );

    await _storage.write(
      key: _pricesKey,
      value: jsonEncode(_memoryCache),
    );

    return _memoryCache;
  }

  static Future<double> getPriceFor(
    String fuelType,
  ) async {
    final normalized =
        _normalizeFuelType(fuelType);

    if (normalized == 'gas_lp' ||
        normalized == 'electric') {
      return 0;
    }

    final prices = await getPrices();

    return prices[normalized] ??
        prices['regular'] ??
        0;
  }

  static Future<void> clear() async {
    _memoryCache.clear();

    await _storage.delete(
      key: _pricesKey,
    );

    await _storage.delete(
      key: _dateKey,
    );
  }

  static String _normalizeFuelType(
    String value,
  ) {
    final normalized =
        value.toLowerCase().trim();

    if (normalized.contains('super') ||
        normalized.contains('súper')) {
      return 'super';
    }

    if (normalized.contains('regular') ||
        normalized.contains('plus 91')) {
      return 'regular';
    }

    if (normalized.contains('diesel') ||
        normalized.contains('diésel')) {
      return 'diesel';
    }

    if (normalized.contains('gas') ||
        normalized.contains('lp') ||
        normalized.contains('glp')) {
      return 'gas_lp';
    }

    if (normalized.contains('electric') ||
        normalized.contains('eléctrico') ||
        normalized.contains('electrico')) {
      return 'electric';
    }

    return normalized;
  }
}