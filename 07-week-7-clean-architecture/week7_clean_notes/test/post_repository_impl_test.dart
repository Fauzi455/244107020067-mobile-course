// TEST repository posts (layer data) dengan data source PALSU.
//
// Menguji aturan cache-first di `PostRepositoryImpl` tanpa jaringan dan tanpa
// SQLite: pakai fake Dio-free datasource.

import 'package:flutter_test/flutter_test.dart';
import 'package:week7_clean_notes/core/failures.dart';
import 'package:week7_clean_notes/features/posts/data/datasources/post_cache_datasource.dart';
import 'package:week7_clean_notes/features/posts/data/datasources/post_remote_datasource.dart';
import 'package:week7_clean_notes/features/posts/data/models/post_model.dart';
import 'package:week7_clean_notes/features/posts/data/repositories/post_repository_impl.dart';

class FakePostRemoteDataSource implements PostRemoteDataSource {
  FakePostRemoteDataSource({this.models, this.fail = false});

  final List<PostModel>? models;
  final bool fail;

  @override
  Future<List<PostModel>> fetchPosts({int limit = 20}) async {
    if (fail) {
      throw Exception('koneksi terputus (simulasi)');
    }
    return models ?? const <PostModel>[];
  }
}

class FakePostCacheDataSource implements PostCacheDataSource {
  FakePostCacheDataSource([List<PostModel>? seed])
    : stored = List<PostModel>.from(seed ?? const <PostModel>[]);

  List<PostModel> stored;
  int replaceCalls = 0;

  @override
  Future<List<PostModel>> readAll() async => stored;

  @override
  Future<void> replaceAll(List<PostModel> posts) async {
    replaceCalls++;
    stored = List<PostModel>.from(posts);
  }
}

PostModel post(int id) =>
    PostModel(id: id, userId: 1, title: 'Judul $id', body: 'Isi $id');

void main() {
  test('cachedPosts mengembalikan isi cache sebagai entity', () async {
    final repo = PostRepositoryImpl(
      FakePostRemoteDataSource(),
      FakePostCacheDataSource([post(1), post(2)]),
    );

    final result = await repo.cachedPosts();

    expect(result.failure, isNull);
    expect(result.posts.length, 2);
    expect(result.posts.first.title, 'Judul 1');
  });

  test('refresh sukses -> hasil jaringan disimpan ke cache', () async {
    final cache = FakePostCacheDataSource();
    final repo = PostRepositoryImpl(
      FakePostRemoteDataSource(models: [post(1), post(2), post(3)]),
      cache,
    );

    final result = await repo.refresh();

    expect(result.failure, isNull);
    expect(result.posts.length, 3);
    expect(cache.replaceCalls, 1);
    expect(cache.stored.length, 3);
  });

  test('refresh gagal -> NetworkFailure, cache lama tidak dirusak', () async {
    final cache = FakePostCacheDataSource([post(9)]);
    final repo = PostRepositoryImpl(
      FakePostRemoteDataSource(fail: true),
      cache,
    );

    final result = await repo.refresh();

    expect(result.failure, isA<NetworkFailure>());
    expect(result.posts, isEmpty);
    expect(cache.replaceCalls, 0);
    expect(cache.stored.single.id, 9);
  });
}
