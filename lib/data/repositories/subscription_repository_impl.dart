import 'package:dartz/dartz.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../../data/models/subscription_info.dart';
import '../../core/errors/failures.dart';
import '../datasources/remote/subscription_api.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionApi api;

  SubscriptionRepositoryImpl(this.api);

  @override
  Future<Either<Failure, SubscriptionInfo>> getSubscriptionStatus(String phoneNumber) async {
    try {
      final response = await api.getSubscriptionStatus(phoneNumber);
      if (response.success && response.data != null) {
        return Right(response.data!);
      } else {
        return Left(ServerFailure(response.message));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> activateSubscription(String phoneNumber, int months) async {
    try {
      final response = await api.activateSubscription(phoneNumber, months);
      if (response.success) {
        return const Right(null);
      } else {
        return Left(ServerFailure(response.message));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}