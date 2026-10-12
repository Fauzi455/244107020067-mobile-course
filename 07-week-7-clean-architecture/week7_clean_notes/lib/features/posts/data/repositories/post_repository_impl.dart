// IMPLEMENTASI kontrak PostRepository: cache-first read.
//
// Strategi offline-first (dulu tersebar di `sync.dart` Minggu 5) kini menjadi
// satu kelas di layer data yang mudah diuji: baca cache, lalu (opsional)
// refresh dari jaringan dan simpan ulang ke cache.

import '../../../../core/failures.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/post_repository.dart';
import '../datasources/post_cache_datasource.dart';
import '../datasources/post_remote_datasource.dart';

class PostRepositoryImpl implements PostRepository {
  const PostRepositoryImpl(this._remote, this._cache);
  final PostRemoteDataSource _remote;
  final PostCacheDataSource _cache;

  @override
  Future<({List<Post> posts, Failure? failure})> cachedPosts() async {
    try {
      final models = await _cache.readAll();
      return (posts: models.map((m) => m.toEntity()).toList(), failure: null);
    } catch (e) {
      return (
        posts: const <Post>[],
        failure: LocalFailure('Gagal membaca cache posts: $e'),
      );
    }
  }

  @override
  Future<({List<Post> posts, Failure? failure})> refresh({
    int limit = 20,
  }) async {
    try {
      final models = await _remote.fetchPosts(limit: limit);
      await _cache.replaceAll(models);
      return (posts: models.map((m) => m.toEntity()).toList(), failure: null);
    } catch (e) {
      return (
        posts: const <Post>[],
        failure: NetworkFailure('Gagal mengambil posts dari jaringan: $e'),
      );
    }
  }
}
