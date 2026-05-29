import '../data/models/ride_data.dart';

class RideOfferParser {
  static RideData? parse({
    required String provider,
    required String text,
  }) {
    try {
      final fare = _extractFare(text);

      final isDelivery =
          _isDeliveryOffer(text);

      double totalDistance = 0;
      int durationMinutes = 0;

      if (isDelivery) {
        totalDistance =
            _extractDeliveryDistance(text);

        durationMinutes =
            _extractDeliveryDuration(text);
      } else {
        final pickupDistance =
            _extractPickupDistance(text);

        final tripDistance =
            _extractTripDistance(text);

        totalDistance =
            pickupDistance + tripDistance;

        durationMinutes =
            _extractDriverDuration(text);
      }

      if (fare <= 0 ||
          totalDistance <= 0) {
        return null;
      }

      return RideData(
        rideId:
            'ride_${DateTime.now().millisecondsSinceEpoch}',
        provider:
            provider.toLowerCase(),
        origin: 'Detectado',
        destination: 'Detectado',
        distanceKm: totalDistance,
        durationMinutes:
            durationMinutes > 0
                ? durationMinutes
                : 1,
        fare: fare,
        timestamp: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  static bool _isDeliveryOffer(
    String text,
  ) {
    final normalized =
        text.toLowerCase();

    return normalized.contains(
          'entrega',
        ) ||
        normalized.contains(
          'artículo',
        ) ||
        normalized.contains(
          'pedido',
        ) ||
        normalized.contains(
          'total:',
        );
  }

  static double _extractFare(
    String text,
  ) {
    final regex = RegExp(
      r'(CRC|₡|¢)\s?([0-9\s.,]+)',
      caseSensitive: false,
    );

    final match =
        regex.firstMatch(text);

    if (match == null) {
      return 0;
    }

    return _parseNumber(
      match.group(2) ?? '',
    );
  }

  // ========= DELIVERY =========

  static double _extractDeliveryDistance(
    String text,
  ) {
    final regex = RegExp(
      r'Total:\s*[0-9h\smin]+\s*\(([0-9.,]+)\s*km\)',
      caseSensitive: false,
    );

    final match =
        regex.firstMatch(text);

    if (match == null) {
      return 0;
    }

    return _parseNumber(
      match.group(1) ?? '',
    );
  }

  static int _extractDeliveryDuration(
    String text,
  ) {
    final regex = RegExp(
      r'Total:\s*(.*?)\(',
      caseSensitive: false,
    );

    final match =
        regex.firstMatch(text);

    if (match == null) {
      return 0;
    }

    return _parseDurationText(
      match.group(1) ?? '',
    );
  }

  // ========= DRIVER =========

  static double _extractPickupDistance(
    String text,
  ) {
    final regex = RegExp(
      r'A\s+[0-9]+\s+min\s+\(([0-9.,]+)\s*km\)',
      caseSensitive: false,
    );

    final match =
        regex.firstMatch(text);

    if (match == null) {
      return 0;
    }

    return _parseNumber(
      match.group(1) ?? '',
    );
  }

  static double _extractTripDistance(
    String text,
  ) {
    final regex = RegExp(
      r'Viaje:.*?\(([0-9.,]+)\s*km\)',
      caseSensitive: false,
      dotAll: true,
    );

    final match =
        regex.firstMatch(text);

    if (match == null) {
      return 0;
    }

    return _parseNumber(
      match.group(1) ?? '',
    );
  }

  static int _extractDriverDuration(
    String text,
  ) {
    final regex = RegExp(
      r'Viaje:\s*(.*?)\(',
      caseSensitive: false,
      dotAll: true,
    );

    final match =
        regex.firstMatch(text);

    if (match == null) {
      return 0;
    }

    return _parseDurationText(
      match.group(1) ?? '',
    );
  }

  // ========= HELPERS =========

  static int _parseDurationText(
    String text,
  ) {
    int total = 0;

    final hourRegex = RegExp(
      r'([0-9]+)\s*h',
      caseSensitive: false,
    );

    final minRegex = RegExp(
      r'([0-9]+)\s*min',
      caseSensitive: false,
    );

    final hourMatch =
        hourRegex.firstMatch(text);

    if (hourMatch != null) {
      total +=
          (int.tryParse(
                    hourMatch.group(1) ??
                        '',
                  ) ??
                  0) *
              60;
    }

    final minMatches =
        minRegex.allMatches(text);

    for (final match in minMatches) {
      total +=
          int.tryParse(
                match.group(1) ?? '',
              ) ??
              0;
    }

    return total;
  }

  static double _parseNumber(
    String value,
  ) {
    var clean =
        value.trim();

    clean = clean.replaceAll(
      ' ',
      '',
    );

    if (clean.contains(',') &&
        clean.contains('.')) {
      clean = clean
          .replaceAll('.', '')
          .replaceAll(',', '.');
    } else if (clean.contains(',')) {
      clean = clean.replaceAll(
        ',',
        '.',
      );
    }

    return double.tryParse(clean) ?? 0;
  }
}