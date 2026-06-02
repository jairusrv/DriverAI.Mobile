// lib/presentation/providers/subscription_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/api_client.dart';
import '../../data/datasources/remote/subscription_api.dart';
import '../../data/repositories/subscription_repository_impl.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../../data/models/subscription_info.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/api_client.dart';
import '../../data/datasources/remote/subscription_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/api_client.dart';
import '../../data/datasources/remote/subscription_api.dart';
import 'auth_provider.dart';

final subscriptionApiProvider = Provider((ref) {
  final dio = ref.read(apiClientProvider).dio;
  return SubscriptionApi(dio);
});

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepositoryImpl(ref.read(subscriptionApiProvider));
});

final subscriptionProvider = FutureProvider<SubscriptionInfo?>((ref) async {
  const storage = FlutterSecureStorage();
  final phoneNumber = await storage.read(key: 'phone_number');
  if (phoneNumber == null) return null;
  final repo = ref.read(subscriptionRepositoryProvider);
  final result = await repo.getSubscriptionStatus(phoneNumber);
  return result.fold(
    (failure) => null,
    (info) => info,
  );
});

// Notifier para acciones como activar suscripción
class SubscriptionNotifier
    extends StateNotifier<AsyncValue<SubscriptionInfo?>> {
  final SubscriptionRepository _repository;
  final String phoneNumber;

  SubscriptionNotifier(this._repository, this.phoneNumber)
      : super(const AsyncValue.data(null)) {
    loadStatus();
  }

  Future<void> loadStatus() async {
    state = const AsyncValue.loading();
    final result = await _repository.getSubscriptionStatus(phoneNumber);
    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (info) => AsyncValue.data(info),
    );
  }

  Future<void> activate(int months) async {
    final result = await _repository.activateSubscription(phoneNumber, months);
    result.fold(
      (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
      (_) => loadStatus(), // recargar estado después de activar
    );
  }
}

final subscriptionNotifierProvider =
    StateNotifierProvider<SubscriptionNotifier, AsyncValue<SubscriptionInfo?>>(
        (ref) {
  const storage = FlutterSecureStorage();
  final phoneNumber =
      storage.read(key: 'phone_number').then((value) => value ?? '');
  // No podemos usar async en el provider, así que lo haremos con un futuro aparte. Mejor usamos un provider normal que depende del phoneNumber.
  throw UnimplementedError(
      'Se necesita obtener phoneNumber de forma asíncrona. Se usará otro enfoque.');
});

/// Para manejar la dependencia asíncrona del phoneNumber, creamos un provider separado:
