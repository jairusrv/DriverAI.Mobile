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
    final icon = _getDecisionIcon(result.decision);

    late OverlaySupportEntry entry;

    entry = showOverlay(
      (context, t) {
        return Positioned(
          top: 38,
          left: 8,
          right: 8,
          child: SafeArea(
            child: Material(
              color: Colors.transparent,
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 380,
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    12,
                    10,
                    8,
                    10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151515)
                        .withOpacity(0.96),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: color,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.35),
                        blurRadius: 14,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.only(right: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$title $icon ₡${result.profitPerKm.toStringAsFixed(0)} / km',
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: color,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (ride != null)
                              Text(
                                '[${ride.provider.toUpperCase()}] 🚗 ${ride.distanceKm.toStringAsFixed(1)} km | ⏱ ${ride.durationMinutes} min',
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            const SizedBox(height: 5),
                            Text(
                              '💵 Pago: ₡${ride?.fare.toStringAsFixed(0) ?? '-'} | 📊 Real: ₡${result.netProfit.toStringAsFixed(0)}',
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '🔧 Reserva: ₡${result.maintenanceReserve.toStringAsFixed(0)} | ₡${result.maintenanceCostPerKm.toStringAsFixed(0)}/km',
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              result.recommendation,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10.5,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: -6,
                        right: -4,
                        child: GestureDetector(
                          onTap: () => entry.dismiss(),
                          child: Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            child: const Text(
                              '×',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      duration: const Duration(seconds: 12),
    );
  }

  static Color _getDecisionColor(
    RideDecision decision,
  ) {
    switch (decision) {
      case RideDecision.accept:
        return Colors.greenAccent;
      case RideDecision.acceptable:
        return Colors.amberAccent;
      case RideDecision.reject:
        return Colors.redAccent;
    }
  }

  static String _getDecisionTitle(
    RideDecision decision,
  ) {
    switch (decision) {
      case RideDecision.accept:
        return 'ACEPTAR';
      case RideDecision.acceptable:
        return 'ACEPTABLE';
      case RideDecision.reject:
        return 'RECHAZAR';
    }
  }

  static String _getDecisionIcon(
    RideDecision decision,
  ) {
    switch (decision) {
      case RideDecision.accept:
        return '✓';
      case RideDecision.acceptable:
        return '!';
      case RideDecision.reject:
        return '✕';
    }
  }
}