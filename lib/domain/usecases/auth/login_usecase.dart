import 'package:dartz/dartz.dart';
import '../../repositories/auth_repository.dart';
import '../../../core/errors/failures.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call({
    required String phoneNumber,
    required String password,
  }) async {
    return await repository.login(phoneNumber: phoneNumber, password: password);
  }
}