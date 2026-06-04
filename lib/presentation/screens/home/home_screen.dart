import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../services/ride_notification_listener.dart';
import '../../../services/recope_service.dart';
import '../../../services/overlay_service.dart';
import '../../../services/minimize_service.dart';
import '../../../services/session_manager.dart';
import '../../../services/native_notification_service.dart';

import '../../../domain/calculators/profitability_calculator.dart';

import '../../../data/datasources/remote/api_client.dart';
import '../../../data/datasources/remote/recope_api.dart';
import '../../../data/datasources/remote/history_api.dart';

import '../../providers/user_preferences_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/auth_provider.dart';

import '../history/history_screen.dart';
import '../configuration/user_config_screen.dart';
import '../stats/stats_screen.dart';
import '../subscription/subscription_status_screen.dart';
import '../admin/admin_payments_screen.dart';
import '../payment/report_sinpe_payment_screen.dart';
import '../permissions/permissions_setup_screen.dart';

final recopeApiProvider = Provider(
  (ref) => RecopeApi(
    ref.read(apiClientProvider).dio,
  ),
);

final recopeServiceProvider = Provider(
  (ref) => RecopeService(
    ref.read(recopeApiProvider),
  ),
);

final rideNotificationListenerProvider =
    Provider((ref) => RideNotificationListener());

final profitabilityCalculatorProvider =
    Provider((ref) => ProfitabilityCalculator());

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _hasCheckedAccess = false;
  bool _hasAccess = true;
  bool _isAdmin = false;
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
        if (mounted) {
          context.goNamed('login');
        }
        return;
      }

      final role = await storage.read(key: 'role');

      if (mounted) {
        setState(() {
          _isAdmin = role?.toLowerCase() == 'admin';
        });
      }

      await SessionManager.initialize();

      final phoneNumber = await storage.read(key: 'phone_number');

      if (phoneNumber == null || phoneNumber.isEmpty) {
        if (mounted) {
          setState(() {
            _hasCheckedAccess = true;
            _hasAccess = true;
          });
        }

        _setupNotificationListener();
        return;
      }

      try {
        final api = ref.read(subscriptionApiProvider);

        final response = await api.getSubscriptionStatus(phoneNumber);

        final hasAccess = response.success &&
            response.data != null &&
            response.data!.hasAccess;

        if (mounted) {
          setState(() {
            _hasCheckedAccess = true;
            _hasAccess = hasAccess;
            _errorMessage = null;
          });
        }

        if (hasAccess && mounted) {
          _setupNotificationListener();
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _hasCheckedAccess = true;
            _hasAccess = true;
            _errorMessage =
                'No se pudo verificar suscripción, pero puedes continuar.';
          });
        }

        _setupNotificationListener();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasCheckedAccess = true;
          _hasAccess = true;
          _errorMessage = 'Error inesperado, pero puedes continuar.';
        });
      }

      _setupNotificationListener();
    }
  }

  void _setupNotificationListener() {
    final listener = ref.read(rideNotificationListenerProvider);

    listener.onRideDetected = (rideData) async {
      if (!_hasAccess) {
        return;
      }

      final userParams = ref.read(userParametersProvider);

      if (!userParams.notificationsEnabled) {
        return;
      }

      try {
        final fuelPrice = await SessionManager.getFuelPrice(
          userParams.fuelType,
        );

        final calculator = ref.read(profitabilityCalculatorProvider);

        final result = calculator.calculate(
          ride: rideData,
          fuelPricePerLiter: fuelPrice,
          params: userParams,
          maxPickupDistance: userParams.maxPickupDistance,
          maxTripDistance: userParams.maxTripDistance,
        );

        OverlayService.showProfitabilityOverlay(
          result,
          ride: rideData,
        );

        final profitPerKm = rideData.distanceKm > 0
            ? result.netProfit / rideData.distanceKm
            : 0.0;

        try {
          await HistoryApi().saveRide(
            fare: rideData.fare,
            distanceKm: rideData.distanceKm,
            pickupDistanceKm: rideData.pickupDistanceKm,
            estimatedTimeMinutes: rideData.durationMinutes.toDouble(),
            profit: result.netProfit,
            profitPerKm: profitPerKm,
            decision: result.decision.name.toUpperCase(),
            sourceApp: rideData.provider,
          );
        } catch (e) {
          debugPrint('Error guardando historial: $e');
        }
      } catch (e) {
        debugPrint('Error procesando viaje: $e');
      }
    };
  }

  Future<void> _minimizeAndWait() async {
  final ready = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) => const PermissionsSetupScreen(),
    ),
  );

  if (ready != true) {
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'DriverAI continuará escuchando notificaciones en segundo plano',
      ),
    ),
  );

  await Future.delayed(
    const Duration(seconds: 1),
  );

  await MinimizeService.minimizeApp();
}

  Future<void> _logout() async {
    await ref.read(authNotifierProvider.notifier).logout();

    if (mounted) {
      context.goNamed('login');
    }
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const UserConfigScreen(),
      ),
    );
  }

  void _openSubscriptionStatus() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SubscriptionStatusScreen(),
      ),
    );
  }

  void _openReportSinpe() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ReportSinpePaymentScreen(),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.local_taxi,
                  color: Colors.white,
                  size: 42,
                ),
                SizedBox(height: 10),
                Text(
                  'DriverAI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          if (_hasAccess) ...[
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Estadísticas'),
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StatsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Historial'),
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HistoryScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('Probar última notificación'),
              onTap: () async {
                Navigator.pop(context);

                final data =
                    await NativeNotificationService.getLastNotification();

                if (data == null || data['text'] == null) {
                  return;
                }

                ref.read(rideNotificationListenerProvider).processNotificationText(
                      provider: data['provider'] ?? 'unknown',
                      text: data['text'],
                    );
              },
            ),
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('Simular Uber Driver'),
              onTap: () {
                Navigator.pop(context);

                ref
                    .read(rideNotificationListenerProvider)
                    .simulateUberDriverOffer();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delivery_dining),
              title: const Text('Simular Uber Delivery'),
              onTap: () {
                Navigator.pop(context);

                ref
                    .read(rideNotificationListenerProvider)
                    .simulateUberDeliveryOffer();
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_taxi),
              title: const Text('Simular DiDi'),
              onTap: () {
                Navigator.pop(context);

                ref.read(rideNotificationListenerProvider).simulateDidiOffer();
              },
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Inicio'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configuración'),
              onTap: () {
                Navigator.pop(context);
                _openSettings();
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_active),
              title: const Text('Permiso de notificaciones'),
              onTap: () async {
                Navigator.pop(context);

                await NativeNotificationService.openNotificationSettings();
              },
            ),
          ],

          ListTile(
            leading: const Icon(Icons.verified_user),
            title: const Text('Estado de suscripción'),
            onTap: () {
              Navigator.pop(context);
              _openSubscriptionStatus();
            },
          ),

          ListTile(
            leading: const Icon(Icons.mobile_friendly),
            title: const Text('Reportar pago SINPE'),
            onTap: () {
              Navigator.pop(context);
              _openReportSinpe();
            },
          ),

          if (_hasAccess)
            ListTile(
              leading: const Icon(Icons.payment),
              title: const Text('Suscripción'),
              onTap: () {
                Navigator.pop(context);
                context.goNamed('subscription');
              },
            ),

          if (_hasAccess && _isAdmin)
            ListTile(
              leading: const Icon(
                Icons.admin_panel_settings,
                color: Colors.deepPurple,
              ),
              title: const Text(
                'Admin pagos SINPE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminPaymentsScreen(),
                  ),
                );
              },
            ),

          const Divider(),

          ListTile(
            leading: const Icon(
              Icons.logout,
              color: Colors.red,
            ),
            title: const Text(
              'Cerrar sesión',
              style: TextStyle(
                color: Colors.red,
              ),
            ),
            onTap: () async {
              Navigator.pop(context);
              await _logout();
            },
          ),
        ],
      ),
    );
  }

  Widget _expiredSubscriptionBody() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_clock,
              size: 82,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            const Text(
              'Tu suscripción está vencida',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Puedes iniciar sesión para reportar tu pago SINPE o revisar el estado de tu suscripción.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.mobile_friendly),
                label: const Text('Reportar pago SINPE'),
                onPressed: _openReportSinpe,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.verified_user),
                label: const Text('Estado de suscripción'),
                onPressed: _openSubscriptionStatus,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
              onPressed: _logout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _activeSubscriptionBody() {
    return Column(
      children: [
        if (_errorMessage != null)
          Container(
            color: Colors.orange,
            padding: const EdgeInsets.all(8),
            width: double.infinity,
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.notifications_active,
                    size: 80,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Esperando notificaciones de Uber/Didi...',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Cuando llegue un viaje, aparecerá un overlay con el análisis.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: _minimizeAndWait,
                    icon: const Icon(Icons.phone_android),
                    label: const Text('Esperar viajes'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Presiona "Esperar viajes" para minimizar la app.\nSeguiremos escuchando notificaciones.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasCheckedAccess) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      drawer: _buildDrawer(),
      appBar: AppBar(
        title: const Text('DriverAI'),
        actions: [
          if (_hasAccess)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _openSettings,
            ),
        ],
      ),
      body: _hasAccess
          ? _activeSubscriptionBody()
          : _expiredSubscriptionBody(),
    );
  }
}