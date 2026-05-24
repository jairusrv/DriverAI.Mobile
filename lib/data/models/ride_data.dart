// data/models/ride_data.dart
import 'package:equatable/equatable.dart';

class RideData extends Equatable {
  final String rideId;
  final String provider; // "uber", "didi", "unknown"
  final String origin;
  final String destination;
  final double distanceKm; // distancia en kilómetros
  final int durationMinutes; // duración en minutos
  final double fare; // en colones (₡)
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
  });

  @override
  List<Object?> get props => [rideId, provider, fare];
}