import 'package:driverai_mobile/presentation/providers/user_preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/datasources/remote/api_client.dart';
import '../../../data/datasources/remote/recope_api.dart';
import '../../../data/datasources/remote/settings_api.dart';
import '../../../data/models/fuel_price.dart';
import '../../../domain/entities/user_parameters.dart';

class UserConfigScreen extends ConsumerStatefulWidget {
  const UserConfigScreen({
    super.key,
  });

  @override
  ConsumerState<UserConfigScreen> createState() =>
      _UserConfigScreenState();
}

class _UserConfigScreenState
    extends ConsumerState<UserConfigScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController
      _efficiencyController;

  late TextEditingController
      _commissionController;

  late TextEditingController
      _fixedCostController;

  late TextEditingController
      _fuelPriceController;

  late TextEditingController
      _maxPickupController;

  late TextEditingController
      _maxTripController;

  String _selectedFuelType = 'regular';

  bool _notificationsEnabled = true;

  bool _isLoading = true;

  bool _isSaving = false;

  List<FuelPrice> _fuelPrices = [];

  @override
  void initState() {
    super.initState();

    final params =
        ref.read(userParametersProvider);

    _efficiencyController =
        TextEditingController(
      text: params.vehicleEfficiency.toString(),
    );

    _commissionController =
        TextEditingController(
      text: params.desiredCommission.toString(),
    );

    _fixedCostController =
        TextEditingController(
      text: params.fixedCostPerTrip.toString(),
    );

    _fuelPriceController =
        TextEditingController(
      text: '0',
    );

    _maxPickupController =
        TextEditingController(
      text: '5',
    );

    _maxTripController =
        TextEditingController(
      text: '25',
    );

    _selectedFuelType = params.fuelType;
    _notificationsEnabled =
        params.notificationsEnabled;

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadFuelPrices();
    await _loadRemoteSettings();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFuelPrices() async {
    try {
      final api = RecopeApi(
        ApiClient().dio,
      );

      final response =
          await api.getFuelPrices();

      if (response.success &&
          response.data != null) {
        _fuelPrices = response.data!;
        _applyFuelPrice();
      }
    } catch (e) {
      debugPrint(
        'Error cargando precios RECOPE: $e',
      );
    }
  }

  Future<void> _loadRemoteSettings()
      async {
    try {
      final response =
          await SettingsApi()
              .getMySettings();

      if (response.statusCode == 200 &&
          response.data != null) {
        final data = response.data;

        _selectedFuelType =
            data['fuelType'] ??
                _selectedFuelType;

        _efficiencyController.text =
            (data['kmPerLiter'] ?? 12)
                .toString();

        _commissionController.text =
            (data['minimumProfitPerKm'] ??
                    350)
                .toString();

        _maxPickupController.text =
            (data['maxPickupDistance'] ?? 5)
                .toString();

        _maxTripController.text =
            (data['maxTripDistance'] ?? 25)
                .toString();

        _applyFuelPrice();

        final newParams =
            UserParameters(
          vehicleEfficiency:
              double.tryParse(
                    _efficiencyController
                        .text,
                  ) ??
                  12,
          desiredCommission:
              double.tryParse(
                    _commissionController
                        .text,
                  ) ??
                  350,
          fixedCostPerTrip:
              double.tryParse(
                    _fixedCostController
                        .text,
                  ) ??
                  500,
          fuelType:
              _selectedFuelType,
          notificationsEnabled:
              _notificationsEnabled,
        );

        await ref
            .read(
              userParametersProvider
                  .notifier,
            )
            .saveParameters(
              newParams,
            );
      }
    } catch (e) {
      debugPrint(
        'No se pudo cargar configuración remota: $e',
      );
    }
  }

  void _applyFuelPrice() {
    double price = 0;

    if (_selectedFuelType ==
        'electric') {
      price = 0;
    } else {
      final match =
          _fuelPrices.where((fuel) {
        return fuel.fuelType
                .toLowerCase()
                .trim() ==
            _selectedFuelType
                .toLowerCase()
                .trim();
      }).toList();

      if (match.isNotEmpty) {
        price = match.first.price;
      }
    }

    _fuelPriceController.text =
        price.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _efficiencyController.dispose();
    _commissionController.dispose();
    _fixedCostController.dispose();
    _fuelPriceController.dispose();
    _maxPickupController.dispose();
    _maxTripController.dispose();

    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final newParams =
          UserParameters(
        vehicleEfficiency:
            double.parse(
          _efficiencyController.text,
        ),
        desiredCommission:
            double.parse(
          _commissionController.text,
        ),
        fixedCostPerTrip:
            double.parse(
          _fixedCostController.text,
        ),
        fuelType:
            _selectedFuelType,
        notificationsEnabled:
            _notificationsEnabled,
      );

      await ref
          .read(
            userParametersProvider
                .notifier,
          )
          .saveParameters(
            newParams,
          );

      await SettingsApi()
          .saveMySettings(
        fuelType: _selectedFuelType,
        fuelPrice: double.parse(
          _fuelPriceController.text,
        ),
        kmPerLiter: double.parse(
          _efficiencyController.text,
        ),
        minimumProfitPerKm:
            double.parse(
          _commissionController.text,
        ),
        maxPickupDistance:
            double.parse(
          _maxPickupController.text,
        ),
        maxTripDistance:
            double.parse(
          _maxTripController.text,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Configuración guardada correctamente',
            ),
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'Error guardando configuración: $e',
            ),
            backgroundColor:
                Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String? _validatePositive(
    String? value,
  ) {
    if (value == null ||
        value.isEmpty) {
      return 'Requerido';
    }

    final parsed =
        double.tryParse(value);

    if (parsed == null ||
        parsed < 0) {
      return 'Debe ser un número válido';
    }

    return null;
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Configuración del Vehículo',
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.save,
            ),
            onPressed:
                _isSaving ? null : _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding:
              const EdgeInsets.all(16),
          children: [
            const Text(
              'Combustible',
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            DropdownButtonFormField<String>(
              value:
                  _selectedFuelType,
              items: const [
                DropdownMenuItem(
                  value: 'super',
                  child: Text('Súper'),
                ),
                DropdownMenuItem(
                  value: 'regular',
                  child: Text('Regular'),
                ),
                DropdownMenuItem(
                  value: 'diesel',
                  child: Text('Diésel'),
                ),
                DropdownMenuItem(
                  value: 'electric',
                  child: Text('Eléctrico'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedFuelType =
                        value;
                    _applyFuelPrice();
                  });

                  ref
                      .read(
                        userParametersProvider
                            .notifier,
                      )
                      .updateFuelType(
                        value,
                      );
                }
              },
              decoration:
                  const InputDecoration(
                labelText:
                    'Tipo de combustible',
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            TextFormField(
              controller:
                  _fuelPriceController,
              readOnly: true,
              enabled: false,
              decoration:
                  const InputDecoration(
                labelText:
                    'Precio combustible RECOPE',
                prefixText: '₡ ',
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            const Text(
              'Rendimiento del vehículo',
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            TextFormField(
              controller:
                  _efficiencyController,
              keyboardType:
                  TextInputType.number,
              decoration:
                  const InputDecoration(
                labelText:
                    'Kilómetros por litro',
                suffixText: 'km/L',
              ),
              validator:
                  _validatePositive,
            ),

            const SizedBox(
              height: 24,
            ),

            const Text(
              'Reglas de rentabilidad',
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            TextFormField(
              controller:
                  _commissionController,
              keyboardType:
                  TextInputType.number,
              decoration:
                  const InputDecoration(
                labelText:
                    'Ganancia mínima por km',
                prefixText: '₡ ',
              ),
              validator:
                  _validatePositive,
            ),

            const SizedBox(
              height: 16,
            ),

            TextFormField(
              controller:
                  _fixedCostController,
              keyboardType:
                  TextInputType.number,
              decoration:
                  const InputDecoration(
                labelText:
                    'Costo fijo por viaje',
                prefixText: '₡ ',
              ),
              validator:
                  _validatePositive,
            ),

            const SizedBox(
              height: 16,
            ),

            TextFormField(
              controller:
                  _maxPickupController,
              keyboardType:
                  TextInputType.number,
              decoration:
                  const InputDecoration(
                labelText:
                    'Distancia máxima de recogida',
                suffixText: 'km',
              ),
              validator:
                  _validatePositive,
            ),

            const SizedBox(
              height: 16,
            ),

            TextFormField(
              controller:
                  _maxTripController,
              keyboardType:
                  TextInputType.number,
              decoration:
                  const InputDecoration(
                labelText:
                    'Distancia máxima del viaje',
                suffixText: 'km',
              ),
              validator:
                  _validatePositive,
            ),

            const SizedBox(
              height: 16,
            ),

            SwitchListTile(
              title: const Text(
                'Mostrar overlay automáticamente',
              ),
              subtitle: const Text(
                'Al desactivar, no se mostrará el análisis automático',
              ),
              value:
                  _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled =
                      value;
                });

                ref
                    .read(
                      userParametersProvider
                          .notifier,
                    )
                    .updateNotificationsEnabled(
                      value,
                    );
              },
            ),

            const SizedBox(
              height: 32,
            ),

            ElevatedButton.icon(
              onPressed:
                  _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.save,
                    ),
              label: Text(
                _isSaving
                    ? 'Guardando...'
                    : 'Guardar configuración',
              ),
            ),
          ],
        ),
      ),
    );
  }
}