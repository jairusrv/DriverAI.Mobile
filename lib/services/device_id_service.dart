import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceIdService {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  Future<String> getDeviceId() async {
    try {
      final androidInfo = await _deviceInfo.androidInfo;
      return androidInfo.id; // ID único del dispositivo
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      String? deviceId = prefs.getString('device_uuid');
      if (deviceId == null) {
        deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
        await prefs.setString('device_uuid', deviceId);
      }
      return deviceId;
    }
  }
}