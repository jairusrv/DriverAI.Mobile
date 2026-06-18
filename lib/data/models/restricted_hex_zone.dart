class RestrictedHexZone {
  final String id;
  final String h3Index;
  final bool enabled;

  const RestrictedHexZone({
    required this.id,
    required this.h3Index,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'h3Index': h3Index,
      'enabled': enabled,
    };
  }

  factory RestrictedHexZone.fromJson(
    Map<String, dynamic> json,
  ) {
    return RestrictedHexZone(
      id: json['id'],
      h3Index: json['h3Index'],
      enabled: json['enabled'] ?? true,
    );
  }
}