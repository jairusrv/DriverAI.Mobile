import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';

import '../data/models/ride_data.dart';
import '../domain/calculators/profitability_calculator.dart';

class OverlayService {
  static void showProfitabilityOverlay(
    ProfitabilityResult result, {
    RideData? ride,
  }) {
    final color =
        _getDecisionColor(result.decision);

    final title =
        _getDecisionTitle(result.decision);

    showOverlay(
      (context, t) {
        return Positioned(
          top: 45,
          left: 55,
          right: 55,
          child: SafeArea(
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black
                      .withOpacity(0.88),
                  borderRadius:
                      BorderRadius.circular(18),
                  border: Border.all(
                    color: color,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color
                          .withOpacity(0.35),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: color,
                            fontSize: 15,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '₡ ${result.profitPerKm.toStringAsFixed(0)} / km',
                          style: TextStyle(
                            color: color,
                            fontSize: 24,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    if (ride != null)
                      Text(
                        '[${ride.provider.toUpperCase()}] 🚗 ${ride.distanceKm.toStringAsFixed(1)} km | ⏱ ${ride.durationMinutes} min',
                        textAlign:
                            TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),

                    const SizedBox(height: 4),

                    Text(
                      '💵 Tarifa: ₡${ride?.fare.toStringAsFixed(0) ?? '-'} | 📊 Ganancia: ₡${result.netProfit.toStringAsFixed(0)}',
                      textAlign:
                          TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      '⛽ Costo: ₡${result.totalCost.toStringAsFixed(0)} | Margen: ${result.profitPercentage.toStringAsFixed(1)}%',
                      textAlign:
                          TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      result.recommendation,
                      textAlign:
                          TextAlign.center,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      duration: const Duration(seconds: 10),
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
}