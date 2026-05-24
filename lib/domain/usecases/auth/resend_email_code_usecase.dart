import 'package:dartz/dartz.dart';
import '../../repositories/auth_repository.dart';
import '../../../core/errors/failures.dart';

class ResendEmailCodeUseCase {
  final AuthRepository repository;

  ResendEmailCodeUseCase(this.repository);

  Future<Either<Failure, void>> call(String email) async {
    return await repository.resendEmailCode(email);
  }
}