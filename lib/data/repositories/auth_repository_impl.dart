import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../core/errors/failures.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/remote/auth_api.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../models/resend_code_request.dart';
import '../models/resend_email_code_request.dart';
import '../models/verify_code_request.dart';
import '../models/verify_email_request.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthApi authApi;

  AuthRepositoryImpl(this.authApi);

  @override
  Future<Either<Failure, Map<String, dynamic>>> register({
    required String phoneNumber,
    required String email,
    required String username,
    required String password,
    required String imei,
  }) async {
    try {
      final request = RegisterRequest(
        imei: imei,
        phoneNumber: phoneNumber,
        email: email,
        username: username,
        password: password,
      );

      final response = await authApi.register(request);

      if (response.success && response.data != null) {
        return Right(response.data!);
      }

      return Left(ServerFailure(response.message));
    } catch (e) {
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> verifyCode({
    required String phoneNumber,
    required String code,
  }) async {
    try {
      final request = VerifyCodeRequest(
        phoneNumber: phoneNumber,
        code: code,
      );

      final response = await authApi.verifyCode(request);

      if (response.success && response.data != null) {
        return Right(response.data!);
      }

      return Left(VerificationFailure(response.message));
    } catch (e) {
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> resendCode(
    String phoneNumber,
  ) async {
    try {
      final request = ResendCodeRequest(
        phoneNumber: phoneNumber,
      );

      final response = await authApi.resendCode(request);

      if (response.success) {
        return const Right(null);
      }

      return Left(ServerFailure(response.message));
    } catch (e) {
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> login({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final request = LoginRequest(
        phoneNumber: phoneNumber,
        password: password,
      );

      final response = await authApi.login(request);

      if (response.success && response.data != null) {
        return Right(response.data!);
      }

      return Left(AuthFailure(response.message));
    } catch (e) {
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final request = VerifyEmailRequest(
        email: email,
        code: code,
      );

      final response = await authApi.verifyEmail(request);

      if (response.success && response.data != null) {
        return Right(response.data!);
      }

      return Left(VerificationFailure(response.message));
    } catch (e) {
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> resendEmailCode(
    String email,
  ) async {
    try {
      final request = ResendEmailCodeRequest(
        email: email,
      );

      final response = await authApi.resendEmailCode(request);

      if (response.success) {
        return const Right(null);
      }

      return Left(ServerFailure(response.message));
    } catch (e) {
      return Left(_mapExceptionToFailure(e));
    }
  }

  Failure _mapExceptionToFailure(Object error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final serverMessage = _extractServerMessage(error);

      switch (statusCode) {
        case 400:
          return ServerFailure(
            serverMessage.isNotEmpty
                ? serverMessage
                : 'Solicitud inválida. Revisa los datos ingresados.',
          );

        case 401:
          return const AuthFailure(
            'Teléfono o contraseña incorrectos.',
          );

        case 403:
          return const AuthFailure(
            'No tienes permisos para realizar esta acción.',
          );

        case 404:
          return const ServerFailure(
            'No se encontró la información solicitada.',
          );

        case 409:
          return ServerFailure(
            serverMessage.isNotEmpty
                ? serverMessage
                : 'Ya existe un registro con esos datos.',
          );

        case 500:
        case 502:
        case 503:
        case 504:
          return const ServerFailure(
            'El servidor no respondió correctamente. Intenta nuevamente.',
          );

        default:
          if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.sendTimeout) {
            return const ServerFailure(
              'La conexión tardó demasiado. Intenta nuevamente.',
            );
          }

          if (error.type == DioExceptionType.connectionError) {
            return const ServerFailure(
              'No se pudo conectar con el servidor. Revisa tu internet.',
            );
          }

          return ServerFailure(
            serverMessage.isNotEmpty
                ? serverMessage
                : 'Ocurrió un problema. Intenta nuevamente.',
          );
      }
    }

    return const ServerFailure(
      'Ocurrió un problema inesperado. Intenta nuevamente.',
    );
  }

  String _extractServerMessage(DioException error) {
    final data = error.response?.data;

    if (data is Map) {
      final message = data['message'] ??
          data['error'] ??
          data['title'] ??
          data['detail'];

      if (message != null) {
        return message.toString();
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return data;
    }

    return '';
  }
}