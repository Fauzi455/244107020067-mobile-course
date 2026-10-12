// Repository preferensi (key-value) berbasis SharedPreferences.
//
// Seluruh akses key-value terpusat di sini, BUKAN tersebar di widget.
// Ini penting agar:
//   - hasil `SharedPreferences.getInstance()` ter-cache,
//   - mudah diuji (bisa di-override lewat provider),
//   - kunci tidak duplikat/typo di banyak tempat.
//
// SharedPreferences hanya untuk nilai primitif kecil (tema, bahasa, waktu
// terakhir dibuka). Daftar catatan TIDAK disimpan di sini — koleksi data
// masuk ke SQLite.

import 'package:shared_preferences/shared_preferences.dart';

class PrefsRepository {
  static const _darkModeKey = 'dark_mode';
  static const _lastOpenedKey = 'last_opened_at';

  Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? false;
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
  }

  Future<void> markOpenedNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastOpenedKey, DateTime.now().toIso8601String());
  }

  Future<String?> getLastOpened() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastOpenedKey);
  }
}
