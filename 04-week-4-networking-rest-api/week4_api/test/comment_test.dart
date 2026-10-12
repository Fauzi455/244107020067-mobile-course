// Unit test untuk model Comment dan provider komentar dengan repository
// palsu (AI Prompt Challenge). Tidak ada HTTP sungguhan di sini.

import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week4_api/data/comments.dart';
import 'package:week4_api/data/models/comment.dart';
import 'package:week4_api/data/providers.dart';
import 'package:week4_api/data/repositories/comment_repository.dart';

class FakeCommentRepository extends CommentRepository {
  FakeCommentRepository({this.items, this.throwError = false}) : super(Dio());
  final List<Comment>? items;
  final bool throwError;

  @override
  Future<List<Comment>> fetchComments(int postId) async {
    if (throwError) {
      throw DioException(
        requestOptions: RequestOptions(path: '/comments'),
        type: DioExceptionType.connectionError,
      );
    }
    return items ?? const [];
  }
}

void main() {
  group('Comment.fromJson', () {
    test('aman terhadap field yang hilang', () {
      final comment = Comment.fromJson({'postId': 1});
      expect(comment.postId, 1);
      expect(comment.id, 0);
      expect(comment.name, '');
      expect(comment.email, '');
      expect(comment.body, '');
    });

    test('memetakan seluruh field dengan benar', () {
      final comment = Comment.fromJson({
        'postId': 2,
        'id': 9,
        'name': 'Budi',
        'email': 'budi@example.com',
        'body': 'Mantap',
      });
      expect(comment.postId, 2);
      expect(comment.id, 9);
      expect(comment.name, 'Budi');
      expect(comment.email, 'budi@example.com');
      expect(comment.body, 'Mantap');
    });
  });

  group('commentsProvider', () {
    test('sukses dengan repository palsu', () async {
      final container = ProviderContainer(
        overrides: [
          commentRepositoryProvider.overrideWithValue(
            FakeCommentRepository(items: const [
              Comment(
                postId: 1,
                id: 1,
                name: 'Budi',
                email: 'budi@example.com',
                body: 'Mantap',
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final comments = await container.read(commentsProvider(1).future);
      expect(comments.length, 1);
      expect(comments.first.name, 'Budi');
    });

    test('error dengan repository palsu', () async {
      final container = ProviderContainer(
        overrides: [
          commentRepositoryProvider.overrideWithValue(
            FakeCommentRepository(throwError: true),
          ),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(commentsProvider(1).future),
        throwsA(isA<DioException>()),
      );
    });
  });
}
