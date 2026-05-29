import 'package:flutter/services.dart';

class NativeNotificationService {
  static const MethodChannel _channel =
      MethodChannel('driverai/notifications');

  static Future<void> openNotificationSettings() async {
    await _channel.invokeMethod(
      'openNotificationSettings',
    );
  }

  static Future<Map<String, dynamic>?>
      getLastNotification() async {
    final result =
        await _channel.invokeMethod<Map>(
      'getLastNotification',
    );

    if (result == null) return null;

    return Map<String, dynamic>.from(result);
  }
}