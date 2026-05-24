// data/datasources/local/shared_preferences_datasource.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SharedPreferencesDataSource {
  static const String _userParamsKey = 'user_parameters';

  Future<void> saveUserParameters(Map<String, dynamic> params) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(params);
    await prefs.setString(_userParamsKey, jsonString);
  }

  Future<Map<String, dynamic>?> getUserParameters() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_userParamsKey);
    if (jsonString != null) {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    }
    return null;
  }
}