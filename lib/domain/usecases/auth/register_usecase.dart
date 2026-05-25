import 'package:dartz/dartz.dart';
import '../../repositories/auth_repository.dart';
import '../../../core/errors/failures.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call({
    required String phoneNumber,
    required String email,
    required String username,
    required String password,
    required String imei,
  }) async {
    return await repository.register(
      phoneNumber: phoneNumber,
      email: email,
      username: username,
      password: password,
      imei: imei,
    );
  }
}