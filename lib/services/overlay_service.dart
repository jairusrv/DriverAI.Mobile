import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';

import '../data/models/ride_data.dart';
import '../domain/calculators/profitability_calculator.dart';

class OverlayService {
  static void showProfitabilityOverlay(
    ProfitabilityResult result, {
    RideData? ride,
  }) {
    final color = _getDecisionColor(result.decision);
    final title = _getDecisionTitle(result.decision);

    showOverlay(
      (context, t) {
        return Positioned(
          top: 38,
          left: 56,
          right: 56,
          child: SafeArea(
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111).withOpacity(0.94),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: color,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.40),
                      blurRadius: 16,
                      spreadRadius: 1.5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₡ ${result.profitPerKm.toStringAsFixed(2)} / km',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: color,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (ride != null)
                      Text(
                        '${_providerLabel(ride.provider)} 🚗 ${ride.distanceKm.toStringAsFixed(1)} km | ⏱ ${ride.durationMinutes} min',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    const SizedBox(height: 5),
                    Text(
                      '🔧 ₡${result.maintenanceReserve.toStringAsFixed(0)} | 📈 ₡${result.netProfit.toStringAsFixed(0)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.recommendation,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      duration: const Duration(seconds: 8),
    );
  }

  static Color _getDecisionColor(RideDecision decision) {
    switch (decision) {
      case RideDecision.accept:
        return Colors.greenAccent;
      case RideDecision.acceptable:
        return Colors.orangeAccent;
      case RideDecision.reject:
        return Colors.redAccent;
    }
  }

  static String _getDecisionTitle(RideDecision decision) {
    switch (decision) {
      case RideDecision.accept:
        return 'ACEPTAR';
      case RideDecision.acceptable:
        return 'ACEPTABLE';
      case RideDecision.reject:
        return 'RECHAZAR';
    }
  }

  static String _providerLabel(String provider) {
    final normalized = provider.toLowerCase();

    if (normalized.contains('uber')) {
      return '[UBER]';
    }

    if (normalized.contains('didi')) {
      return '[DIDI]';
    }

    return '[APP]';
  }
}