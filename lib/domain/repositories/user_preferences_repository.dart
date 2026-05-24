// domain/repositories/user_preferences_repository.dart
import 'package:dartz/dartz.dart';
import '../entities/user_parameters.dart';
import '../../core/errors/failures.dart';

abstract class UserPreferencesRepository {
  Future<Either<Failure, void>> saveParameters(UserParameters params);
  Future<Either<Failure, UserParameters>> loadParameters();
}