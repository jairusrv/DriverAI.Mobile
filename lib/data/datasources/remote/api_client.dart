import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/shared_prefs_keys.dart';

class ApiClient {
  late final Dio _dio;

  final FlutterSecureStorage _secureStorage =
      const FlutterSecureStorage();

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(
          seconds: ApiConstants.defaultTimeout,
        ),
        receiveTimeout: const Duration(
          seconds: ApiConstants.defaultTimeout,
        ),
        sendTimeout: const Duration(
          seconds: ApiConstants.defaultTimeout,
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _addInterceptors();
  }

  void _addInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (
          options,
          handler,
        ) async {
          final token =
              await _secureStorage.read(
            key: SharedPrefsKeys.token,
          );

          if (token != null &&
              token.isNotEmpty) {
            options.headers['Authorization'] =
                'Bearer $token';
          }

          return handler.next(options);
        },
        onError: (
          error,
          handler,
        ) async {
          if (error.response?.statusCode ==
              401) {
            await _secureStorage.delete(
              key: SharedPrefsKeys.token,
            );
          }

          return handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;
}