import 'package:dartz/dartz.dart';
import '../../data/models/subscription_info.dart';
import '../../core/errors/failures.dart';

abstract class SubscriptionRepository {
  Future<Either<Failure, SubscriptionInfo>> getSubscriptionStatus(String phoneNumber);
  Future<Either<Failure, void>> activateSubscription(String phoneNumber, int months);
}