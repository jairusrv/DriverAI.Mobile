import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import '../data/datasources/remote/api_client.dart';

class ErrorLogService {
  static final Dio _dio = ApiClient().dio;

  static Future<void> logError({
    int? userId,
    required String source,
    required String message,
    String? stackTrace,
    String? deviceInfo,
  }) async {
    try {
      final resolvedDeviceInfo =
          deviceInfo ?? await _getDeviceInfo();

      await _dio.post(
        ApiConstants.errors,
        data: {
          'userId': userId,
          'source': source,
          'message': message,
          'stackTrace': stackTrace,
          'deviceInfo': resolvedDeviceInfo,
        },
      );
    } catch (_) {
      // Nunca dejamos que el logger rompa la app.
    }
  }

  static Future<String> _getDeviceInfo() async {
    final plugin = DeviceInfoPlugin();

    try {
      if (Platform.isAndroid) {
        final android = await plugin.androidInfo;

        return 'Android ${android.version.release} | '
            '${android.manufacturer} ${android.model} | '
            'SDK ${android.version.sdkInt}';
      }

      if (Platform.isIOS) {
        final ios = await plugin.iosInfo;

        return 'iOS ${ios.systemVersion} | '
            '${ios.name} ${ios.model}';
      }

      return Platform.operatingSystem;
    } catch (_) {
      return 'unknown';
    }
  }
}