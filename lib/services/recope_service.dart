// services/recope_service.dart

import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';

import '../core/errors/failures.dart';
import '../data/datasources/remote/recope_api.dart';
import '../data/models/fuel_price.dart';

class RecopeService {
  final RecopeApi _recopeApi;
  final Logger _logger = Logger();

  RecopeService(this._recopeApi);

  Future<Either<Failure, double>> getCurrentFuelPrice({
    String fuelType = 'regular',
  }) async {
    try {
      final normalizedFuel =
          _normalizeFuelType(fuelType);

      if (normalizedFuel == 'gas_lp' ||
          normalizedFuel == 'electric') {
        return const Right(0);
      }

      final response =
          await _recopeApi.getFuelPrices();

      if (!response.success ||
          response.data == null ||
          response.data!.isEmpty) {
        return Left(
          RecopeFailure(response.message),
        );
      }

      final selected =
          _findFuelPrice(
        response.data!,
        normalizedFuel,
      );

      return Right(selected.price);
    } catch (e) {
      _logger.e(
        'Error al obtener precio de combustible: $e',
      );

      return Left(
        ServerFailure(e.toString()),
      );
    }
  }

  Future<Either<Failure, void>> refreshPrices() async {
    try {
      final response =
          await _recopeApi.updatePrices();

      if (response.success) {
        return const Right(null);
      }

      return Left(
        RecopeFailure(response.message),
      );
    } catch (e) {
      return Left(
        ServerFailure(e.toString()),
      );
    }
  }

  FuelPrice _findFuelPrice(
    List<FuelPrice> prices,
    String fuelType,
  ) {
    return prices.firstWhere(
      (fuel) =>
          _normalizeFuelType(fuel.fuelType) ==
          fuelType,
      orElse: () => prices.firstWhere(
        (fuel) =>
            _normalizeFuelType(fuel.fuelType) ==
            'regular',
        orElse: () => prices.first,
      ),
    );
  }

  String _normalizeFuelType(String value) {
    final normalized =
        value.toLowerCase().trim();

    if (normalized.contains('super') ||
        normalized.contains('súper')) {
      return 'super';
    }

    if (normalized.contains('regular') ||
        normalized.contains('plus 91')) {
      return 'regular';
    }

    if (normalized.contains('diesel') ||
        normalized.contains('diésel')) {
      return 'diesel';
    }

    if (normalized.contains('gas') ||
        normalized.contains('lp') ||
        normalized.contains('glp')) {
      return 'gas_lp';
    }

    if (normalized.contains('electric') ||
        normalized.contains('eléctrico') ||
        normalized.contains('electrico')) {
      return 'electric';
    }

    return normalized;
  }
}