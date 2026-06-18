// presentation/screens/configuration/profitability_config_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/common/custom_button.dart';

final profitabilityConfigProvider =
    StateNotifierProvider<ProfitabilityConfigNotifier, Map<String, double>>(
        (ref) {
  return ProfitabilityConfigNotifier();
});

class ProfitabilityConfigNotifier extends StateNotifier<Map<String, double>> {
  ProfitabilityConfigNotifier()
      : super({'vehicleEfficiency': 12.0, 'desiredCommission': 30.0});

  void updateVehicleEfficiency(double value) {
    state = {...state, 'vehicleEfficiency': value};
    // Guardar en local storage
  }

  void updateDesiredCommission(double value) {
    state = {...state, 'desiredCommission': value};
    // Guardar en local storage
  }
}

class ProfitabilityConfigScreen extends ConsumerWidget {
  const ProfitabilityConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(profitabilityConfigProvider);
    final notifier = ref.read(profitabilityConfigProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración de Rentabilidad')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildSlider(
              label: 'Rendimiento del vehículo (km/litro)',
              value: config['vehicleEfficiency']!,
              min: 5,
              max: 25,
              onChanged: notifier.updateVehicleEfficiency,
            ),
            const SizedBox(height: 32),
            _buildSlider(
              label: 'Comisión deseada (%)',
              value: config['desiredCommission']!,
              min: 10,
              max: 60,
              onChanged: notifier.updateDesiredCommission,
            ),
            const Spacer(),
            CustomButton(
              text: 'Guardar',
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Configuración guardada')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.toStringAsFixed(1)}'),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          label: value.toStringAsFixed(1),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
