import 'package:equatable/equatable.dart';

class RideData extends Equatable {
  final String rideId;
  final String provider;
  final String origin;
  final String destination;

  final double distanceKm;
  final double pickupDistanceKm;
  final double tripDistanceKm;

  final int durationMinutes;
  final double fare;
  final DateTime timestamp;

  const RideData({
    required this.rideId,
    required this.provider,
    required this.origin,
    required this.destination,
    required this.distanceKm,
    required this.durationMinutes,
    required this.fare,
    required this.timestamp,
    this.pickupDistanceKm = 0,
    this.tripDistanceKm = 0,
  });

  @override
  List<Object?> get props => [
        rideId,
        provider,
        fare,
        distanceKm,
        pickupDistanceKm,
        tripDistanceKm,
      ];
}
