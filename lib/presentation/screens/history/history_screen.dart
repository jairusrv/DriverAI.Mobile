import 'package:flutter/material.dart';

import '../../../data/datasources/remote/history_api.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;
  String? _error;

  List<dynamic> _rides = [];
  Map<String, dynamic>? _summary;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final historyApi = HistoryApi();

      final ridesResponse = await historyApi.getMyHistory();

      final summaryResponse = await historyApi.getMySummary();

      final ridesData = ridesResponse.data;
      final summaryData = summaryResponse.data;

      setState(() {
        _rides = ridesData is List ? ridesData : [];

        _summary = summaryData is Map<String, dynamic> ? summaryData : {};

        _isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'Error cargando historial: $e',
      );

      setState(() {
        _error = 'No se pudo cargar el historial';
        _isLoading = false;
      });
    }
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                color: color,
                size: 32,
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final totalTrips = _toInt(
      _summary?['total'] ?? _summary?['totalTrips'],
    );

    final acceptedTrips = _toInt(
      _summary?['accepted'] ?? _summary?['acceptedTrips'],
    );

    final rejectedTrips = _toInt(
      _summary?['rejected'] ?? _summary?['rejectedTrips'],
    );

    final totalProfit = _toDouble(
      _summary?['totalProfit'],
    );

    final averageProfitPerKm = _toDouble(
      _summary?['averageProfitPerKm'],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Historial',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
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
            Row(
              children: [
                _buildStatCard(
                  title: 'Viajes',
                  value: totalTrips.toString(),
                  icon: Icons.route,
                  color: Colors.blue,
                ),
                _buildStatCard(
                  title: 'Aceptados',
                  value: acceptedTrips.toString(),
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
              ],
            ),
            Row(
              children: [
                _buildStatCard(
                  title: 'Rechazados',
                  value: rejectedTrips.toString(),
                  icon: Icons.cancel,
                  color: Colors.red,
                ),
                _buildStatCard(
                  title: 'Ganancia Total',
                  value: '₡${totalProfit.toStringAsFixed(0)}',
                  icon: Icons.attach_money,
                  color: Colors.orange,
                ),
              ],
            ),
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.speed,
                ),
                title: const Text(
                  'Ganancia promedio por KM',
                ),
                subtitle: Text(
                  '₡${averageProfitPerKm.toStringAsFixed(0)}',
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Últimos viajes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            if (_rides.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No hay viajes registrados',
                  ),
                ),
              ),
            ..._rides.map(
              (ride) {
                final decision = (ride['decision'] ?? '').toString();

                final accepted = decision.toUpperCase() == 'ACEPTAR';

                final fare = _toDouble(
                  ride['fare'],
                );

                final profit = _toDouble(
                  ride['profit'],
                );

                final distanceKm = _toDouble(
                  ride['distanceKm'],
                );

                final profitPerKm = _toDouble(
                  ride['profitPerKm'],
                );

                final sourceApp =
                    (ride['sourceApp'] ?? 'Desconocido').toString();

                return Card(
                  child: ListTile(
                    leading: Icon(
                      accepted ? Icons.check_circle : Icons.cancel,
                      color: accepted ? Colors.green : Colors.red,
                    ),
                    title: Text(
                      '$sourceApp • ₡${fare.toStringAsFixed(0)}',
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ganancia: ₡${profit.toStringAsFixed(0)}',
                        ),
                        Text(
                          'Distancia: ${distanceKm.toStringAsFixed(1)} km',
                        ),
                        Text(
                          '₡/km: ${profitPerKm.toStringAsFixed(0)}',
                        ),
                      ],
                    ),
                    trailing: Text(
                      decision,
                      style: TextStyle(
                        color: accepted ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
