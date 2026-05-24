import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';

abstract class AuthRepository {
  // Registro
  Future<Either<Failure, Map<String, dynamic>>> register({
    required String phoneNumber,
    required String email,
    required String username,
    required String password,
  });

  // Verificación SMS
  Future<Either<Failure, Map<String, dynamic>>> verifyCode({
    required String phoneNumber,
    required String code,
  });

  Future<Either<Failure, void>> resendCode(String phoneNumber);

  // Login
  Future<Either<Failure, Map<String, dynamic>>> login({
    required String phoneNumber,
    required String password,
  });

  // ========== NUEVOS MÉTODOS PARA EMAIL ==========
  Future<Either<Failure, Map<String, dynamic>>> verifyEmail({
    required String email,
    required String code,
  });

  Future<Either<Failure, void>> resendEmailCode(String email);
}