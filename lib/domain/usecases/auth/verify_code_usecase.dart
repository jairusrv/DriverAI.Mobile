// domain/usecases/auth/verify_code_usecase.dart
import 'package:dartz/dartz.dart';
import '../../repositories/auth_repository.dart';
import '../../../core/errors/failures.dart';

class VerifyCodeUseCase {
  final AuthRepository repository;

  VerifyCodeUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call({
    required String phoneNumber,
    required String code,
  }) async {
    return await repository.verifyCode(phoneNumber: phoneNumber, code: code);
  }
}