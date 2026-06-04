import 'package:flutter/material.dart';

import '../../../services/native_permission_service.dart';

class PermissionsSetupScreen extends StatefulWidget {
  const PermissionsSetupScreen({super.key});

  @override
  State<PermissionsSetupScreen> createState() => _PermissionsSetupScreenState();
}

class _PermissionsSetupScreenState extends State<PermissionsSetupScreen>
    with WidgetsBindingObserver {
  bool _isLoading = true;

  bool _notificationEnabled = false;
  bool _overlayEnabled = false;
  bool _batteryIgnored = false;
  bool _accessibilityEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _isLoading = true;
    });

    final notificationEnabled =
        await NativePermissionService.isNotificationListenerEnabled();

    final overlayEnabled = await NativePermissionService.canDrawOverlays();

    final batteryIgnored =
        await NativePermissionService.isBatteryOptimizationIgnored();

    final accessibilityEnabled =
        await NativePermissionService.isAccessibilityEnabled();

    if (!mounted) return;

    setState(() {
      _notificationEnabled = notificationEnabled;
      _overlayEnabled = overlayEnabled;
      _batteryIgnored = batteryIgnored;
      _isLoading = false;
    });
  }

  bool get _allReady =>
      _notificationEnabled &&
      _overlayEnabled &&
      _batteryIgnored &&
      _accessibilityEnabled;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Preparar DriverAI'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                _headerCard(),
                const SizedBox(height: 16),
                _permissionTile(
                  title: 'Acceso a notificaciones',
                  description:
                      'Permite que DriverAI lea ofertas de Uber y DiDi para analizarlas.',
                  isReady: _notificationEnabled,
                  buttonText: 'Activar',
                  onTap: () async {
                    await NativePermissionService.openNotificationSettings();
                  },
                ),
                const SizedBox(height: 12),
                _permissionTile(
                  title: 'Accesibilidad',
                  description:
                      'Permite que DriverAI lea la oferta visible en Uber o DiDi para calcular la rentabilidad.',
                  isReady: _accessibilityEnabled,
                  buttonText: 'Activar',
                  onTap: () async {
                    await NativePermissionService.openAccessibilitySettings();
                  },
                ),
                const SizedBox(height: 12),
                _permissionTile(
                  title: 'Mostrar encima de otras apps',
                  description:
                      'Permite mostrar el overlay de rentabilidad sobre Uber o DiDi.',
                  isReady: _overlayEnabled,
                  buttonText: 'Activar',
                  onTap: () async {
                    await NativePermissionService.openOverlaySettings();
                  },
                ),
                const SizedBox(height: 12),
                _permissionTile(
                  title: 'Batería sin restricciones',
                  description:
                      'Evita que Android cierre DriverAI mientras esperas viajes.',
                  isReady: _batteryIgnored,
                  buttonText: 'Activar',
                  onTap: () async {
                    await NativePermissionService
                        .openBatteryOptimizationSettings();
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _allReady
                      ? () {
                          Navigator.pop(context, true);
                        }
                      : null,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Continuar'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _checkPermissions,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Verificar permisos'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _headerCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DriverAI necesita estos permisos',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Solo debes configurarlos una vez. Después DriverAI podrá analizar las solicitudes automáticamente.',
              style: TextStyle(
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  _allReady ? Icons.check_circle : Icons.warning_amber_rounded,
                  color: _allReady ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _allReady
                        ? 'DriverAI está listo para funcionar.'
                        : 'Faltan permisos por activar.',
                    style: TextStyle(
                      color: _allReady
                          ? Colors.green.shade700
                          : Colors.orange.shade800,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _permissionTile({
    required String title,
    required String description,
    required bool isReady,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              isReady ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isReady ? Colors.green : Colors.orange,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (!isReady)
              ElevatedButton(
                onPressed: onTap,
                child: Text(buttonText),
              )
            else
              const Text(
                'Listo',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w900,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
