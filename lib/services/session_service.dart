import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionService {
  static const FlutterSecureStorage _storage =
      FlutterSecureStorage();

  static Future<void> saveSession({
    required String token,
    required int userId,
    required String email,
    required String role,
  }) async {
    await _storage.write(
      key: 'token',
      value: token,
    );

    await _storage.write(
      key: 'userId',
      value: userId.toString(),
    );

    await _storage.write(
      key: 'email',
      value: email,
    );

    await _storage.write(
      key: 'role',
      value: role,
    );
  }

  static Future<String?> getToken() async {
    return await _storage.read(
      key: 'token',
    );
  }

  static Future<int?> getUserId() async {
    final value = await _storage.read(
      key: 'userId',
    );

    if (value == null) return null;

    return int.tryParse(value);
  }

  static Future<void> clear() async {
    await _storage.deleteAll();
  }
}