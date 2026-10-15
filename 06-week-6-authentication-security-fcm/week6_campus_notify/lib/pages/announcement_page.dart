// Halaman tujuan deep link `/pengumuman/:id`.
//
// Halaman ini adalah bukti visual untuk tabel pengujian tiga app state: ia
// menampilkan rute yang diterima dan dari state mana halaman dibuka
// (foreground / background / terminated).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/announcements.dart';
import '../data/api_errors.dart';
import '../providers/providers.dart';
import '../routes.dart';

final announcementDetailProvider = FutureProvider.family<Announcement, String>(
  (ref, id) async {
    return ref.watch(announcementRepositoryProvider).byId(id);
  },
);

class AnnouncementPage extends ConsumerWidget {
  const AnnouncementPage({super.key, required this.id, this.openedFrom});

  final String id;

  /// Label app state asal: foreground / background / terminated.
  final String? openedFrom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(announcementDetailProvider(id));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Pengumuman')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: scheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.link,
                      size: 17,
                      color: scheme.onTertiaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Deep link ${AppRoutes.announcement(id)}',
                        style: TextStyle(
                          color: scheme.onTertiaryContainer,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Dibuka dari state: ${openedFrom ?? 'navigasi manual'}',
                  style: TextStyle(
                    color: scheme.onTertiaryContainer,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          detail.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => _Fallback(
              id: id,
              message: friendlyApiMessage(error),
              onRetry: () => ref.invalidate(announcementDetailProvider(id)),
            ),
            data: (item) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 15,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.publishedAt,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 26),
                Text(
                  item.body,
                  style: const TextStyle(fontSize: 14.5, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({
    required this.id,
    required this.message,
    required this.onRetry,
  });

  final String id;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pengumuman #$id',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: scheme.errorContainer,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Isi pengumuman tidak dapat diambil',
                style: TextStyle(
                  color: scheme.onErrorContainer,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                style: TextStyle(
                  color: scheme.onErrorContainer,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Rute tetap berhasil dibuka — yang gagal hanya pengambilan '
                'data dari server.',
                style: TextStyle(
                  color: scheme.onErrorContainer,
                  fontSize: 11.5,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onRetry,
                  child: const Text('Coba lagi'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
