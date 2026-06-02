import 'package:dio/dio.dart';

import '../../models/api_response.dart';
import '../../models/fuel_price.dart';

class RecopeApi {
  final Dio _dio;

  RecopeApi(this._dio);

  Future<ApiResponse<List<FuelPrice>>> getFuelPrices() async {
    final response = await _dio.get(
      '/api/recope/datos',
    );

    final body = response.data;

    List<dynamic> rawList = [];

    if (body is Map<String, dynamic>) {
      final data = body['data'];

      if (data is List) {
        rawList = data;
      }
    } else if (body is List) {
      rawList = body;
    }

    final prices = rawList
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => FuelPrice.fromJson(item),
        )
        .toList();

    return ApiResponse<List<FuelPrice>>(
      success: true,
      message: 'Precios obtenidos',
      data: prices,
    );
  }

  Future<ApiResponse<void>> updatePrices() async {
    final response = await _dio.get(
      //'/api/recope/actualizar',
      '/api/Recope/datos',
    );

    final body = response.data;

    bool success = true;
    String message = 'Precios actualizados';

    if (body is Map<String, dynamic>) {
      success = body['success'] == true || body['success'] == 'true';

      message = body['message']?.toString() ?? message;
    }

    return ApiResponse<void>(
      success: success,
      message: message,
      data: null,
    );
  }
}
