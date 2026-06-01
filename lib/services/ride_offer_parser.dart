import '../data/models/ride_data.dart';

class RideOfferParser {
  static RideData? parse({
    required String provider,
    required String text,
  }) {
    try {
      final fare = _extractFare(text);
      final isDelivery = _isDeliveryOffer(text);

      double pickupDistance = 0;
      double tripDistance = 0;
      double totalDistance = 0;
      int durationMinutes = 0;

      if (isDelivery) {
        totalDistance = _extractDeliveryDistance(text);
        tripDistance = totalDistance;
        durationMinutes = _extractDeliveryDuration(text);
      } else {
        pickupDistance = _extractPickupDistance(text);
        tripDistance = _extractTripDistance(text);

        totalDistance = pickupDistance + tripDistance;

        final tripDuration = _extractDriverTripDuration(text);

        final pickupDuration = _estimatePickupDuration(
          pickupDistanceKm: pickupDistance,
          tripDistanceKm: tripDistance,
          tripDurationMinutes: tripDuration,
        );

        durationMinutes = tripDuration + pickupDuration;
      }

      if (fare <= 0 || totalDistance <= 0) {
        return null;
      }

      return RideData(
        rideId: 'ride_${DateTime.now().millisecondsSinceEpoch}',
        provider: provider.toLowerCase(),
        origin: 'Detectado',
        destination: 'Detectado',
        distanceKm: totalDistance,
        pickupDistanceKm: pickupDistance,
        tripDistanceKm: tripDistance,
        durationMinutes: durationMinutes > 0 ? durationMinutes : 1,
        fare: fare,
        timestamp: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  static bool _isDeliveryOffer(String text) {
    final normalized = text.toLowerCase();

    if (normalized.contains('viaje:')) {
      return false;
    }

    return normalized.contains('entrega') ||
        normalized.contains('pedido') ||
        normalized.contains('total:');
  }

  static double _extractFare(String text) {
    final regex = RegExp(
      r'(CRC|₡|¢|ARS)\s?([0-9\s.,]+)',
      caseSensitive: false,
    );

    final match = regex.firstMatch(text);

    if (match == null) {
      return 0;
    }

    return _parseNumber(match.group(2) ?? '');
  }

  static double _extractDeliveryDistance(String text) {
    final regex = RegExp(
      r'Total:\s*[0-9h\smin]+\s*\(([0-9.,]+)\s*km\)',
      caseSensitive: false,
    );

    final match = regex.firstMatch(text);

    if (match == null) {
      return 0;
    }

    return _parseNumber(match.group(1) ?? '');
  }

  static int _extractDeliveryDuration(String text) {
    final regex = RegExp(
      r'Total:\s*(.*?)\(',
      caseSensitive: false,
    );

    final match = regex.firstMatch(text);

    if (match == null) {
      return 0;
    }

    return _parseDurationText(match.group(1) ?? '');
  }

  static double _extractPickupDistance(String text) {
    final regex = RegExp(
      r'A\s+[0-9]+\s+min\s+\(([0-9.,]+)\s*km\)',
      caseSensitive: false,
    );

    final match = regex.firstMatch(text);

    if (match == null) {
      return 0;
    }

    return _parseNumber(match.group(1) ?? '');
  }

  static double _extractTripDistance(String text) {
    final regex = RegExp(
      r'Viaje:.*?\(([0-9.,]+)\s*km\)',
      caseSensitive: false,
      dotAll: true,
    );

    final match = regex.firstMatch(text);

    if (match == null) {
      return 0;
    }

    return _parseNumber(match.group(1) ?? '');
  }

  static int _extractDriverTripDuration(String text) {
    final regex = RegExp(
      r'Viaje:\s*(.*?)\(',
      caseSensitive: false,
      dotAll: true,
    );

    final match = regex.firstMatch(text);

    if (match == null) {
      return 0;
    }

    return _parseDurationText(match.group(1) ?? '');
  }

  static int _estimatePickupDuration({
    required double pickupDistanceKm,
    required double tripDistanceKm,
    required int tripDurationMinutes,
  }) {
    if (pickupDistanceKm <= 0 ||
        tripDistanceKm <= 0 ||
        tripDurationMinutes <= 0) {
      return 0;
    }

    final estimated =
        (pickupDistanceKm * tripDurationMinutes) / tripDistanceKm;

    return estimated.round();
  }

  static int _parseDurationText(String text) {
    int total = 0;

    final hourRegex = RegExp(
      r'([0-9]+)\s*h',
      caseSensitive: false,
    );

    final minRegex = RegExp(
      r'([0-9]+)\s*min',
      caseSensitive: false,
    );

    final hourMatch = hourRegex.firstMatch(text);

    if (hourMatch != null) {
      total +=
          (int.tryParse(hourMatch.group(1) ?? '') ?? 0) * 60;
    }

    final minMatches = minRegex.allMatches(text);

    for (final match in minMatches) {
      total += int.tryParse(match.group(1) ?? '') ?? 0;
    }

    return total;
  }

  static double _parseNumber(String value) {
    var clean = value.trim();
    clean = clean.replaceAll(' ', '');

    if (clean.contains(',') && clean.contains('.')) {
      clean = clean.replaceAll('.', '').replaceAll(',', '.');
    } else if (clean.contains(',')) {
      clean = clean.replaceAll(',', '.');
    }

    return double.tryParse(clean) ?? 0;
  }
}