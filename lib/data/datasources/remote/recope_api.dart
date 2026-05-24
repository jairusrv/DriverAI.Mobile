// data/datasources/remote/recope_api.dart
import 'package:dio/dio.dart';
import '../../models/api_response.dart';
import '../../models/fuel_price.dart';

class RecopeApi {
  final Dio _dio;
  RecopeApi(this._dio);

  Future<ApiResponse<List<FuelPrice>>> getFuelPrices() async {
    final response = await _dio.get('/api/recope/datos');
    return ApiResponse.fromJson(response.data, (data) {
      final list = data as List;
      return list.map((item) => FuelPrice.fromJson(item)).toList();
    });
  }

  Future<ApiResponse<void>> updatePrices() async {
    final response = await _dio.get('/api/recope/actualizar');
    return ApiResponse.fromJson(response.data, (_) => null);
  }
}