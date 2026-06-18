import 'package:flutter/material.dart';

import '../../../data/datasources/remote/history_api.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({
    super.key,
  });

  @override
  State<StatsScreen> createState() =>
      _StatsScreenState();
}

class _StatsScreenState
    extends State<StatsScreen> {
  bool _isLoading = true;
  String? _error;

  List<dynamic> _rides = [];
  Map<String, dynamic> _summary = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = HistoryApi();

      final historyResponse =
          await api.getMyHistory();

      final summaryResponse =
          await api.getMySummary();

      final historyData =
          historyResponse.data;

      final summaryData =
          summaryResponse.data;

      setState(() {
        _rides = historyData is List
            ? historyData
            : [];

        _summary = summaryData
                is Map<String, dynamic>
            ? summaryData
            : {};

        _isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'Error cargando estadísticas: $e',
      );

      setState(() {
        _error =
            'No se pudieron cargar las estadísticas';
        _isLoading = false;
      });
    }
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value.toString(),
        ) ??
        0;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value.toString(),
        ) ??
        0;
  }

  Map<String, dynamic>? _bestRide() {
    if (_rides.isEmpty) return null;

    final sorted = [..._rides];

    sorted.sort(
      (a, b) => _toDouble(
        b['profit'],
      ).compareTo(
        _toDouble(
          a['profit'],
        ),
      ),
    );

    return sorted.first
        as Map<String, dynamic>?;
  }

  Map<String, dynamic>? _worstRide() {
    if (_rides.isEmpty) return null;

    final sorted = [..._rides];

    sorted.sort(
      (a, b) => _toDouble(
        a['profit'],
      ).compareTo(
        _toDouble(
          b['profit'],
        ),
      ),
    );

    return sorted.first
        as Map<String, dynamic>?;
  }

  Widget _metricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor:
                  color.withValues(alpha:0.2),
              child: Icon(
                icon,
                color: color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rideHighlight({
    required String title,
    required Map<String, dynamic>? ride,
    required Color color,
    required IconData icon,
  }) {
    if (ride == null) {
      return Card(
        child: ListTile(
          leading: Icon(
            icon,
            color: color,
          ),
          title: Text(title),
          subtitle: const Text(
            'Sin datos todavía',
          ),
        ),
      );
    }

    final source =
        (ride['sourceApp'] ?? 'Desconocido')
            .toString();

    final profit =
        _toDouble(ride['profit']);

    final fare =
        _toDouble(ride['fare']);

    final profitPerKm =
        _toDouble(ride['profitPerKm']);

    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          color: color,
        ),
        title: Text(title),
        subtitle: Text(
          '$source • Tarifa ₡${fare.toStringAsFixed(0)} • ₡/km ${profitPerKm.toStringAsFixed(0)}',
        ),
        trailing: Text(
          '₡${profit.toStringAsFixed(0)}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    final total = _toInt(
      _summary['total'] ??
          _summary['totalTrips'],
    );

    final accepted = _toInt(
      _summary['accepted'] ??
          _summary['acceptedTrips'],
    );

    final rejected = _toInt(
      _summary['rejected'] ??
          _summary['rejectedTrips'],
    );

    final totalProfit =
        _toDouble(_summary['totalProfit']);

    final averageProfitPerKm =
        _toDouble(
      _summary['averageProfitPerKm'],
    );

    final acceptanceRate = total > 0
        ? (accepted / total) * 100
        : 0.0;

    final bestRide = _bestRide();

    final worstRide = _worstRide();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Estadísticas',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          padding:
              const EdgeInsets.all(16),
          children: [
            if (_error != null)
              Card(
                color: Colors.red.shade50,
                child: ListTile(
                  leading: const Icon(
                    Icons.error,
                    color: Colors.red,
                  ),
                  title: Text(_error!),
                ),
              ),

            _metricCard(
              title: 'Ganancia total',
              value:
                  '₡${totalProfit.toStringAsFixed(0)}',
              icon: Icons.attach_money,
              color: Colors.green,
            ),

            _metricCard(
              title:
                  'Ganancia promedio por km',
              value:
                  '₡${averageProfitPerKm.toStringAsFixed(0)}',
              icon: Icons.speed,
              color: Colors.blue,
            ),

            _metricCard(
              title: 'Tasa de aceptación',
              value:
                  '${acceptanceRate.toStringAsFixed(1)}%',
              icon: Icons.check_circle,
              color: Colors.orange,
            ),

            _metricCard(
              title: 'Viajes analizados',
              value: total.toString(),
              icon: Icons.route,
              color: Colors.purple,
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _metricCard(
                    title: 'Aceptados',
                    value:
                        accepted.toString(),
                    icon:
                        Icons.thumb_up,
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _metricCard(
                    title: 'Rechazados',
                    value:
                        rejected.toString(),
                    icon:
                        Icons.thumb_down,
                    color: Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            const Text(
              'Rendimiento',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            _rideHighlight(
              title: 'Mejor viaje',
              ride: bestRide,
              color: Colors.green,
              icon: Icons.trending_up,
            ),

            _rideHighlight(
              title: 'Peor viaje',
              ride: worstRide,
              color: Colors.red,
              icon: Icons.trending_down,
            ),
          ],
        ),
      ),
    );
  }
}