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
    price: (json['price'] ??
            json['precio'] ??
            json['Precio'] ??
            0)
        .toDouble(),
    date: DateTime.tryParse(
          (json['createdAt'] ??
                  json['fecha'] ??
                  json['Fecha'] ??
                  DateTime.now().toIso8601String())
              .toString(),
        ) ??
        DateTime.now(),
    fuelType: (json['fuelType'] ??
            json['tipo'] ??
            json['Tipo'] ??
            json['producto'] ??
            json['Producto'] ??
            'regular')
        .toString()
        .toLowerCase(),
  );
}

  @override
  List<Object?> get props => [price, fuelType];
}