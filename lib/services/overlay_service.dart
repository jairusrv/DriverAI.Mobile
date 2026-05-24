// services/overlay_service.dart
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import '../domain/calculators/profitability_calculator.dart';

class OverlayService {
  static void showProfitabilityOverlay(ProfitabilityResult result) {
  showOverlay(
    (context, t) {
      return Positioned(
        // ... estilos similares
        child: Container(
          // ...
          child: Column(
            children: [
              Text(result.isProfitable ? '✅ Viaje Rentable' : '❌ Viaje No Rentable'),
              Text('Ganancia neta: ₡${result.netProfit.toStringAsFixed(0)}'),
              Text('Margen: ${result.profitPercentage.toStringAsFixed(1)}%'),
              Text(result.recommendation),
            ],
          ),
        ),
      );
    },
    duration: const Duration(seconds: 10),
  );
}
}