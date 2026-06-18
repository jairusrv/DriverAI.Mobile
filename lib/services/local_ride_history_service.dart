import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalRideHistoryService {
  static final LocalRideHistoryService instance =
      LocalRideHistoryService._();

  LocalRideHistoryService._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;

    final databasesPath = await getDatabasesPath();

    final path = join(
      databasesPath,
      'driverai_history.db',
    );

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE ride_history(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            provider TEXT NOT NULL,
            decision TEXT NOT NULL,
            fare REAL NOT NULL,
            total_km REAL NOT NULL,
            total_minutes INTEGER NOT NULL,
            profit_per_km REAL NOT NULL,
            net_profit REAL NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );

    return _db!;
  }

  Future<void> saveRide({
    required String provider,
    required String decision,
    required double fare,
    required double totalKm,
    required int totalMinutes,
    required double profitPerKm,
    required double netProfit,
  }) async {
    final db = await database;

    await db.insert(
      'ride_history',
      {
        'provider': provider,
        'decision': decision,
        'fare': fare,
        'total_km': totalKm,
        'total_minutes': totalMinutes,
        'profit_per_km': profitPerKm,
        'net_profit': netProfit,
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<int> totalOffers() async {
    final db = await database;

    final result = await db.rawQuery(
      'SELECT COUNT(*) as total FROM ride_history',
    );

    return result.first['total'] as int;
  }

  Future<double> totalPotentialProfit() async {
    final db = await database;

    final result = await db.rawQuery(
      '''
      SELECT COALESCE(
        SUM(net_profit),
        0
      ) as total
      FROM ride_history
      '''
    );

    return (result.first['total'] as num).toDouble();
  }

  Future<int> acceptedOffers() async {
    final db = await database;

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as total
      FROM ride_history
      WHERE decision = 'ACEPTAR'
      '''
    );

    return result.first['total'] as int;
  }

  Future<int> rejectedOffers() async {
    final db = await database;

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as total
      FROM ride_history
      WHERE decision = 'RECHAZAR'
      '''
    );

    return result.first['total'] as int;
  }

  Future<List<Map<String, dynamic>>> latestOffers() async {
    final db = await database;

    return db.query(
      'ride_history',
      orderBy: 'id DESC',
      limit: 100,
    );
  }
}