import 'package:driverai_mobile/presentation/providers/user_preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/fuel_price_session_service.dart';
import '../../../data/datasources/remote/api_client.dart';
import '../../../data/datasources/remote/recope_api.dart';
import '../../../data/datasources/remote/settings_api.dart';
import '../../../domain/entities/user_parameters.dart';
import '../../../services/recope_service.dart';

class UserConfigScreen extends ConsumerStatefulWidget 
{
  const UserConfigScreen({
    super.key,
  });

  @override
  ConsumerState<UserConfigScreen> createState() =>
      _UserConfigScreenState();
}

class _UserConfigScreenState
    extends ConsumerState<UserConfigScreen> 
{
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _efficiencyController;
  late TextEditingController _commissionController;
  late TextEditingController _fixedCostController;
  late TextEditingController _fuelPriceController;
  late TextEditingController _maxPickupController;
  late TextEditingController _maxTripController;

  String _selectedFuelType = 'regular';
  String _selectedServiceType = 'Driver';
  String _selectedPlatform = 'Uber';

  bool _notificationsEnabled = true;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isLoadingFuelPrice = false;
  bool get _isManualFuelPrice {
  return _selectedFuelType == 'gas_lp' ||
      _selectedFuelType == 'electric';
  }
  @override
  void initState() {
    super.initState();

    final params = ref.read(userParametersProvider);

    _efficiencyController = TextEditingController(
      text: params.vehicleEfficiency.toString(),
    );

    _commissionController = TextEditingController(
      text: params.desiredCommission.toString(),
    );

    _fixedCostController = TextEditingController(
      text: params.fixedCostPerTrip.toString(),
    );

    _fuelPriceController = TextEditingController(
      text: '0',
    );

    _maxPickupController = TextEditingController(
      text: '5',
    );

    _maxTripController = TextEditingController(
      text: '25',
    );

    _selectedFuelType = _normalizeFuelType(
      params.fuelType,
    );

    _notificationsEnabled = params.notificationsEnabled;

    _loadInitialData();
  }
  

  Future<void> _loadInitialData() async {
  await _loadRemoteSettings();
  await FuelPriceSessionService.getPrices();
  await _updateFuelPrice();

  if (mounted) {
    setState(() {
      _isLoading = false;
    });
  }
}

  Future<void> _loadRemoteSettings() async {
    try {
      final response = await SettingsApi().getMySettings();

      if (response.statusCode == 200 &&
          response.data != null) {
        final data = response.data;

        _selectedFuelType = _normalizeFuelType(
          data['fuelType'] ?? _selectedFuelType,
        );

        _efficiencyController.text =
            (data['kmPerLiter'] ?? 12).toString();

        _commissionController.text =
            (data['minimumProfitPerKm'] ?? 350).toString();

        _maxPickupController.text =
            (data['maxPickupDistance'] ?? 5).toString();

        _maxTripController.text =
            (data['maxTripDistance'] ?? 25).toString();
        
        _selectedServiceType =
            data['serviceType'] ?? _selectedServiceType;
        
        _selectedPlatform =
            data['platform'] ?? _selectedPlatform;

        final newParams = UserParameters(
          vehicleEfficiency: double.tryParse(
                _efficiencyController.text,
              ) ??
              12,
          desiredCommission: double.tryParse(
                _commissionController.text,
              ) ??
              350,
          fixedCostPerTrip: double.tryParse(
                _fixedCostController.text,
              ) ??
              500,
          fuelType: _selectedFuelType,
          notificationsEnabled: _notificationsEnabled,
        );

        await ref
            .read(userParametersProvider.notifier)
            .saveParameters(newParams);
      }
    } catch (e) {
      debugPrint(
        'No se pudo cargar configuración remota: $e',
      );
    }
  }

  Future<void> _updateFuelPrice() async {
  if (_isManualFuelPrice) {
    if (_fuelPriceController.text.isEmpty) {
      _fuelPriceController.text = '0';
    }

    return;
  }

  setState(() {
    _isLoadingFuelPrice = true;
    _fuelPriceController.text = '';
  });

  try {
    final price =
        await FuelPriceSessionService.getPriceFor(
      _selectedFuelType,
    );

    if (mounted) {
      setState(() {
        _fuelPriceController.text =
            price.toStringAsFixed(0);
      });
    }
  } catch (e) {
    debugPrint(
      'Error obteniendo precio desde sesión: $e',
    );

    if (mounted) {
      setState(() {
        _fuelPriceController.text = '0';
      });
    }
  } finally {
    if (mounted) {
      setState(() {
        _isLoadingFuelPrice = false;
      });
    }
  }
}

  String _normalizeFuelType(String value) {
    final normalized = value.toLowerCase().trim();

    if (normalized.contains('super') ||
        normalized.contains('súper')) {
      return 'super';
    }

    if (normalized.contains('regular') ||
        normalized.contains('gasolina')) {
      return 'regular';
    }

    if (normalized.contains('diesel') ||
        normalized.contains('diésel')) {
      return 'diesel';
    }

    if (normalized.contains('electric') ||
        normalized.contains('eléctrico') ||
        normalized.contains('electrico')) {
      return 'electric';
    }

    return 'regular';
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final newParams = UserParameters(
        vehicleEfficiency: double.parse(
          _efficiencyController.text,
        ),
        desiredCommission: double.parse(
          _commissionController.text,
        ),
        fixedCostPerTrip: double.parse(
          _fixedCostController.text,
        ),
        fuelType: _selectedFuelType,
        notificationsEnabled: _notificationsEnabled,
      );

      await ref
          .read(userParametersProvider.notifier)
          .saveParameters(newParams);

      await SettingsApi().saveMySettings(
        fuelType: _selectedFuelType,
        fuelPrice: double.parse(
          _fuelPriceController.text,
        ),
        kmPerLiter: double.parse(
          _efficiencyController.text,
        ),
        minimumProfitPerKm: double.parse(
          _commissionController.text,
        ),
        serviceType: _selectedServiceType,

        platform: _selectedPlatform,

        maxPickupDistance: double.parse(
          _maxPickupController.text,
        ),
        maxTripDistance: double.parse(
          _maxTripController.text,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error guardando configuración: $e',
            ),
            backgroundColor: Colors.red,
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

  String? _validatePositive(String? value) {
    if (value == null || value.isEmpty) {
      return 'Requerido';
    }

    final parsed = double.tryParse(value);

    if (parsed == null || parsed < 0) {
      return 'Debe ser un número válido';
    }

    return null;
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Configuración del Vehículo',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
  elevation: 3,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  ),
  child: Padding(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📱 Tipo de servicio',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedServiceType = 'Delivery';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedServiceType == 'Delivery'
                          ? Colors.black87
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'DELIVERY',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _selectedServiceType == 'Delivery'
                            ? Colors.white
                            : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedServiceType = 'Driver';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedServiceType == 'Driver'
                          ? Colors.black87
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'DRIVER',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _selectedServiceType == 'Driver'
                            ? Colors.white
                            : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  ),
),
const SizedBox(height: 20),
Card(
  elevation: 3,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  ),
  child: Padding(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📱 Plataforma a configurar',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPlatform = 'Uber';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedPlatform == 'Uber'
                          ? Colors.black87
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'UBER',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _selectedPlatform == 'Uber'
                            ? Colors.white
                            : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPlatform = 'Didi';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedPlatform == 'Didi'
                          ? Colors.black87
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'DIDI',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _selectedPlatform == 'Didi'
                            ? Colors.white
                            : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  ),
),
const SizedBox(height: 20),
            const Text(
              'Combustible',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            DropdownButtonFormField<String>(
              value: _selectedFuelType,
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
                  value: 'gas_lp',
                  child: Text('Gas-LP'),
                ),
                DropdownMenuItem(
                  value: 'electric',
                  child: Text('Eléctrico'),
                ),
              ],
              onChanged: (value) async {
  if (value == null) {
    return;
  }

  setState(() {
    _selectedFuelType = value;
    _fuelPriceController.text = '';
  });

  ref
      .read(userParametersProvider.notifier)
      .updateFuelType(value);

  await _updateFuelPrice();
},
              decoration: const InputDecoration(
                labelText: 'Tipo de combustible',
              ),
            ),

            const SizedBox(height: 16),
/// El campo de precio se vuelve editable si el tipo de combustible es gas_lp o eléctrico
            TextFormField(
  controller: _fuelPriceController,
  readOnly: !_isManualFuelPrice,
  enabled: true,
  keyboardType: TextInputType.number,
  decoration: InputDecoration(
    labelText: _isManualFuelPrice
        ? 'Precio combustible manual'
        : _isLoadingFuelPrice
            ? 'Cargando precio RECOPE...'
            : 'Precio combustible RECOPE',
    prefixText: '₡ ',
    suffixIcon: _isManualFuelPrice
        ? const Icon(Icons.edit)
        : _isLoadingFuelPrice
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              )
            : const Icon(Icons.lock),
  ),
  validator: _validatePositive,
),

            const SizedBox(height: 24),

            const Text(
              'Rendimiento del vehículo',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            TextFormField(
              controller: _efficiencyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Kilómetros por litro',
                suffixText: 'km/L',
              ),
              validator: _validatePositive,
            ),

            const SizedBox(height: 24),

            const Text(
              'Reglas de rentabilidad',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            TextFormField(
              controller: _commissionController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Ganancia mínima por km',
                prefixText: '₡ ',
              ),
              validator: _validatePositive,
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _fixedCostController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Costo fijo por viaje',
                prefixText: '₡ ',
              ),
              validator: _validatePositive,
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _maxPickupController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Distancia máxima de recogida',
                suffixText: 'km',
              ),
              validator: _validatePositive,
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _maxTripController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Distancia máxima del viaje',
                suffixText: 'km',
              ),
              validator: _validatePositive,
            ),

            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text(
                'Mostrar overlay automáticamente',
              ),
              subtitle: const Text(
                'Al desactivar, no se mostrará el análisis automático',
              ),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });

                ref
                    .read(userParametersProvider.notifier)
                    .updateNotificationsEnabled(value);
              },
            ),

            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save),
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