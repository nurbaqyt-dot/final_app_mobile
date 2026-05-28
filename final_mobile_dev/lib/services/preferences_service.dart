import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  const PreferencesService(this._preferences);

  final SharedPreferences _preferences;

  bool getBool(String key, {bool fallback = false}) {
    return _preferences.getBool(key) ?? fallback;
  }

  Future<void> setBool(String key, bool value) async {
    await _preferences.setBool(key, value);
  }

  Map<String, dynamic>? getMap(String key) {
    final raw = _preferences.getString(key);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  Future<void> setMap(String key, Map<String, dynamic> value) async {
    await _preferences.setString(key, jsonEncode(value));
  }

  List<Map<String, dynamic>> getList(String key) {
    final raw = _preferences.getString(key);
    if (raw == null || raw.isEmpty) {
      return <Map<String, dynamic>>[];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) {
      return <Map<String, dynamic>>[];
    }
    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> setList(String key, List<Map<String, dynamic>> value) async {
    await _preferences.setString(key, jsonEncode(value));
  }

  Future<void> remove(String key) async {
    await _preferences.remove(key);
  }
}
