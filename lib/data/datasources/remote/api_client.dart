import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/api_constants.dart';

class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: ApiConstants.defaultTimeout),
      receiveTimeout: const Duration(seconds: ApiConstants.defaultTimeout),
      sendTimeout: const Duration(seconds: ApiConstants.defaultTimeout),
      headers: {'Content-Type': 'application/json'},
    ));
    _addInterceptors();
  }

  void _addInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _secureStorage.read(key: 'auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        print('Dio error: ${error.message}');
        return handler.next(error);
      },
    ));
  }

  Dio get dio => _dio;
}