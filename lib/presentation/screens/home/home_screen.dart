import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../services/ride_notification_listener.dart';
import '../../../services/recope_service.dart';
import '../../../services/overlay_service.dart';
import '../../../domain/calculators/profitability_calculator.dart';
import '../../../domain/entities/user_parameters.dart';
import '../../../data/datasources/remote/api_client.dart';
import '../../../data/datasources/remote/recope_api.dart';
import '../../providers/user_preferences_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/auth_provider.dart';
import '../configuration/user_config_screen.dart';

final recopeApiProvider = Provider((ref) => RecopeApi(ref.read(apiClientProvider).dio));
final recopeServiceProvider = Provider((ref) => RecopeService(ref.read(recopeApiProvider)));
final rideNotificationListenerProvider = Provider((ref) => RideNotificationListener());
final profitabilityCalculatorProvider = Provider((ref) => ProfitabilityCalculator());

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _hasCheckedAccess = false;
  bool _hasAccess = true; // Por defecto asumimos acceso (si falla, permitimos)
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAccessAndSetup();
  }

  Future<void> _checkAccessAndSetup() async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      if (token == null) {
        if (mounted) context.goNamed('login');
        return;
      }

      final phoneNumber = await storage.read(key: 'phone_number');
      if (phoneNumber == null || phoneNumber.isEmpty) {
        // Si no hay teléfono, igual dejamos pasar (puede ser un error)
        setState(() {
          _hasCheckedAccess = true;
          _hasAccess = true;
        });
        _setupNotificationListener();
        return;
      }

      // Intentar obtener estado de suscripción, pero si falla, igual permitir acceso
      try {
        final api = ref.read(subscriptionApiProvider);
        final response = await api.getSubscriptionStatus(phoneNumber);
        final hasAccess = response.success && response.data != null && response.data!.hasAccess;
        setState(() {
          _hasCheckedAccess = true;
          _hasAccess = hasAccess;
          _errorMessage = null;
        });
      } catch (e) {
        // Si el endpoint falla, igual permitimos acceso (modo desarrollo)
        setState(() {
          _hasCheckedAccess = true;
          _hasAccess = true;
          _errorMessage = 'No se pudo verificar suscripción, pero puedes continuar.';
        });
      }

      if (_hasAccess && mounted) {
        _setupNotificationListener();
      }
    } catch (e) {
      setState(() {
        _hasCheckedAccess = true;
        _hasAccess = true;
        _errorMessage = 'Error inesperado, pero puedes continuar.';
      });
      _setupNotificationListener();
    }
  }

  void _setupNotificationListener() {
    final listener = ref.read(rideNotificationListenerProvider);
    listener.onRideDetected = (rideData) async {
      final userParams = ref.read(userParametersProvider);
      if (!userParams.notificationsEnabled) return;
      final fuelPriceResult = await ref.read(recopeServiceProvider).getCurrentFuelPrice();
      fuelPriceResult.fold(
        (failure) => debugPrint('Error al obtener precio: ${failure.message}'),
        (fuelPrice) {
          final calculator = ref.read(profitabilityCalculatorProvider);
          final result = calculator.calculate(
            ride: rideData,
            fuelPricePerLiter: fuelPrice,
            params: userParams,
          );
          OverlayService.showProfitabilityOverlay(result);
        },
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasCheckedAccess) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_hasAccess) {
      return Scaffold(
        appBar: AppBar(title: const Text('DriverAI')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 80, color: Colors.red),
              const SizedBox(height: 20),
              const Text('Tu período de prueba ha expirado o no tienes una suscripción activa.'),
              const SizedBox(height: 10),
              const Text('Activa tu suscripción para seguir usando DriverAI.'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.goNamed('subscription'),
                child: const Text('Ver suscripciones'),
              ),
            ],
          ),
        ),
      );
    }

    // Pantalla principal (acceso concedido)
    return Scaffold(
      appBar: AppBar(
        title: const Text('DriverAI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserConfigScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_errorMessage != null)
            Container(
              color: Colors.orange,
              padding: const EdgeInsets.all(8),
              child: Text(_errorMessage!, style: const TextStyle(color: Colors.white)),
            ),
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_active, size: 80, color: Colors.blue),
                  SizedBox(height: 20),
                  Text('Esperando notificaciones de Uber/Didi...'),
                  SizedBox(height: 10),
                  Text('Cuando llegue un viaje, aparecerá un overlay con el análisis.'),
                  SizedBox(height: 20),
                  Text('Configura tu vehículo desde el ícono de ajustes.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}