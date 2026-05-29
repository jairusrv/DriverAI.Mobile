import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/local/shared_preferences_datasource.dart';
import '../../data/repositories/user_preferences_repository_impl.dart';
import '../../domain/entities/user_parameters.dart';
import '../../domain/repositories/user_preferences_repository.dart';

final sharedPrefsDataSourceProvider = Provider(
  (ref) => SharedPreferencesDataSource(),
);

final userPreferencesRepositoryProvider = Provider(
  (ref) {
    return UserPreferencesRepositoryImpl(
      ref.read(sharedPrefsDataSourceProvider),
    );
  },
);

class UserParametersNotifier extends StateNotifier<UserParameters> {
  final UserPreferencesRepository _repository;

  UserParametersNotifier(this._repository)
      : super(const UserParameters()) {
    _loadParameters();
  }

  Future<void> _loadParameters() async {
    final result = await _repository.loadParameters();

    result.fold(
      (failure) => state = const UserParameters(),
      (params) => state = params,
    );
  }

  Future<void> saveParameters(
    UserParameters newParams,
  ) async {
    state = newParams;
    await _repository.saveParameters(newParams);
  }

  void updateVehicleEfficiency(double value) {
    state = state.copyWith(
      vehicleEfficiency: value,
    );
    _repository.saveParameters(state);
  }

  void updateDesiredCommission(double value) {
    state = state.copyWith(
      desiredCommission: value,
    );
    _repository.saveParameters(state);
  }

  void updateFuelType(String fuelType) {
    state = state.copyWith(
      fuelType: fuelType,
    );
    _repository.saveParameters(state);
  }

  void updateVehicleType(String vehicleType) {
    state = state.copyWith(
      vehicleType: vehicleType,
    );
    _repository.saveParameters(state);
  }

  void updateMaintenanceCostPerKm(double value) {
    state = state.copyWith(
      maintenanceCostPerKm: value,
    );
    _repository.saveParameters(state);
  }

  void updateNotificationsEnabled(bool enabled) {
    state = state.copyWith(
      notificationsEnabled: enabled,
    );
    _repository.saveParameters(state);
  }
}

final userParametersProvider =
    StateNotifierProvider<UserParametersNotifier, UserParameters>(
  (ref) {
    final repository = ref.read(
      userPreferencesRepositoryProvider,
    );

    return UserParametersNotifier(repository);
  },
);