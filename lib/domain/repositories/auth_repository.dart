import 'package:dartz/dartz.dart';
import '../entities/user_entity.dart';
import '../../core/errors/failures.dart';

abstract class AuthRepository {
  Future<Either<Failure, Map<String, dynamic>>> register({
    required String phoneNumber,
    required String email,
    required String username,
    required String password,
  });

  Future<Either<Failure, Map<String, dynamic>>> verifyCode({
    required String phoneNumber,
    required String code,
  });

  Future<Either<Failure, void>> resendCode(String phoneNumber);

  Future<Either<Failure, Map<String, dynamic>>> login({
    required String phoneNumber,
    required String password,
  });
}