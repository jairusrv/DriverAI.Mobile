import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/shared_prefs_keys.dart';
import 'api_client.dart';

class SettingsApi {
  final Dio _dio = ApiClient().dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<int> _getUserId() async {
    final userId = await _storage.read(
      key: SharedPrefsKeys.userId,
    );

    if (userId == null || userId.isEmpty) {
      throw Exception('No hay usuario en sesión');
    }

    return int.parse(userId);
  }

  Future<Response> getMySettings() async {
    final userId = await _getUserId();

    return await _dio.get(
      '${ApiConstants.settings}/$userId',
    );
  }

  Future<Response> saveMySettings({
    required String fuelType,
    required double fuelPrice,
    required double kmPerLiter,
    required double minimumProfitPerKm,
    required double maxPickupDistance,
    required double maxTripDistance,
    required String serviceType,
    required String platform,
    required String vehicleType,
    required double maintenanceCostPerKm,
    String currency = 'CRC',
    String language = 'es',
  }) async {
    final userId = await _getUserId();

    return await _dio.post(
      ApiConstants.settings,
      data: {
        'userId': userId,
        'fuelType': fuelType,
        'fuelPrice': fuelPrice,
        'kmPerLiter': kmPerLiter,
        'minimumProfitPerKm': minimumProfitPerKm,
        'maxPickupDistance': maxPickupDistance,
        'maxTripDistance': maxTripDistance,
        'serviceType': serviceType,
        'platform': platform,
        'vehicleType': vehicleType,
        'maintenanceCostPerKm': maintenanceCostPerKm,
        'currency': currency,
        'language': language,
      },
    );
  }
}
