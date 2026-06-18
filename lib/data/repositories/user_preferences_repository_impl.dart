// data/repositories/user_preferences_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../domain/repositories/user_preferences_repository.dart';
import '../../domain/entities/user_parameters.dart';
import '../../core/errors/failures.dart';
import '../datasources/local/shared_preferences_datasource.dart';

class UserPreferencesRepositoryImpl implements UserPreferencesRepository {
  final SharedPreferencesDataSource dataSource;

  UserPreferencesRepositoryImpl(this.dataSource);

  @override
  Future<Either<Failure, void>> saveParameters(UserParameters params) async {
    try {
      await dataSource.saveUserParameters(params.toJson());
      return const Right(null);
    } catch (e) {
      return Left(LocalStorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserParameters>> loadParameters() async {
    try {
      final json = await dataSource.getUserParameters();
      if (json != null) {
        return Right(UserParameters.fromJson(json));
      } else {
        // Valores por defecto
        return const Right(UserParameters());
      }
    } catch (e) {
      return Left(LocalStorageFailure(e.toString()));
    }
  }
}
