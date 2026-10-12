// WIRING DI fitur settings (Praktikum 5, modul Minggu 7).
//
// Inilah satu-satunya tempat objek dibuat: datasource -> repository ->
// notifier. Widget tidak pernah `SettingsRepositoryImpl()` sendiri, dan
// datasource bisa diganti fake lewat `overrideWithValue` saat test.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/failures.dart';
import '../../data/datasources/settings_local_datasource.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

/// Data layer: datasource SharedPreferences.
final settingsLocalDataSourceProvider = Provider<SettingsLocalDataSource>(
  (ref) => SettingsLocalDataSource(),
);

/// Domain layer: kontrak, bukan implementasi.
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepositoryImpl(ref.watch(settingsLocalDataSourceProvider)),
);

/// Presentation layer: state preferensi untuk UI.
class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final result = await ref.watch(settingsRepositoryProvider).load();
    final failure = result.failure;
    if (failure != null) {
      throw FailureException(failure);
    }
    return result.settings;
  }

  Future<void> toggleDarkMode() async {
    final current = state.value ?? const AppSettings();
    final next = !current.darkMode;
    final failure = await ref
        .read(settingsRepositoryProvider)
        .saveDarkMode(next);
    if (failure != null) {
      throw FailureException(failure);
    }
    state = AsyncData(current.copyWith(darkMode: next));
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
  // Matikan retry otomatis Riverpod 3 agar error langsung final & mudah diuji.
  retry: (retryCount, error) => null,
);

/// Tema aktif — dibaca `MaterialApp.router` di `main.dart`.
final darkModeProvider = Provider<bool>(
  (ref) => ref.watch(settingsProvider).value?.darkMode ?? false,
);

/// Waktu terakhir aplikasi dibuka (ditampilkan di halaman Pengaturan).
final lastOpenedProvider = Provider<DateTime?>(
  (ref) => ref.watch(settingsProvider).value?.lastOpened,
);

/// Simulasi offline yang deterministik (tidak bergantung Wi-Fi).
///
/// Ini state sesi murni UI, jadi tidak dipersistensikan. Fitur `posts`
/// membacanya untuk melewati refresh jaringan saat demo offline.
class ForceOfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

final forceOfflineProvider = NotifierProvider<ForceOfflineNotifier, bool>(
  ForceOfflineNotifier.new,
);
