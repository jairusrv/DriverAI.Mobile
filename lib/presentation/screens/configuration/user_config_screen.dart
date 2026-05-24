import 'package:driverai_mobile/presentation/providers/user_preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/user_parameters.dart';
import '../../providers/subscription_provider.dart';

class UserConfigScreen extends ConsumerStatefulWidget {
  const UserConfigScreen({super.key});

  @override
  ConsumerState<UserConfigScreen> createState() => _UserConfigScreenState();
}

class _UserConfigScreenState extends ConsumerState<UserConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _efficiencyController;
  late TextEditingController _commissionController;
  late TextEditingController _fixedCostController;
  String _selectedFuelType = 'super';
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    final params = ref.read(userParametersProvider);
    _efficiencyController = TextEditingController(text: params.vehicleEfficiency.toString());
    _commissionController = TextEditingController(text: params.desiredCommission.toString());
    _fixedCostController = TextEditingController(text: params.fixedCostPerTrip.toString());
    _selectedFuelType = params.fuelType;
    _notificationsEnabled = params.notificationsEnabled;
  }

  @override
  void dispose() {
    _efficiencyController.dispose();
    _commissionController.dispose();
    _fixedCostController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final newParams = UserParameters(
        vehicleEfficiency: double.parse(_efficiencyController.text),
        desiredCommission: double.parse(_commissionController.text),
        fixedCostPerTrip: double.parse(_fixedCostController.text),
        fuelType: _selectedFuelType,
        notificationsEnabled: _notificationsEnabled,
      );
      await ref.read(userParametersProvider.notifier).saveParameters(newParams);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuración guardada correctamente')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final params = ref.watch(userParametersProvider);
    // Sincronizar controladores si los parámetros cambian externamente
    _efficiencyController.text = params.vehicleEfficiency.toString();
    _commissionController.text = params.desiredCommission.toString();
    _fixedCostController.text = params.fixedCostPerTrip.toString();
    _selectedFuelType = params.fuelType;
    _notificationsEnabled = params.notificationsEnabled;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración del Vehículo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Rendimiento del vehículo', style: TextStyle(fontWeight: FontWeight.bold)),
            TextFormField(
              controller: _efficiencyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Kilómetros por litro (km/L)',
                suffixText: 'km/L',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Requerido';
                final v = double.tryParse(value);
                if (v == null || v <= 0) return 'Debe ser un número positivo';
                return null;
              },
            ),
            const SizedBox(height: 16),
            const Text('Preferencias de rentabilidad', style: TextStyle(fontWeight: FontWeight.bold)),
            TextFormField(
              controller: _commissionController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Comisión deseada (%)',
                suffixText: '%',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Requerido';
                final v = double.tryParse(value);
                if (v == null || v < 0 || v > 100) return 'Valor entre 0 y 100';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _fixedCostController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Costo fijo por viaje (₡)',
                prefixText: '₡ ',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Requerido';
                final v = double.tryParse(value);
                if (v == null || v < 0) return 'Debe ser un número no negativo';
                return null;
              },
            ),
            const SizedBox(height: 16),
            const Text('Tipo de combustible', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButtonFormField<String>(
              value: _selectedFuelType,
              items: const [
                DropdownMenuItem(value: 'super', child: Text('Súper')),
                DropdownMenuItem(value: 'diesel', child: Text('Diésel')),
                DropdownMenuItem(value: 'regular', child: Text('Regular')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedFuelType = value);
                  ref.read(userParametersProvider.notifier).updateFuelType(value);
                }
              },
              decoration: const InputDecoration(labelText: 'Combustible'),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Mostrar overlay automáticamente al recibir notificación'),
              subtitle: const Text('Al desactivar, no se mostrará el análisis automático'),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
                ref.read(userParametersProvider.notifier).updateNotificationsEnabled(value);
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Guardar configuración'),
            ),
          ],
        ),
      ),
    );
  }
}