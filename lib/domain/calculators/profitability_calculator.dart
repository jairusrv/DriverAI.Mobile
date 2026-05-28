import '../entities/user_parameters.dart';
import '../../data/models/ride_data.dart';

enum RideDecision {
  accept,
  acceptable,
  reject,
}

class ProfitabilityResult {
  final bool isProfitable;
  final RideDecision decision;
  final double netProfit;
  final double profitPercentage;
  final double fuelCost;
  final double totalCost;
  final double profitPerKm;
  final String recommendation;

  ProfitabilityResult({
    required this.isProfitable,
    required this.decision,
    required this.netProfit,
    required this.profitPercentage,
    required this.fuelCost,
    required this.totalCost,
    required this.profitPerKm,
    required this.recommendation,
  });
}

class ProfitabilityCalculator {
  ProfitabilityResult calculate({
    required RideData ride,
    required double fuelPricePerLiter,
    required UserParameters params,
  }) {
    final distanceKm =
        ride.distanceKm <= 0 ? 1.0 : ride.distanceKm;

    final vehicleEfficiency =
        params.vehicleEfficiency <= 0
            ? 10.0
            : params.vehicleEfficiency;

    final litersNeeded =
        distanceKm / vehicleEfficiency;

    final fuelCost =
        litersNeeded * fuelPricePerLiter;

    const timeCostPerMinute = 30.0;

    final timeCost =
        ride.durationMinutes * timeCostPerMinute;

    final fixedCost =
        params.fixedCostPerTrip;

    final totalCost =
        fuelCost + timeCost + fixedCost;

    final netProfit =
        ride.fare - totalCost;

    final profitPercentage =
        ride.fare > 0
            ? (netProfit / ride.fare) * 100
            : 0.0;

    final profitPerKm =
        netProfit / distanceKm;

    final idealProfitPerKm =
        params.desiredCommission;

    final acceptableProfitPerKm =
        idealProfitPerKm * 0.75;

    late RideDecision decision;
    late String recommendation;

    if (profitPerKm >= idealProfitPerKm &&
        netProfit > 0) {
      decision = RideDecision.accept;
      recommendation =
          'ACEPTAR. Cumple el objetivo ideal de ₡${idealProfitPerKm.toStringAsFixed(0)}/km.';
    } else if (profitPerKm >= acceptableProfitPerKm &&
        netProfit > 0) {
      decision = RideDecision.acceptable;
      recommendation =
          'ACEPTABLE. Está por debajo del ideal, pero aún genera ganancia.';
    } else {
      decision = RideDecision.reject;
      recommendation =
          'RECHAZAR. No cumple el mínimo aceptable de rentabilidad.';
    }

    return ProfitabilityResult(
      isProfitable:
          decision != RideDecision.reject,
      decision: decision,
      netProfit: netProfit,
      profitPercentage: profitPercentage,
      fuelCost: fuelCost,
      totalCost: totalCost,
      profitPerKm: profitPerKm,
      recommendation: recommendation,
    );
  }
}