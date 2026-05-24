// domain/usecases/auth/resend_code_usecase.dart
import 'package:dartz/dartz.dart';
import '../../repositories/auth_repository.dart';
import '../../../core/errors/failures.dart';

class ResendCodeUseCase {
  final AuthRepository repository;

  ResendCodeUseCase(this.repository);

  Future<Either<Failure, void>> call(String phoneNumber) async {
    return await repository.resendCode(phoneNumber);
  }
}