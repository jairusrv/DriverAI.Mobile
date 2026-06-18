import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';


class MinimizeService {
  static const MethodChannel _channel = MethodChannel('com.driverai.minimize');

  /// Envía la app al segundo plano (Android) o cierra la app en iOS (no hay minimización estándar).
  static Future<void> minimizeApp() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _channel.invokeMethod('minimize');
      } else {
        // En iOS, el usuario debe presionar el botón de inicio; no hay API para minimizar.
        // Aquí podrías mostrar un diálogo informativo.
        throw UnimplementedError('Minimización no soportada en iOS');
      }
    } catch (e) {
      debugPrint('Error al minimizar: $e');
    }
  }
}