import 'package:flutter/services.dart';

class NativePermissionService {
  static const MethodChannel _channel =
      MethodChannel('driverai/notifications');

  static Future<void> openNotificationSettings() async {
    await _channel.invokeMethod('openNotificationSettings');
  }

  static Future<bool> isNotificationListenerEnabled() async {
    final result = await _channel.invokeMethod<bool>(
      'isNotificationListenerEnabled',
    );

    return result ?? false;
  }

  static Future<void> openOverlaySettings() async {
    await _channel.invokeMethod('openOverlaySettings');
  }

  static Future<bool> canDrawOverlays() async {
    final result = await _channel.invokeMethod<bool>(
      'canDrawOverlays',
    );

    return result ?? false;
  }

  static Future<void> openBatteryOptimizationSettings() async {
    await _channel.invokeMethod(
      'openBatteryOptimizationSettings',
    );
  }

  static Future<bool> isBatteryOptimizationIgnored() async {
    final result = await _channel.invokeMethod<bool>(
      'isBatteryOptimizationIgnored',
    );

    return result ?? false;
  }

  static Future<bool> areRequiredPermissionsReady() async {
    final notificationEnabled =
        await isNotificationListenerEnabled();

    final overlayEnabled = await canDrawOverlays();

    final batteryIgnored =
        await isBatteryOptimizationIgnored();

    return notificationEnabled &&
        overlayEnabled &&
        batteryIgnored;
  }
}