import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/datasources/remote/subscription_api.dart';
import '../../data/models/subscription_info.dart';
import '../../data/repositories/subscription_repository_impl.dart';
import '../../domain/repositories/subscription_repository.dart';
import 'auth_provider.dart';

final subscriptionApiProvider = Provider<SubscriptionApi>((ref) {
  final dio = ref.read(apiClientProvider).dio;
  return SubscriptionApi(dio);
});

final subscriptionRepositoryProvider =
    Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepositoryImpl(
    ref.read(subscriptionApiProvider),
  );
});

final subscriptionProvider =
    FutureProvider<SubscriptionInfo?>((ref) async {
  const storage = FlutterSecureStorage();

  final phoneNumber = await storage.read(key: 'phone_number');

  if (phoneNumber == null || phoneNumber.isEmpty) {
    return null;
  }

  final repository = ref.read(subscriptionRepositoryProvider);

  final result = await repository.getSubscriptionStatus(
    phoneNumber,
  );

  return result.fold(
    (_) => null,
    (info) => info,
  );
});