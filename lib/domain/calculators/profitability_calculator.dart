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
  final bool pickupDistanceExceeded;
  final bool tripDistanceExceeded;
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
    required this.pickupDistanceExceeded,
    required this.tripDistanceExceeded,
    required this.recommendation,
  });
}

class ProfitabilityCalculator {
  ProfitabilityResult calculate({
    required RideData ride,
    required double fuelPricePerLiter,
    required UserParameters params,
    double maxPickupDistance = 0,
    double maxTripDistance = 0,
  }) {
    final distanceKm = ride.distanceKm <= 0 ? 1.0 : ride.distanceKm;

    final minimumProfitPerKm =
        params.desiredCommission <= 0 ? 300.0 : params.desiredCommission;

    final acceptableProfitPerKm = minimumProfitPerKm * 0.75;

    final maintenanceCostPerKm =
        params.maintenanceCostPerKm < 0 ? 0.0 : params.maintenanceCostPerKm;

    final maintenanceReserve = distanceKm * maintenanceCostPerKm;
    final netProfit = ride.fare - maintenanceReserve;
    final profitPerKm = netProfit / distanceKm;

    final profitPercentage =
        ride.fare > 0 ? (netProfit / ride.fare) * 100 : 0.0;

    RideDecision decision;
    String recommendation;

    if (profitPerKm >= minimumProfitPerKm) {
      decision = RideDecision.accept;
      recommendation = 'El Monto Por Km es superior a ₡${minimumProfitPerKm.toStringAsFixed(0)}/km.';
    } else if (profitPerKm >= acceptableProfitPerKm) {
      decision = RideDecision.acceptable;
      recommendation = 'El monto por Km es muy cercano a ₡${minimumProfitPerKm.toStringAsFixed(0)}/km.';
    } else {
      decision = RideDecision.reject;
      recommendation = 'El monto por Km es menor a ₡${minimumProfitPerKm.toStringAsFixed(0)}/km.';
    }

    final pickupDistanceExceeded = maxPickupDistance > 0 &&
        ride.pickupDistanceKm > 0 &&
        ride.pickupDistanceKm > maxPickupDistance;

    final tripDistanceExceeded = maxTripDistance > 0 &&
        ride.tripDistanceKm > 0 &&
        ride.tripDistanceKm > maxTripDistance;

    if (pickupDistanceExceeded || tripDistanceExceeded) {
      final reason = pickupDistanceExceeded
          ? 'Distancia de recogida mayor a la establecida'
          : 'Distancia del viaje mayor a la establecida';

      if (decision == RideDecision.accept) {
        decision = RideDecision.acceptable;
      } else if (decision == RideDecision.acceptable) {
        decision = RideDecision.reject;
      }

      recommendation = reason;
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
      pickupDistanceExceeded: pickupDistanceExceeded,
      tripDistanceExceeded: tripDistanceExceeded,
      recommendation: recommendation,
    );
  }
}