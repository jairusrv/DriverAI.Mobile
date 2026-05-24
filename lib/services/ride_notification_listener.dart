import 'package:logger/logger.dart';
import '../data/models/ride_data.dart';

typedef OnRideDetectedCallback = void Function(RideData ride);

class RideNotificationListener {
  OnRideDetectedCallback? onRideDetected;
  final Logger _logger = Logger();

  RideNotificationListener() {
    _init();
  }

  Future<void> _init() async {
    _logger.i('RideNotificationListener inicializado (versión simplificada)');
  }

  // Método para simular la recepción de una notificación
  void simulateRide(Map<String, dynamic> data) {
    final ride = RideData(
      rideId: data['rideId'] ?? 'sim_${DateTime.now().millisecondsSinceEpoch}',
      provider: data['provider'] ?? 'uber',
      origin: data['origin'] ?? 'Origen simulado',
      destination: data['destination'] ?? 'Destino simulado',
      distanceKm: (data['distance'] ?? 5.0).toDouble(),
      durationMinutes: (data['duration'] ?? 15).toInt(),
      fare: (data['fare'] ?? 2000.0).toDouble(),
      timestamp: DateTime.now(),
    );
    onRideDetected?.call(ride);
  }
}