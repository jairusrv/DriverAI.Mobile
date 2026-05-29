import 'package:driverai_mobile/presentation/providers/user_preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/datasources/remote/settings_api.dart';
import '../../../domain/entities/user_parameters.dart';
import '../../../services/fuel_price_session_service.dart';

class UserConfigScreen extends ConsumerStatefulWidget {
  const UserConfigScreen({super.key});

  @override
  ConsumerState<UserConfigScreen> createState() => _UserConfigScreenState();
}

class _UserConfigScreenState extends ConsumerState<UserConfigScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _efficiencyController;
  late TextEditingController _commissionController;
  late TextEditingController _fuelPriceController;
  late TextEditingController _maintenanceCostController;
  late TextEditingController _maxPickupController;
  late TextEditingController _maxTripController;

  String _selectedFuelType = 'regular';
  String _selectedServiceType = 'Driver';
  String _selectedPlatform = 'Uber';
  String _selectedVehicleType = 'motorcycle';

  bool _notificationsEnabled = true;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isLoadingFuelPrice = false;

  final Map<String, double> _maintenanceByVehicleType = {
    'motorcycle': 30,
    'sedan': 50,
    'suv': 75,
    'electric_vehicle': 25,
  };

  bool get _isManualFuelPrice {
    return _selectedFuelType == 'gas_lp' ||
        _selectedFuelType == 'electric';
  }

  double get _acceptableProfit {
    final minimum =
        double.tryParse(_commissionController.text) ?? 300;
    return minimum * 0.75;
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

    _fuelPriceController = TextEditingController(text: '0');

    _maintenanceCostController = TextEditingController(
      text: _maintenanceByVehicleType[_selectedVehicleType]!
          .toStringAsFixed(0),
    );

    _maxPickupController = TextEditingController(text: '5');
    _maxTripController = TextEditingController(text: '25');

    _selectedFuelType = _normalizeFuelType(params.fuelType);
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

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;

        _selectedFuelType = _normalizeFuelType(
          data['fuelType'] ?? _selectedFuelType,
        );

        _efficiencyController.text =
            (data['kmPerLiter'] ?? 12).toString();

        _commissionController.text =
            (data['minimumProfitPerKm'] ?? 300).toString();

        _maxPickupController.text =
            (data['maxPickupDistance'] ?? 5).toString();

        _maxTripController.text =
            (data['maxTripDistance'] ?? 25).toString();

        _selectedServiceType =
            data['serviceType'] ?? _selectedServiceType;

        _selectedPlatform =
            data['platform'] ?? _selectedPlatform;

        _selectedVehicleType =
            data['vehicleType'] ?? _selectedVehicleType;

        final maintenance =
            data['maintenanceCostPerKm'] ??
                _maintenanceByVehicleType[_selectedVehicleType] ??
                30;

        _maintenanceCostController.text =
            maintenance.toString();

        final newParams = UserParameters(
          vehicleEfficiency: double.tryParse(
                _efficiencyController.text,
              ) ??
              12,
          desiredCommission: double.tryParse(
                _commissionController.text,
              ) ??
              300,
          fixedCostPerTrip: 0,
          fuelType: _selectedFuelType,
          notificationsEnabled: _notificationsEnabled,
        );

        await ref
            .read(userParametersProvider.notifier)
            .saveParameters(newParams);
      }
    } catch (e) {
      debugPrint('No se pudo cargar configuración remota: $e');
    }
  }

  Future<void> _updateFuelPrice() async {
    if (_isManualFuelPrice) {
      if (_fuelPriceController.text.isEmpty) {
        _fuelPriceController.text = '0';
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingFuelPrice = true;
        _fuelPriceController.text = '';
      });
    }

    try {
      final price = await FuelPriceSessionService.getPriceFor(
        _selectedFuelType,
      );

      if (mounted) {
        setState(() {
          _fuelPriceController.text = price.toStringAsFixed(0);
        });
      }
    } catch (e) {
      debugPrint('Error obteniendo precio desde sesión: $e');

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

    if (normalized.contains('gas_lp') ||
        normalized.contains('gas-lp') ||
        normalized.contains('gas lp')) {
      return 'gas_lp';
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
    _fuelPriceController.dispose();
    _maintenanceCostController.dispose();
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
        vehicleEfficiency: double.parse(_efficiencyController.text),
        desiredCommission: double.parse(_commissionController.text),
        fixedCostPerTrip: 0,
        fuelType: _selectedFuelType,
        notificationsEnabled: _notificationsEnabled,
      );

      await ref
          .read(userParametersProvider.notifier)
          .saveParameters(newParams);

      await SettingsApi().saveMySettings(
        fuelType: _selectedFuelType,
        fuelPrice: double.parse(_fuelPriceController.text),
        kmPerLiter: double.parse(_efficiencyController.text),
        minimumProfitPerKm: double.parse(_commissionController.text),
        serviceType: _selectedServiceType,
        platform: _selectedPlatform,
        maxPickupDistance: double.parse(_maxPickupController.text),
        maxTripDistance: double.parse(_maxTripController.text),
        vehicleType: _selectedVehicleType,
        maintenanceCostPerKm: double.parse(
          _maintenanceCostController.text,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuración guardada correctamente'),
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error guardando configuración: $e'),
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
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Configuración DriverAI'),
        centerTitle: true,
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
            _headerCard(),
            const SizedBox(height: 16),
            _serviceCard(),
            const SizedBox(height: 16),
            _vehicleCard(),
            const SizedBox(height: 16),
            _fuelCard(),
            const SizedBox(height: 16),
            _profitabilityCard(),
            const SizedBox(height: 16),
            _limitsCard(),
            const SizedBox(height: 16),
            _automationCard(),
            const SizedBox(height: 24),
            _saveButton(),
          ],
        ),
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DriverAI',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Configura cómo DriverAI analizará cada viaje antes de aceptarlo.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _serviceCard() {
    return _sectionCard(
      title: 'Perfil de trabajo',
      icon: Icons.work_outline,
      child: Column(
        children: [
          _segmentedSelector(
            firstLabel: 'DELIVERY',
            secondLabel: 'DRIVER',
            firstSelected: _selectedServiceType == 'Delivery',
            onFirstTap: () {
              setState(() {
                _selectedServiceType = 'Delivery';
              });
            },
            onSecondTap: () {
              setState(() {
                _selectedServiceType = 'Driver';
              });
            },
          ),
          const SizedBox(height: 12),
          _segmentedSelector(
            firstLabel: 'UBER',
            secondLabel: 'DIDI',
            firstSelected: _selectedPlatform == 'Uber',
            onFirstTap: () {
              setState(() {
                _selectedPlatform = 'Uber';
              });
            },
            onSecondTap: () {
              setState(() {
                _selectedPlatform = 'Didi';
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _vehicleCard() {
    return _sectionCard(
      title: 'Vehículo y mantenimiento',
      icon: Icons.directions_car_filled_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedVehicleType,
            decoration: const InputDecoration(
              labelText: 'Tipo de vehículo',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'motorcycle',
                child: Text('Motocicleta'),
              ),
              DropdownMenuItem(
                value: 'sedan',
                child: Text('Sedán económico'),
              ),
              DropdownMenuItem(
                value: 'suv',
                child: Text('SUV / 4x4'),
              ),
              DropdownMenuItem(
                value: 'electric_vehicle',
                child: Text('Vehículo eléctrico'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                _selectedVehicleType = value;
                _maintenanceCostController.text =
                    _maintenanceByVehicleType[value]!
                        .toStringAsFixed(0);
              });
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _maintenanceCostController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Fondo mantenimiento sugerido',
              prefixText: '₡ ',
              suffixText: '/ km',
              border: OutlineInputBorder(),
              helperText:
                  'Reserva para aceite, llantas, frenos y reparaciones.',
            ),
            validator: _validatePositive,
          ),
        ],
      ),
    );
  }

  Widget _fuelCard() {
    return _sectionCard(
      title: 'Combustible',
      icon: Icons.local_gas_station_outlined,
      child: Column(
        children: [
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
              if (value == null) return;

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
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _fuelPriceController,
            readOnly: !_isManualFuelPrice,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: _isManualFuelPrice
                  ? 'Precio combustible manual'
                  : _isLoadingFuelPrice
                      ? 'Cargando precio RECOPE...'
                      : 'Precio combustible RECOPE',
              prefixText: '₡ ',
              border: const OutlineInputBorder(),
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
        ],
      ),
    );
  }

  Widget _profitabilityCard() {
    return _sectionCard(
      title: 'Reglas de rentabilidad',
      icon: Icons.trending_up,
      child: Column(
        children: [
          TextFormField(
            controller: _commissionController,
            keyboardType: TextInputType.number,
            onChanged: (_) {
              setState(() {});
            },
            decoration: const InputDecoration(
              labelText: 'Ganancia mínima por km',
              prefixText: '₡ ',
              suffixText: '/ km',
              border: OutlineInputBorder(),
            ),
            validator: _validatePositive,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.orange.withOpacity(0.35),
              ),
            ),
            child: Text(
              'Aceptable automático: ₡${_acceptableProfit.toStringAsFixed(0)} / km',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.deepOrange,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Fórmula: (Pago total - fondo mantenimiento) / kilómetros totales.',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _limitsCard() {
    return _sectionCard(
      title: 'Límites del viaje',
      icon: Icons.route_outlined,
      child: Column(
        children: [
          TextFormField(
            controller: _maxPickupController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Distancia máxima de recogida',
              suffixText: 'km',
              border: OutlineInputBorder(),
            ),
            validator: _validatePositive,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _maxTripController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Distancia máxima del viaje',
              suffixText: 'km',
              border: OutlineInputBorder(),
            ),
            validator: _validatePositive,
          ),
        ],
      ),
    );
  }

  Widget _automationCard() {
    return _sectionCard(
      title: 'Automatización',
      icon: Icons.notifications_active_outlined,
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Mostrar overlay automáticamente'),
        subtitle: const Text(
          'Al desactivar, no se mostrará el análisis automático.',
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
    );
  }

  Widget _saveButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _save,
        icon: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save),
        label: Text(
          _isSaving ? 'Guardando...' : 'Guardar configuración',
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.black87),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _segmentedSelector({
    required String firstLabel,
    required String secondLabel,
    required bool firstSelected,
    required VoidCallback onFirstTap,
    required VoidCallback onSecondTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _segmentButton(
              label: firstLabel,
              selected: firstSelected,
              onTap: onFirstTap,
            ),
          ),
          Expanded(
            child: _segmentButton(
              label: secondLabel,
              selected: !firstSelected,
              onTap: onSecondTap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _segmentButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: selected ? Colors.black87 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black54,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}