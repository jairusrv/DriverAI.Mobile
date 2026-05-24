// services/recope_service.dart
import 'package:dartz/dartz.dart';
import '../data/datasources/remote/recope_api.dart';
import '../data/models/fuel_price.dart';
import '../core/errors/failures.dart';
import 'package:logger/logger.dart';

class RecopeService {
  final RecopeApi _recopeApi;
  final Logger _logger = Logger();

  RecopeService(this._recopeApi);

  /// Obtiene el precio del combustible más reciente (por defecto súper).
  Future<Either<Failure, double>> getCurrentFuelPrice() async {
    try {
      final response = await _recopeApi.getFuelPrices();
      if (response.success && response.data != null && response.data!.isNotEmpty) {
        // Suponemos que el último precio es el actual
        final latest = response.data!.first;
        return Right(latest.price);
      } else {
        return Left(RecopeFailure(response.message));
      }
    } catch (e) {
      _logger.e('Error al obtener precio de combustible: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Forzar la actualización de los precios desde la fuente original (Recope)
  Future<Either<Failure, void>> refreshPrices() async {
    try {
      final response = await _recopeApi.updatePrices();
      if (response.success) {
        return const Right(null);
      } else {
        return Left(RecopeFailure(response.message));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}