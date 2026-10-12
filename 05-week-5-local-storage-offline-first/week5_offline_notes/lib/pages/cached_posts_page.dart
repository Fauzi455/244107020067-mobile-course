// Halaman cache-first read (tab "Posts").
//
// Alur offline-first:
//   1. `cachedPostsProvider.build()` langsung mengembalikan isi tabel
//      `cached_posts` -> UI tidak blank meski offline.
//   2. Di background, data di-refresh dari jaringan dan disimpan ke cache.
//
// Saat `forceOffline` aktif (Pengaturan), refresh jaringan dilewati sehingga
// demo offline menjadi deterministik.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';

class CachedPostsPage extends ConsumerWidget {
  const CachedPostsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(cachedPostsProvider);
    final forceOffline = ref.watch(forceOfflineProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts (Cache)'),
        actions: [
          IconButton(
            tooltip: 'Refresh dari jaringan',
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(cachedPostsProvider.notifier).refreshFromNetwork(),
          ),
        ],
      ),
      body: Column(
        children: [
          MaterialBanner(
            leading: Icon(
              forceOffline ? Icons.wifi_off : Icons.cloud_sync,
              color: theme.colorScheme.primary,
            ),
            content: Text(
              forceOffline
                  ? 'Mode offline: data ditampilkan dari cache lokal.'
                  : 'Cache-first: tampil dari cache, lalu refresh di background.',
            ),
            actions: const [SizedBox.shrink()],
          ),
          Expanded(
            child: postsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        'Belum ada cache dan jaringan tidak tersedia.\n$err',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => ref.invalidate(cachedPostsProvider),
                        child: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (posts) {
                if (posts.isEmpty) {
                  return const Center(
                    child: Text('Cache kosong. Hubungkan internet lalu refresh.'),
                  );
                }
                return ListView.separated(
                  itemCount: posts.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return ListTile(
                      leading: CircleAvatar(child: Text(post.id.toString())),
                      title: Text(
                        post.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        post.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
