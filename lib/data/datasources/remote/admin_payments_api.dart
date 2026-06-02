import 'package:dio/dio.dart';

import 'api_client.dart';

class AdminPaymentsApi {
  final Dio _dio = ApiClient().dio;

  Future<List<dynamic>> getPayments() async {
    final response = await _dio.get('/payments');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> approvePayment(int paymentId) async {
    final response = await _dio.post('/payments/$paymentId/approve');
    return Map<String, dynamic>.from(response.data);
  }
}
