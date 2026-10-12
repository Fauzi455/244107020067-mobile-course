// IMPLEMENTASI kontrak SettingsRepository.
//
// Menerjemahkan exception platform (SharedPreferences) menjadi `Failure`,
// dan mengubah tipe primitif (`bool`, `String` ISO) menjadi entity murni
// `AppSettings`.

import '../../../../core/failures.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._local);

  final SettingsLocalDataSource _local;

  @override
  Future<({AppSettings settings, Failure? failure})> load() async {
    try {
      final dark = await _local.readDarkMode();
      final rawLastOpened = await _local.readLastOpened();
      return (
        settings: AppSettings(
          darkMode: dark,
          lastOpened: rawLastOpened == null
              ? null
              : DateTime.tryParse(rawLastOpened)?.toLocal(),
        ),
        failure: null,
      );
    } catch (e) {
      return (
        settings: const AppSettings(),
        failure: LocalFailure('Gagal membaca preferensi: $e'),
      );
    }
  }

  @override
  Future<Failure?> saveDarkMode(bool value) async {
    try {
      await _local.writeDarkMode(value);
      return null;
    } catch (e) {
      return LocalFailure('Gagal menyimpan tema: $e');
    }
  }

  @override
  Future<Failure?> markOpenedNow() async {
    try {
      await _local.writeLastOpened(DateTime.now());
      return null;
    } catch (e) {
      return LocalFailure('Gagal mencatat waktu buka: $e');
    }
  }
}
