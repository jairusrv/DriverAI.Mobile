import 'package:dio/dio.dart';

import 'api_client.dart';

class SinpePaymentApi {
  final Dio _dio = ApiClient().dio;

  Future<Map<String, dynamic>> reportSinpePayment({
    required double amount,
    required String sinpeSenderPhone,
    required String sinpeReferenceNumber,
    String? notes,
  }) async {
    final response = await _dio.post(
      '/payments/report-sinpe',
      data: {
        'amount': amount,
        'sinpeSenderPhone': sinpeSenderPhone,
        'sinpeReferenceNumber': sinpeReferenceNumber,
        'notes': notes,
      },
    );

    return Map<String, dynamic>.from(response.data);
  }
}