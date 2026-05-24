import 'package:dartz/dartz.dart';
import '../../repositories/auth_repository.dart';
import '../../../core/errors/failures.dart';

class VerifyEmailUseCase {
  final AuthRepository repository;

  VerifyEmailUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call({
    required String email,
    required String code,
  }) async {
    return await repository.verifyEmail(email: email, code: code);
  }
}