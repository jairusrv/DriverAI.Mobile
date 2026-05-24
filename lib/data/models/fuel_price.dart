// data/models/fuel_price.dart
import 'package:equatable/equatable.dart';

class FuelPrice extends Equatable {
  final double price; // Precio por litro en colones (₡/L)
  final DateTime date;
  final String fuelType; // "super", "diesel", "regular"

  const FuelPrice({
    required this.price,
    required this.date,
    required this.fuelType,
  });

  factory FuelPrice.fromJson(Map<String, dynamic> json) {
    return FuelPrice(
      price: (json['precio'] as num).toDouble(),
      date: DateTime.parse(json['fecha']),
      fuelType: json['tipo'] ?? 'super',
    );
  }

  @override
  List<Object?> get props => [price, fuelType];
}