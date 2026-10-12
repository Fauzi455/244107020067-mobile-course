// WIRING DI + STATE fitur posts (cache-first read).
//
// Perbedaan penting dibanding Minggu 5: dulu widget memanggil fungsi bebas
// `readCachedPosts()` / `fetchPostsFromNetwork()` langsung dari `sync.dart`.
// Sekarang semuanya lewat kontrak `PostRepository` di domain, dan Dio hanya
// dikenal oleh layer data.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/failures.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../data/datasources/post_cache_datasource.dart';
import '../../data/datasources/post_remote_datasource.dart';
import '../../data/repositories/post_repository_impl.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/post_repository.dart';

final postRepositoryProvider = Provider<PostRepository>(
  (ref) => PostRepositoryImpl(
    ref.watch(postRemoteDataSourceProvider),
    ref.watch(postCacheDataSourceProvider),
  ),
);

class CachedPostsNotifier extends AsyncNotifier<List<Post>> {
  @override
  Future<List<Post>> build() async {
    final repository = ref.watch(postRepositoryProvider);
    // 1) Segera kembalikan cache agar UI tidak blank saat offline.
    final cached = await repository.cachedPosts();
    // 2) Refresh dari jaringan di background (kecuali mode offline aktif).
    if (!ref.read(forceOfflineProvider)) {
      Future.microtask(refreshFromNetwork);
    }
    return cached.posts;
  }

  Future<void> refreshFromNetwork() async {
    if (ref.read(forceOfflineProvider)) {
      return;
    }
    final result = await ref.read(postRepositoryProvider).refresh();
    final failure = result.failure;
    if (failure == null) {
      state = AsyncData(result.posts);
      return;
    }
    // Cache-first: bila jaringan gagal, pertahankan cache yang ada.
    final cached = await ref.read(postRepositoryProvider).cachedPosts();
    if (cached.posts.isEmpty) {
      state = AsyncError(FailureException(failure), StackTrace.current);
    } else {
      state = AsyncData(cached.posts);
    }
  }
}

final cachedPostsProvider =
    AsyncNotifierProvider<CachedPostsNotifier, List<Post>>(
      CachedPostsNotifier.new,
      retry: (retryCount, error) => null,
    );
