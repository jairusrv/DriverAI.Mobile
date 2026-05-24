import 'package:equatable/equatable.dart';

/// Parámetros de configuración del usuario para el cálculo de rentabilidad.
/// Todos los valores monetarios están en Colones (CRC).
class UserParameters extends Equatable {
  final double vehicleEfficiency;    // Kilómetros por litro (km/L)
  final double desiredCommission;    // Porcentaje de ganancia deseado (0-100)
  final double fixedCostPerTrip;     // Costo fijo por viaje en colones (₡)
  final String fuelType;             // "super", "diesel", "regular"
  final bool notificationsEnabled;   // Si se debe mostrar el overlay automáticamente

  const UserParameters({
    this.vehicleEfficiency = 12.0,
    this.desiredCommission = 20.0,
    this.fixedCostPerTrip = 500.0,
    this.fuelType = 'super',
    this.notificationsEnabled = true,
  });

  /// Convierte a Map para guardar en SharedPreferences
  Map<String, dynamic> toJson() => {
        'vehicleEfficiency': vehicleEfficiency,
        'desiredCommission': desiredCommission,
        'fixedCostPerTrip': fixedCostPerTrip,
        'fuelType': fuelType,
        'notificationsEnabled': notificationsEnabled,
      };

  /// Crea una instancia desde un Map (cargado desde SharedPreferences)
  factory UserParameters.fromJson(Map<String, dynamic> json) {
    return UserParameters(
      vehicleEfficiency: (json['vehicleEfficiency'] ?? 12.0).toDouble(),
      desiredCommission: (json['desiredCommission'] ?? 20.0).toDouble(),
      fixedCostPerTrip: (json['fixedCostPerTrip'] ?? 500.0).toDouble(),
      fuelType: json['fuelType'] ?? 'super',
      notificationsEnabled: json['notificationsEnabled'] ?? true,
    );
  }

  /// Método copyWith para actualizar parámetros de forma inmutable
  UserParameters copyWith({
    double? vehicleEfficiency,
    double? desiredCommission,
    double? fixedCostPerTrip,
    String? fuelType,
    bool? notificationsEnabled,
  }) {
    return UserParameters(
      vehicleEfficiency: vehicleEfficiency ?? this.vehicleEfficiency,
      desiredCommission: desiredCommission ?? this.desiredCommission,
      fixedCostPerTrip: fixedCostPerTrip ?? this.fixedCostPerTrip,
      fuelType: fuelType ?? this.fuelType,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  @override
  List<Object?> get props => [
        vehicleEfficiency,
        desiredCommission,
        fixedCostPerTrip,
        fuelType,
        notificationsEnabled,
      ];
}