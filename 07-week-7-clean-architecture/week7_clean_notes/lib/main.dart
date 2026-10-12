// Entry point aplikasi Week 7 — Clean Architecture (feature-first).
//
// Perubahan dari Minggu 5:
//   - `main.dart` hanya bootstrap: ProviderContainer + MaterialApp.router.
//   - Tidak ada akses SharedPreferences langsung di sini; waktu "terakhir
//     dibuka" dicatat lewat repository settings yang disuntikkan container.
//   - Rute terpusat di `routes.dart`, tema mengikuti `darkModeProvider`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/settings/presentation/providers/settings_providers.dart';
import 'routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Composition root: satu container dipakai seluruh aplikasi.
  final container = ProviderContainer();
  try {
    // Catat waktu terakhir dibuka (side effect bootstrap, tanpa logika bisnis
    // sehingga cukup repository — tidak perlu use case).
    await container.read(settingsRepositoryProvider).markOpenedNow();
  } catch (_) {
    // Diabaikan: preferensi bersifat opsional dan tidak boleh menggagalkan start.
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const CleanNotesApp(),
    ),
  );
}

class CleanNotesApp extends ConsumerWidget {
  const CleanNotesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = ref.watch(darkModeProvider);
    return MaterialApp.router(
      title: 'Week 7 - Clean Notes',
      debugShowCheckedModeBanner: false,
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
