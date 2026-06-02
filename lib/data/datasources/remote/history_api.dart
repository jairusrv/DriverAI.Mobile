import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/shared_prefs_keys.dart';
import 'api_client.dart';

class HistoryApi {
  final Dio _dio = ApiClient().dio;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<int> _getUserId() async {
    final userId = await _storage.read(
      key: SharedPrefsKeys.userId,
    );

    if (userId == null) {
      throw Exception(
        'No hay usuario en sesión',
      );
    }

    return int.parse(userId);
  }

  Future<Response> getMyHistory() async {
    final userId = await _getUserId();

    return await _dio.get(
      '${ApiConstants.history}/$userId',
    );
  }

  Future<Response> getMySummary() async {
    final userId = await _getUserId();

    return await _dio.get(
      '${ApiConstants.history}/$userId/summary',
    );
  }

  Future<Response> saveRide({
    required double fare,
    required double distanceKm,
    required double pickupDistanceKm,
    required double estimatedTimeMinutes,
    required double profit,
    required double profitPerKm,
    required String decision,
    required String sourceApp,
  }) async {
    final userId = await _getUserId();

    return await _dio.post(
      ApiConstants.history,
      data: {
        'userId': userId,
        'fare': fare,
        'distanceKm': distanceKm,
        'pickupDistanceKm': pickupDistanceKm,
        'estimatedTimeMinutes': estimatedTimeMinutes,
        'profit': profit,
        'profitPerKm': profitPerKm,
        'decision': decision,
        'sourceApp': sourceApp,
      },
    );
  }
}
