import 'package:logger/logger.dart';

import '../data/models/ride_data.dart';
import 'ride_offer_parser.dart';

typedef OnRideDetectedCallback = void Function(
  RideData ride,
);

class RideNotificationListener {
  OnRideDetectedCallback? onRideDetected;

  final Logger _logger = Logger();

  RideNotificationListener() {
    _init();
  }

  Future<void> _init() async {
    _logger.i(
      'RideNotificationListener inicializado',
    );
  }

  void simulateRide(
    Map<String, dynamic> data,
  ) {
    final ride = RideData(
      rideId: data['rideId'] ??
          'sim_${DateTime.now().millisecondsSinceEpoch}',
      provider: data['provider'] ?? 'uber',
      origin: data['origin'] ??
          'Origen simulado',
      destination:
          data['destination'] ??
              'Destino simulado',
      distanceKm:
          (data['distance'] ?? 5.0)
              .toDouble(),
      durationMinutes:
          (data['duration'] ?? 15)
              .toInt(),
      fare: (data['fare'] ?? 2000.0)
          .toDouble(),
      timestamp: DateTime.now(),
    );

    onRideDetected?.call(ride);
  }

  RideData? parseNotificationText({
    required String provider,
    required String text,
  }) {
    final ride = RideOfferParser.parse(
      provider: provider,
      text: text,
    );

    if (ride == null) {
      _logger.w(
        'No se pudo parsear oferta de viaje: $text',
      );
    }

    return ride;
  }

  void processNotificationText({
    required String provider,
    required String text,
  }) {
    final ride =
        parseNotificationText(
      provider: provider,
      text: text,
    );

    if (ride == null) {
      return;
    }

    _logger.i(
      'Viaje detectado: ${ride.provider} | ₡${ride.fare} | ${ride.distanceKm} km | ${ride.durationMinutes} min',
    );

    onRideDetected?.call(ride);
  }

  void simulateUberDriverOffer() {
    processNotificationText(
      provider: 'uber',
      text: '''
UberX Exclusivo
CRC1,254
A 3 min (0.7 km)
Av. 21A, San Francisco - Goicoechea
Viaje: 12 min (2.4 km)
Hospital - San José
''',
    );
  }

  void simulateUberDeliveryOffer() {
    processNotificationText(
      provider: 'uber',
      text: '''
Artículo Exclusivo
₡10 204,09
A 2 min (0.3 km)
C. 13, Catedral - San José
Viaje: 1 h 25 min (61.0 km)
San Rafael - San Ramón
''',
    );
  }

  void simulateDidiOffer() {
    processNotificationText(
      provider: 'didi',
      text: '''
DiDi viaje disponible
₡3.500
A 4 min (1.2 km)
Viaje: 18 min (6.8 km)
''',
    );
  }
}