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
  final double maintenanceReserve;
  final double maintenanceCostPerKm;
  final String recommendation;

  ProfitabilityResult({
    required this.isProfitable,
    required this.decision,
    required this.netProfit,
    required this.profitPercentage,
    required this.fuelCost,
    required this.totalCost,
    required this.profitPerKm,
    required this.maintenanceReserve,
    required this.maintenanceCostPerKm,
    required this.recommendation,
  });
}

class ProfitabilityCalculator {
  ProfitabilityResult calculate({
    required RideData ride,
    required double fuelPricePerLiter,
    required UserParameters params,
  }) {
    final distanceKm = ride.distanceKm <= 0 ? 1.0 : ride.distanceKm;

    final minimumProfitPerKm = params.desiredCommission <= 0
        ? 300.0
        : params.desiredCommission;

    final acceptableProfitPerKm = minimumProfitPerKm * 0.75;

    final maintenanceCostPerKm =
        params.maintenanceCostPerKm < 0
            ? 0.0
            : params.maintenanceCostPerKm;

    final maintenanceReserve =
        distanceKm * maintenanceCostPerKm;

    final netProfit = ride.fare - maintenanceReserve;

    final profitPerKm = netProfit / distanceKm;

    final profitPercentage = ride.fare > 0
        ? (netProfit / ride.fare) * 100
        : 0.0;

    late RideDecision decision;
    late String recommendation;

    if (profitPerKm >= minimumProfitPerKm) {
      decision = RideDecision.accept;
      recommendation =
          'ACEPTAR. Supera la meta de ₡${minimumProfitPerKm.toStringAsFixed(0)}/km.';
    } else if (profitPerKm >= acceptableProfitPerKm) {
      decision = RideDecision.acceptable;
      recommendation =
          'ACEPTABLE. Está sobre el 75% de la meta mínima.';
    } else {
      decision = RideDecision.reject;
      recommendation =
          'RECHAZAR. No alcanza el mínimo aceptable de ₡${acceptableProfitPerKm.toStringAsFixed(0)}/km.';
    }

    return ProfitabilityResult(
      isProfitable: decision != RideDecision.reject,
      decision: decision,
      netProfit: netProfit,
      profitPercentage: profitPercentage,
      fuelCost: 0.0,
      totalCost: maintenanceReserve,
      profitPerKm: profitPerKm,
      maintenanceReserve: maintenanceReserve,
      maintenanceCostPerKm: maintenanceCostPerKm,
      recommendation: recommendation,
    );
  }
}