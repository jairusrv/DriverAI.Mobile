// domain/calculators/profitability_calculator.dart
import '../entities/user_parameters.dart';
import '../../data/models/ride_data.dart';

class ProfitabilityResult {
  final bool isProfitable;
  final double netProfit;          // ganancia neta en colones
  final double profitPercentage;   // porcentaje sobre la tarifa
  final double fuelCost;           // costo de combustible en colones
  final double totalCost;          // costo total en colones
  final String recommendation;

  ProfitabilityResult({
    required this.isProfitable,
    required this.netProfit,
    required this.profitPercentage,
    required this.fuelCost,
    required this.totalCost,
    required this.recommendation,
  });
}

class ProfitabilityCalculator {
  /// Calcula si el viaje es rentable según los parámetros del usuario.
  /// - ride.distanceKm: kilómetros
  /// - ride.fare: colones (CRC)
  /// - fuelPricePerLiter: colones por litro (CRC/L)
  /// - params.vehicleEfficiency: kilómetros por litro (km/L)
  ProfitabilityResult calculate({
    required RideData ride,
    required double fuelPricePerLiter, // CRC/L
    required UserParameters params,
  }) {
    // 1. Costo de combustible (CRC)
    final litersNeeded = ride.distanceKm / params.vehicleEfficiency; // litros
    final fuelCost = litersNeeded * fuelPricePerLiter; // CRC

    // 2. Costo por tiempo (opcional, ejemplo: ₡30 por minuto)
    const timeCostPerMinute = 30.0; // CRC
    final timeCost = ride.durationMinutes * timeCostPerMinute;

    // 3. Costo fijo por viaje (ejemplo: ₡500 por desgaste/seguro)
    final fixedCost = params.fixedCostPerTrip; // CRC (debe ser CRC)

    final totalCost = fuelCost + timeCost + fixedCost;

    // 4. Ganancia neta (CRC)
    final netProfit = ride.fare - totalCost;

    // 5. Porcentaje de ganancia sobre la tarifa
    final profitPercentage = (netProfit / ride.fare) * 100;

    // 6. Determinar si es rentable según la comisión deseada
    final isProfitable = profitPercentage >= params.desiredCommission;

    // 7. Mensaje de recomendación
    String recommendation;
    if (isProfitable) {
      recommendation = '✅ Viaje rentable. Ganancia neta: ₡${netProfit.toStringAsFixed(0)} '
                      '(${profitPercentage.toStringAsFixed(1)}%). Se recomienda aceptar.';
    } else {
      recommendation = '❌ Viaje NO rentable. Ganancia neta: ₡${netProfit.toStringAsFixed(0)} '
                      '(${profitPercentage.toStringAsFixed(1)}%). Es mejor rechazar.';
    }

    return ProfitabilityResult(
      isProfitable: isProfitable,
      netProfit: netProfit,
      profitPercentage: profitPercentage,
      fuelCost: fuelCost,
      totalCost: totalCost,
      recommendation: recommendation,
    );
  }
}