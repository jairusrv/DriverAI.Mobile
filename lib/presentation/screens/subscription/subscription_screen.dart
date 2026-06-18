import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../data/models/subscription_info.dart';
import '../../providers/subscription_provider.dart';

final phoneNumberProvider = FutureProvider<String?>((ref) async {
  const storage = FlutterSecureStorage();
  return await storage.read(key: 'phone_number');
});

final subscriptionStatusProvider =
    FutureProvider<SubscriptionInfo?>((ref) async {
  final phoneNumber = await ref.watch(phoneNumberProvider.future);
  if (phoneNumber == null) return null;
  final api = ref.read(subscriptionApiProvider);
  final response = await api.getSubscriptionStatus(phoneNumber);
  if (response.success && response.data != null) {
    return response.data;
  }
  return null;
});

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  int _selectedMonths = 1;
  bool _isActivating = false;

  Future<void> _activateSubscription() async {
    setState(() => _isActivating = true);
    const storage = FlutterSecureStorage();
    final phoneNumber = await storage.read(key: 'phone_number');
    if (phoneNumber != null) {
      final api = ref.read(subscriptionApiProvider);
      final response =
          await api.activateSubscription(phoneNumber, _selectedMonths);
      if (response.success) {
        ref.invalidate(subscriptionStatusProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Suscripción activada correctamente')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message)),
          );
        }
      }
    }
    if (mounted) setState(() => _isActivating = false);
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionAsync = ref.watch(subscriptionStatusProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Suscripción')),
      body: subscriptionAsync.when(
        data: (info) {
          if (info == null) {
            return const Center(child: Text('No se pudo obtener información'));
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          info.hasAccess
                              ? '✅ Acceso Activo'
                              : '⛔ Acceso Bloqueado',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: info.hasAccess ? Colors.green : Colors.red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (info.isInTrial)
                          Text(
                              'Período de prueba: ${info.remainingTrialDays} días restantes'),
                        if (info.isSubscriptionActive &&
                            info.subscriptionExpiryDate != null)
                          Text(
                              'Suscripción activa hasta: ${_formatDate(info.subscriptionExpiryDate)}'),
                        if (!info.hasAccess && !info.isInTrial)
                          const Text(
                              'Tu período de prueba ha expirado. Activa una suscripción para continuar.'),
                        const SizedBox(height: 8),
                        if (info.message.isNotEmpty) Text(info.message),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Activar suscripción',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: _selectedMonths,
                  items: [1, 3, 6, 12].map((months) {
                    return DropdownMenuItem(
                        value: months, child: Text('$months mes(es)'));
                  }).toList(),
                  onChanged: (value) =>
                      setState(() => _selectedMonths = value!),
                  decoration:
                      const InputDecoration(labelText: 'Selecciona duración'),
                ),
                const SizedBox(height: 16),
                if (_isActivating)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton.icon(
                    onPressed: _activateSubscription,
                    icon: const Icon(Icons.payment),
                    label: Text('Pagar y activar ($_selectedMonths mes(es))'),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }
}
