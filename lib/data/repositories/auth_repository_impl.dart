import 'package:dartz/dartz.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../../core/errors/failures.dart';
import '../datasources/remote/auth_api.dart';
import '../models/register_request.dart';
import '../models/verify_code_request.dart';
import '../models/login_request.dart';
import '../models/resend_code_request.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthApi authApi;

  AuthRepositoryImpl(this.authApi);

  @override
  Future<Either<Failure, Map<String, dynamic>>> register({
    required String phoneNumber,
    required String email,
    required String username,
    required String password,
  }) async {
    try {
      final request = RegisterRequest(
        phoneNumber: phoneNumber,
        email: email,
        username: username,
        password: password,
      );
      final response = await authApi.register(request);
      if (response.success && response.data != null) {
        return Right(response.data!);
      } else {
        return Left(ServerFailure(response.message));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> verifyCode({
    required String phoneNumber,
    required String code,
  }) async {
    try {
      final request = VerifyCodeRequest(phoneNumber: phoneNumber, code: code);
      final response = await authApi.verifyCode(request);
      if (response.success && response.data != null) {
        return Right(response.data!);
      } else {
        return Left(VerificationFailure(response.message));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resendCode(String phoneNumber) async {
    try {
      final request = ResendCodeRequest(phoneNumber: phoneNumber);
      final response = await authApi.resendCode(request);
      if (response.success) {
        return const Right(null);
      } else {
        return Left(ServerFailure(response.message));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> login({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final request = LoginRequest(phoneNumber: phoneNumber, password: password);
      final response = await authApi.login(request);
      if (response.success && response.data != null) {
        return Right(response.data!);
      } else {
        return Left(AuthFailure(response.message));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}