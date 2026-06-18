import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../data/models/restricted_hex_zone.dart';
import '../../../services/native_hex_zone_service.dart';
import '../../../services/restricted_hex_zone_service.dart';

class RestrictedHexZonesScreen extends StatefulWidget {
  const RestrictedHexZonesScreen({super.key});

  @override
  State<RestrictedHexZonesScreen> createState() =>
      _RestrictedHexZonesScreenState();
}

class _RestrictedHexZonesScreenState extends State<RestrictedHexZonesScreen> {
  final _zoneService = RestrictedHexZoneService();
  final Map<String, List<LatLng>> _hexPointsByIndex = {};

  static const LatLng _initialPosition = LatLng(
    9.8644,
    -83.9194,
  );

  static const double _hexRadiusMeters = 220;
  static const int _gridRadius = 11;
  static const double _hexSpacingFix = 0.985;

  LatLng _mapCenter = _initialPosition;

  Set<String> _selectedIndexes = {};
  Set<Polygon> _polygons = {};

  @override
  void initState() {
    super.initState();
    _loadZones();
    _generateHexagons(_initialPosition);
  }

  Future<void> _loadZones() async {
    final zones = await _zoneService.getZones();

    if (!mounted) return;

    setState(() {
      _selectedIndexes =
          zones.where((z) => z.enabled).map((z) => z.h3Index).toSet();
    });

    _generateHexagons(_mapCenter);

    await NativeHexZoneService.syncZones(zones);
  }

  Future<void> _saveZones() async {
    final zones = _selectedIndexes.map((index) {
      final points = _hexPointsByIndex[index] ?? [];

      return RestrictedHexZone(
        id: index,
        h3Index: index,
        enabled: true,
        points: points
            .map(
              (p) => {
                'lat': p.latitude,
                'lng': p.longitude,
              },
            )
            .toList(),
      );
    }).toList();

    await _zoneService.saveZones(zones);
    await NativeHexZoneService.syncZones(zones);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Zonas rojas guardadas'),
      ),
    );
  }

  void _generateHexagons(LatLng center) {
    final polygons = <Polygon>{};

    for (var row = -_gridRadius; row <= _gridRadius; row++) {
      for (var col = -_gridRadius; col <= _gridRadius; col++) {
        final hexCenter = _hexCenterFromOffset(
          center: center,
          row: row,
          col: col,
        );

        final index = _hexIndex(hexCenter);
        final selected = _selectedIndexes.contains(index);
        final points = _hexagonPoints(hexCenter);

        _hexPointsByIndex[index] = points;

        polygons.add(
          Polygon(
            polygonId: PolygonId(index),
            points: points,
            consumeTapEvents: true,
            strokeWidth: selected ? 2 : 1,
            strokeColor:
                selected ? Colors.red : Colors.red.withValues(alpha: 0.35),
            fillColor: selected
                ? Colors.red.withValues(alpha: 0.42)
                : Colors.red.withValues(alpha: 0.06),
            onTap: () => _toggleHex(index),
          ),
        );
      }
    }

    setState(() {
      _polygons = polygons;
    });
  }

  LatLng _hexCenterFromOffset({
    required LatLng center,
    required int row,
    required int col,
  }) {
    final dx = _hexRadiusMeters * 1.5 * _hexSpacingFix * col;

    final dy = _hexRadiusMeters * sqrt(3) * _hexSpacingFix * (row + col / 2);

    return _moveMeters(
      center,
      dx,
      dy,
    );
  }

  List<LatLng> _hexagonPoints(LatLng center) {
    final points = <LatLng>[];

    for (var i = 0; i < 6; i++) {
      final angle = pi / 180 * (60 * i - 30);

      final dx = _hexRadiusMeters * cos(angle);
      final dy = _hexRadiusMeters * sin(angle);

      points.add(
        _moveMeters(
          center,
          dx,
          dy,
        ),
      );
    }

    return points;
  }

  LatLng _moveMeters(
    LatLng origin,
    double eastMeters,
    double northMeters,
  ) {
    const earthRadius = 6378137.0;

    final dLat = northMeters / earthRadius;
    final dLng = eastMeters / (earthRadius * cos(pi * origin.latitude / 180));

    final lat = origin.latitude + dLat * 180 / pi;
    final lng = origin.longitude + dLng * 180 / pi;

    return LatLng(lat, lng);
  }

  String _hexIndex(LatLng center) {
    final lat = (center.latitude * 100000).round();
    final lng = (center.longitude * 100000).round();

    return 'HEX_${lat}_$lng';
  }

  void _toggleHex(String index) {
    setState(() {
      if (_selectedIndexes.contains(index)) {
        _selectedIndexes.remove(index);
      } else {
        _selectedIndexes.add(index);
      }
    });

    _generateHexagons(_mapCenter);
  }

  void _clearSelection() {
    setState(() {
      _selectedIndexes.clear();
    });

    _generateHexagons(_mapCenter);
  }

  void _onCameraMove(CameraPosition position) {
    _mapCenter = position.target;
  }

  void _onCameraIdle() {
    _generateHexagons(_mapCenter);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zonas rojas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearSelection,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveZones,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _initialPosition,
              zoom: 13.5,
            ),
            polygons: _polygons,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedIndexes.isEmpty
                            ? 'Toca hexágonos para marcarlos como zona roja.'
                            : 'Zonas rojas seleccionadas: ${_selectedIndexes.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _saveZones,
                      child: const Text('Guardar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
