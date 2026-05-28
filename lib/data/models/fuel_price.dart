import 'package:equatable/equatable.dart';

class FuelPrice extends Equatable {
  final double price;
  final DateTime date;
  final String fuelType;

  const FuelPrice({
    required this.price,
    required this.date,
    required this.fuelType,
  });

  factory FuelPrice.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawProduct = (
      json['fuelType'] ??
      json['producto'] ??
      json['Producto'] ??
      json['nomprod'] ??
      json['Nomprod'] ??
      json['tipo'] ??
      json['Tipo'] ??
      ''
    ).toString();

    final rawPrice = (
      json['price'] ??
      json['precio'] ??
      json['Precio'] ??
      json['preciototal'] ??
      json['PrecioTotal'] ??
      0
    ).toString().trim();

    return FuelPrice(
      price: double.tryParse(rawPrice) ?? 0,
      date: DateTime.tryParse(
            (
              json['createdAt'] ??
              json['fecha'] ??
              json['Fecha'] ??
              json['fechaupd'] ??
              DateTime.now().toIso8601String()
            ).toString(),
          ) ??
          DateTime.now(),
      fuelType: _normalizeFuelType(rawProduct),
    );
  }

  static String _normalizeFuelType(
    String value,
  ) {
    final normalized =
        value.toLowerCase().trim();

    if (normalized.contains('super') ||
        normalized.contains('súper') ||
        normalized.contains('superior')) {
      return 'super';
    }

    if (normalized.contains('regular') ||
        normalized.contains('plus 91')) {
      return 'regular';
    }

    if (normalized.contains('diesel') ||
        normalized.contains('diésel') ||
        normalized.contains('diesel 50')) {
      return 'diesel';
    }

    if (normalized.contains('gas') ||
        normalized.contains('lp') ||
        normalized.contains('glp')) {
      return 'gas_lp';
    }

    if (normalized.contains('electric') ||
        normalized.contains('eléctrico') ||
        normalized.contains('electrico')) {
      return 'electric';
    }

    return normalized;
  }

  @override
  List<Object?> get props => [
        price,
        date,
        fuelType,
      ];
}