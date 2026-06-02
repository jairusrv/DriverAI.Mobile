import 'package:dio/dio.dart';

import '../../models/api_response.dart';
import '../../models/subscription_info.dart';

class SubscriptionApi {
  final Dio _dio;

  SubscriptionApi(this._dio);

  Future<ApiResponse<SubscriptionInfo>> getSubscriptionStatus(
    String phoneNumber,
  ) async {
    final response = await _dio.get(
      '/api/auth/subscription-status/$phoneNumber',
    );

    return ApiResponse.fromJson(
      response.data,
      (data) => SubscriptionInfo.fromJson(data),
    );
  }

  Future<ApiResponse<SubscriptionInfo>> getSubscriptionDetails(
    String phoneNumber,
  ) async {
    final response = await _dio.get(
      '/api/auth/subscription-details/$phoneNumber',
    );

    return ApiResponse.fromJson(
      response.data,
      (data) => SubscriptionInfo.fromJson(data),
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> activateSubscription(
    String phoneNumber,
    int months,
  ) async {
    final response = await _dio.post(
      '/api/auth/activate-subscription',
      data: {
        'phoneNumber': phoneNumber,
        'months': months,
      },
    );

    return ApiResponse.fromJson(
      response.data,
      (data) => data as Map<String, dynamic>,
    );
  }
}
