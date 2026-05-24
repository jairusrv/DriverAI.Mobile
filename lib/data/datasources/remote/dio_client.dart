import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Cliente HTTP singleton con manejo de token
class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;
  DioClient._internal();

  late final Dio dio;
  final storage = const FlutterSecureStorage();

  void init({String? baseUrl}) {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? 'https://driverai-api.onrender.com',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    // Interceptor para agregar token
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token expirado, podríamos hacer refresh aquí
          await storage.delete(key: 'access_token');
        }
        return handler.next(error);
      },
    ));

    // Logger para depuración
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: true,
    ));
  }
}