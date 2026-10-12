// Halaman pengaturan (tab "Pengaturan").
//
// Menyimpan preferensi lewat PrefsRepository:
//   - tema gelap/terang (dark_mode)
//   - waktu terakhir dibuka (last_opened_at)
//   - toggle forceOffline untuk simulasi offline deterministik

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkAsync = ref.watch(darkModeProvider);
    final lastOpened = ref.watch(lastOpenedProvider).value;
    final forceOffline = ref.watch(forceOfflineProvider);
    final dark = darkAsync.value ?? false;

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
            onChanged: (_) => ref.read(darkModeProvider.notifier).toggle(),
          ),
          const Divider(),
          const _SectionLabel('Sesi'),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Terakhir dibuka'),
            subtitle: Text(
              lastOpened == null ? 'Belum ada catatan' : _prettyTime(lastOpened),
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

String _prettyTime(String iso) {
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return iso;
  final local = parsed.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} '
      '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
}
