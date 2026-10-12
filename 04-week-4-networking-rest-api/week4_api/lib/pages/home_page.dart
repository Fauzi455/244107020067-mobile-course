// Halaman beranda: pintu masuk ke seluruh fitur minggu 4.
//
// Modul awalnya memakai `PagedPostPage` langsung sebagai `home`. Setelah
// menyelesaikan Refactoring Challenge (menambahkan GoRouter + halaman
// detail), beranda diubah menjadi menu kecil ini supaya semua fitur —
// daftar biasa, pagination, dan detail — bisa diakses dan didemokan.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Week 4 - REST API')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionHeader(
            title: 'Networking & REST API',
            subtitle:
                'Dio terpusat + Repository pattern + Riverpod AsyncValue. '
                'Sumber data: JSONPlaceholder (tanpa API key).',
          ),
          const SizedBox(height: 16),
          _MenuCard(
            icon: Icons.list_alt,
            title: 'Daftar Posts',
            description:
                'Empat state: loading, error (+ retry), empty, dan success. '
                'Tarik ke bawah untuk refresh.',
            route: '/posts',
          ),
          const SizedBox(height: 12),
          _MenuCard(
            icon: Icons.all_inclusive,
            title: 'Posts (Pagination)',
            description:
                'Infinite scroll 10 item per halaman dengan guard request '
                'ganda dan indikator akhir data.',
            route: '/paged',
          ),
          const SizedBox(height: 24),
          const _SectionHeader(
            title: 'Coba juga',
            subtitle:
                'Ketuk salah satu post untuk membuka halaman detail berisi '
                'judul, isi lengkap, dan komentar.',
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String description;
  final String route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(route),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
