import 'package:flutter/services.dart';

class NativeCaptureService {
  static const MethodChannel _channel = MethodChannel(
    'driverai/capture',
  );

  static Future<bool> startCapture() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'startCapture',
      );

      return result ?? false;
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'No se pudo iniciar la captura');
    }
  }

  static Future<bool> stopCapture() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'stopCapture',
      );

      return result ?? false;
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'No se pudo detener la captura');
    }
  }
}