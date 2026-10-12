// KONTRAK repository preferensi — di `domain`, implementasi di `data`.
//
// Preferensi hanya berisi nilai primitif kecil (tema, waktu terakhir dibuka).
// Daftar catatan TIDAK disimpan di sini — koleksi data selalu masuk SQLite.

import '../../../../core/failures.dart';
import '../entities/app_settings.dart';

abstract class SettingsRepository {
  /// Baca seluruh preferensi sekaligus.
  Future<({AppSettings settings, Failure? failure})> load();

  /// Simpan pilihan tema (langsung berlaku, tanpa menunggu restart).
  Future<Failure?> saveDarkMode(bool value);

  /// Catat waktu aplikasi dibuka (dipanggil sekali saat bootstrap).
  Future<Failure?> markOpenedNow();
}
