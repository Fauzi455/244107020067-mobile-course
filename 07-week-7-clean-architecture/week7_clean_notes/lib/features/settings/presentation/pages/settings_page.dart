// Halaman pengaturan (tab "Pengaturan") — presentation murni.
//
// Halaman ini tidak menyentuh SharedPreferences. Ia hanya:
//   - membaca state lewat `settingsProvider` / `lastOpenedProvider`, dan
//   - memanggil notifier untuk mengubah preferensi.
//
// Formatting tanggal dipanggil dari `lib/core/format.dart` (fungsi murni),
// bukan ditulis ulang di dalam widget.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format.dart';
import '../providers/settings_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = ref.watch(darkModeProvider);
    final lastOpened = ref.watch(lastOpenedProvider);
    final forceOffline = ref.watch(forceOfflineProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          const _SectionLabel('Tampilan'),
          SwitchListTile(
            secondary: Icon(dark ? Icons.dark_mode : Icons.light_mode),
            title: const Text('Tema gelap'),
            subtitle: const Text('Disimpan di SharedPreferences'),
            value: dark,
            onChanged: (_) =>
                ref.read(settingsProvider.notifier).toggleDarkMode(),
          ),
          const Divider(),
          const _SectionLabel('Sesi'),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Terakhir dibuka'),
            subtitle: Text(
              lastOpened == null
                  ? 'Belum ada catatan'
                  : formatDateTimeWithSeconds(lastOpened),
            ),
          ),
          const Divider(),
          const _SectionLabel('Offline-first'),
          SwitchListTile(
            secondary: const Icon(Icons.wifi_off),
            title: const Text('Simulasi offline'),
            subtitle: const Text(
              'Lewati refresh jaringan & sinkronisasi agar demo deterministik',
            ),
            value: forceOffline,
            onChanged: (_) => ref.read(forceOfflineProvider.notifier).toggle(),
          ),
          const Divider(),
          const _SectionLabel('Penyimpanan'),
          const ListTile(
            leading: Icon(Icons.key_outlined),
            title: Text('Preferensi'),
            subtitle: Text('SharedPreferences — key-value kecil (tema, waktu)'),
          ),
          const ListTile(
            leading: Icon(Icons.table_chart_outlined),
            title: Text('Catatan'),
            subtitle: Text('SQLite (sqflite) — data relasional + antrean sync'),
          ),
          const ListTile(
            leading: Icon(Icons.cached),
            title: Text('Cache posts'),
            subtitle: Text('Tabel cached_posts — cache-first read'),
          ),
          const Divider(),
          const _SectionLabel('Arsitektur'),
          const ListTile(
            leading: Icon(Icons.account_tree_outlined),
            title: Text('Clean Architecture'),
            subtitle: Text(
              'presentation -> domain <- data, satu folder per fitur',
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
