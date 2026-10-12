// Data source preferensi berbasis SharedPreferences.
//
// Seluruh akses key-value terpusat di sini, BUKAN tersebar di widget. Ini
// penting agar:
//   - hasil `SharedPreferences.getInstance()` ter-cache,
//   - mudah diuji (bisa di-override lewat provider),
//   - kunci tidak duplikat/typo di banyak tempat.

import 'package:shared_preferences/shared_preferences.dart';

class SettingsLocalDataSource {
  static const String darkModeKey = 'dark_mode';
  static const String lastOpenedKey = 'last_opened_at';

  Future<bool> readDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(darkModeKey) ?? false;
  }

  Future<String?> readLastOpened() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(lastOpenedKey);
  }

  Future<void> writeDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(darkModeKey, value);
  }

  Future<void> writeLastOpened(DateTime value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(lastOpenedKey, value.toIso8601String());
  }
}
