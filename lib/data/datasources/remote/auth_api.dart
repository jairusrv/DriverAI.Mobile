import 'package:dio/dio.dart';
import '../../models/api_response.dart';
import '../../models/register_request.dart';
import '../../models/verify_code_request.dart';
import '../../models/resend_code_request.dart';
import '../../models/login_request.dart';

class AuthApi {
  final Dio _dio;
  AuthApi(this._dio);

  Future<ApiResponse<Map<String, dynamic>>> register(RegisterRequest request) async {
    final response = await _dio.post('/api/auth/register', data: request.toJson());
    return ApiResponse.fromJson(response.data, (data) => data as Map<String, dynamic>);
  }

  Future<ApiResponse<Map<String, dynamic>>> verifyCode(VerifyCodeRequest request) async {
    final response = await _dio.post('/api/auth/verify-code', data: request.toJson());
    return ApiResponse.fromJson(response.data, (data) => data as Map<String, dynamic>);
  }

  Future<ApiResponse<void>> resendCode(ResendCodeRequest request) async {
    final response = await _dio.post('/api/auth/resend-code', data: request.toJson());
    return ApiResponse.fromJson(response.data, (_) => null);
  }

  Future<ApiResponse<Map<String, dynamic>>> login(LoginRequest request) async {
    final response = await _dio.post('/api/auth/login', data: request.toJson());
    return ApiResponse.fromJson(response.data, (data) => data as Map<String, dynamic>);
  }
}