// Entry point aplikasi Offline Notes.
//
// - ProviderScope membungkus seluruh widget tree (Riverpod).
// - `markOpenedNow()` mencatat waktu terakhir dibuka ke SharedPreferences.
// - Tema mengikuti preferensi `darkModeProvider` (SharedPreferences).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_router.dart';
import 'data/prefs.dart';
import 'data/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Catat waktu terakhir dibuka (jangan sampai menggagalkan startup).
  try {
    await PrefsRepository().markOpenedNow();
  } catch (_) {
    // Diabaikan: preferensi bersifat opsional.
  }
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = ref.watch(darkModeProvider).value ?? false;
    return MaterialApp.router(
      title: 'Week 5 - Offline Notes',
      debugShowCheckedModeBanner: false,
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
