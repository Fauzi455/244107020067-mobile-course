// Unit test untuk model Post, error mapping, dan provider dengan
// repository palsu (tanpa HTTP sungguhan).
//
// Pola override repository palsu ini adalah fondasi mock API yang
// dipakai lagi di Minggu 12 (Testing & QA). Pastikan tidak ada
// request HTTP sungguhan di dalam test.

import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week4_api/data/models/post.dart';
import 'package:week4_api/data/providers.dart';
import 'package:week4_api/data/repositories/post_repository.dart';

class FakePostRepository extends PostRepository {
  FakePostRepository({this.items, this.throwError = false})
      : super(Dio());
  final List<Post>? items;
  final bool throwError;

  @override
  Future<List<Post>> fetchPosts() async {
    if (throwError) {
      throw DioException(
        requestOptions: RequestOptions(path: '/posts'),
        type: DioExceptionType.connectionError,
      );
    }
    return items ?? const [];
  }

  @override
  Future<List<Post>> fetchPostsPage(
      {required int page, int limit = 10}) async {
    return fetchPosts();
  }
}

DioException _badResponse(int statusCode) {
  return DioException(
    requestOptions: RequestOptions(path: '/posts'),
    type: DioExceptionType.badResponse,
    response: Response(
      requestOptions: RequestOptions(path: '/posts'),
      statusCode: statusCode,
    ),
  );
}

void main() {
  group('Post.fromJson', () {
    test('aman terhadap field yang hilang', () {
      final post = Post.fromJson({'id': 7});
      expect(post.id, 7);
      expect(post.title, '');
      expect(post.body, '');
      expect(post.userId, 0);
    });

    test('aman terhadap angka desimal dan field null (edge case tambahan)', () {
      // Beberapa API mengirim angka sebagai double (mis. 3.0) atau null.
      final post = Post.fromJson({
        'id': 12,
        'userId': 3.0,
        'title': null,
        'body': null,
      });
      expect(post.id, 12);
      expect(post.userId, 3); // 3.0 -> 3
      expect(post.title, '');
      expect(post.body, '');
    });

    test('round-trip toJson -> fromJson', () {
      const original = Post(userId: 1, id: 1, title: 'Tes', body: 'Isi');
      final restored = Post.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.body, original.body);
    });
  });

  group('friendlyErrorMessage', () {
    test('connection error -> pesan "terhubung"', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/posts'),
        type: DioExceptionType.connectionError,
      );
      expect(friendlyErrorMessage(err), contains('terhubung'));
    });

    test('timeout -> pesan "timeout"', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/posts'),
        type: DioExceptionType.receiveTimeout,
      );
      expect(friendlyErrorMessage(err), contains('timeout'));
    });

    test('404 -> pesan "tidak ditemukan"', () {
      expect(friendlyErrorMessage(_badResponse(404)), contains('tidak ditemukan'));
    });

    test('500 -> pesan "Server bermasalah"', () {
      expect(friendlyErrorMessage(_badResponse(500)), contains('Server bermasalah'));
    });
  });

  group('postListProvider', () {
    test('sukses dengan repository palsu', () async {
      final container = ProviderContainer(
        overrides: [
          postRepositoryProvider.overrideWithValue(
            FakePostRepository(items: [
              const Post(userId: 1, id: 1, title: 'Tes', body: 'Isi'),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);
      // Gunakan helper readPostsOnce (lihat providers.dart).
      final posts = await readPostsOnce(container);
      expect(posts.length, 1);
      expect(posts.first.title, 'Tes');
    });

    test('error dengan repository palsu', () async {
      final container = ProviderContainer(
        overrides: [
          postRepositoryProvider.overrideWithValue(
            FakePostRepository(throwError: true),
          ),
        ],
      );
      addTearDown(container.dispose);
      // Gunakan helper readPostsErrorOnce (lihat providers.dart).
      final err = await readPostsErrorOnce(container);
      expect(err, isA<DioException>());
      expect(friendlyErrorMessage(err!), contains('terhubung'));
    });
  });
}
