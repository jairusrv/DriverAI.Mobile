import 'package:equatable/equatable.dart';

class UserParameters extends Equatable {
  final double vehicleEfficiency;
  final double desiredCommission;
  final String fuelType;
  final bool notificationsEnabled;
  final String vehicleType;
  final double maintenanceCostPerKm;
  final double maxPickupDistance;
  final double maxTripDistance;

  const UserParameters({
    this.vehicleEfficiency = 12.0,
    this.desiredCommission = 300.0,
    this.fuelType = 'regular',
    this.notificationsEnabled = true,
    this.vehicleType = '',
    this.maintenanceCostPerKm = 0.0,
    this.maxPickupDistance = 0.0,
    this.maxTripDistance = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'vehicleEfficiency': vehicleEfficiency,
        'desiredCommission': desiredCommission,
        'fuelType': fuelType,
        'notificationsEnabled': notificationsEnabled,
        'vehicleType': vehicleType,
        'maintenanceCostPerKm': maintenanceCostPerKm,
        'maxPickupDistance': maxPickupDistance,
        'maxTripDistance': maxTripDistance,
      };

  factory UserParameters.fromJson(Map<String, dynamic> json) {
    return UserParameters(
      vehicleEfficiency: (json['vehicleEfficiency'] ?? 12.0).toDouble(),
      desiredCommission: (json['desiredCommission'] ?? 300.0).toDouble(),
      fuelType: json['fuelType'] ?? 'regular',
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      vehicleType: json['vehicleType'] ?? '',
      maintenanceCostPerKm: (json['maintenanceCostPerKm'] ?? 0.0).toDouble(),
      maxPickupDistance: (json['maxPickupDistance'] ?? 0.0).toDouble(),
      maxTripDistance: (json['maxTripDistance'] ?? 0.0).toDouble(),
    );
  }

  UserParameters copyWith({
    double? vehicleEfficiency,
    double? desiredCommission,
    String? fuelType,
    bool? notificationsEnabled,
    String? vehicleType,
    double? maintenanceCostPerKm,
    double? maxPickupDistance,
    double? maxTripDistance,
  }) {
    return UserParameters(
      vehicleEfficiency: vehicleEfficiency ?? this.vehicleEfficiency,
      desiredCommission: desiredCommission ?? this.desiredCommission,
      fuelType: fuelType ?? this.fuelType,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      vehicleType: vehicleType ?? this.vehicleType,
      maintenanceCostPerKm: maintenanceCostPerKm ?? this.maintenanceCostPerKm,
      maxPickupDistance: maxPickupDistance ?? this.maxPickupDistance,
      maxTripDistance: maxTripDistance ?? this.maxTripDistance,
    );
  }

  @override
  List<Object?> get props => [
        vehicleEfficiency,
        desiredCommission,
        fuelType,
        notificationsEnabled,
        vehicleType,
        maintenanceCostPerKm,
        maxPickupDistance,
        maxTripDistance,
      ];
}