class RestrictedHexZone {
  final String id;

  /// Identificador único del hexágono
  final String h3Index;

  /// Coordenadas del polígono
  /// [
  ///   {"lat": ..., "lng": ...},
  ///   ...
  /// ]
  final List<Map<String, double>> points;

  final bool enabled;

  const RestrictedHexZone({
    required this.id,
    required this.h3Index,
    required this.points,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'h3Index': h3Index,
      'points': points,
      'enabled': enabled,
    };
  }

  factory RestrictedHexZone.fromJson(
    Map<String, dynamic> json,
  ) {
    return RestrictedHexZone(
      id: json['id'],
      h3Index: json['h3Index'],
      points: List<Map<String, double>>.from(
        (json['points'] as List).map(
          (e) => Map<String, double>.from(e),
        ),
      ),
      enabled: json['enabled'] ?? true,
    );
  }
}