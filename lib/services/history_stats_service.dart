import 'package:sqflite/sqflite.dart';

class HistoryStatsService {
  final Database database;

  HistoryStatsService(this.database);

  Future<Map<String, dynamic>> loadStats() async {
    final totalOffersResult = await database.rawQuery(
      '''
      SELECT COUNT(*) as total
      FROM ride_history
      '''
    );

    final acceptedResult = await database.rawQuery(
      '''
      SELECT COUNT(*) as total
      FROM ride_history
      WHERE decision = 'ACEPTAR'
      '''
    );

    final reviewResult = await database.rawQuery(
      '''
      SELECT COUNT(*) as total
      FROM ride_history
      WHERE decision = 'REVISAR'
      '''
    );

    final rejectedResult = await database.rawQuery(
      '''
      SELECT COUNT(*) as total
      FROM ride_history
      WHERE decision = 'RECHAZAR'
      '''
    );

    final profitResult = await database.rawQuery(
      '''
      SELECT COALESCE(
        SUM(net_profit),
        0
      ) as total
      FROM ride_history
      '''
    );

    final avgProfitKmResult = await database.rawQuery(
      '''
      SELECT COALESCE(
        AVG(profit_per_km),
        0
      ) as average
      FROM ride_history
      '''
    );

    return {
      'totalOffers':
          totalOffersResult.first['total'] ?? 0,

      'accepted':
          acceptedResult.first['total'] ?? 0,

      'review':
          reviewResult.first['total'] ?? 0,

      'rejected':
          rejectedResult.first['total'] ?? 0,

      'potentialProfit':
          profitResult.first['total'] ?? 0,

      'avgProfitKm':
          avgProfitKmResult.first['average'] ?? 0,
    };
  }
}