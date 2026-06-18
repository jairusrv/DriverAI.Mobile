import 'package:flutter/services.dart';

class NativeNotificationService {
  static const MethodChannel _channel =
      MethodChannel('driverai/notifications');

  static Future<void> openNotificationSettings() async {
    await _channel.invokeMethod(
      'openNotificationSettings',
    );
  }

}