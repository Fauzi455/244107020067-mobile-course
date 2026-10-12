// =============================================================================
// OUTPUT AWAL AI (belum diverifikasi) — AI Prompt Challenge Minggu 4
// -----------------------------------------------------------------------------
// Ini adalah hasil awal dari AI coding assistant atas prompt:
//
//   "Buatkan repository layer Flutter untuk endpoint GET /comments?postId={id}
//    dari JSONPlaceholder menggunakan Dio + flutter_riverpod.
//    Requirements:
//    - Model Comment dengan fromJson aman null (postId, id, name, email, body).
//    - CommentRepository dengan method fetchComments(postId) + timeout 10 detik.
//    - AsyncNotifierProvider dengan penanganan error otomatis (AsyncError)
//      dan fungsi pesan error ramah pengguna untuk timeout, connection error,
//      404, dan 500.
//    - Satu unit test untuk fromJson dengan field yang hilang.
//    Jelaskan setiap bagian kode dalam komentar."
//
// Kode ini TIDAK dipakai apa adanya. Lihat docs/AI_challenge/README.md untuk
// daftar masalah yang ditemukan dan perbaikannya (versi final ada di
// lib/data/models/comment.dart, lib/data/repositories/comment_repository.dart,
// dan lib/data/comments.dart).
// =============================================================================

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---- Masalah #1: fromJson TIDAK aman null (cast langsung) -------------------
class Comment {
  Comment({
    required this.postId,
    required this.id,
    required this.name,
    required this.email,
    required this.body,
  });

  final int postId;
  final int id;
  final String name;
  final String email;
  final String body;

  factory Comment.fromJson(Map<String, dynamic> json) {
    // BUG: bila salah satu field hilang -> crash
    // "type 'Null' is not a subtype of type 'int'".
    return Comment(
      postId: json['postId'] as int,
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      body: json['body'] as String,
    );
  }
}

// ---- Masalah #2: timeout ditulis di tiap method, bukan terpusat ------------
class CommentRepository {
  CommentRepository(this._dio);
  final Dio _dio;

  Future<List<Comment>> fetchComments(int postId) async {
    final response = await _dio.get<List>(
      '/comments',
      queryParameters: {'postId': postId},
      // BUG: timeout tersebar; tidak konsisten dengan client lain.
      options: Options(receiveTimeout: const Duration(seconds: 10)),
    );
    return (response.data ?? []).map((e) => Comment.fromJson(e)).toList();
  }
}

final commentRepositoryProvider = Provider<CommentRepository>(
  (ref) => CommentRepository(Dio()),
);

// ---- Masalah #3: memakai FutureProvider, bukan AsyncNotifierProvider -------
final commentsProvider =
    FutureProvider.family<List<Comment>, int>((ref, postId) {
  return ref.watch(commentRepositoryProvider).fetchComments(postId);
});

// ---- Masalah #4: pesan error tidak lengkap (404/500 tidak dibedakan) -------
String friendlyErrorMessage(Object error) {
  // BUG: hanya menangani connectionError; timeout & badResponse jatuh ke
  // pesan generik, dan pesan teknis mentah bisa bocor ke UI.
  if (error is DioException) {
    if (error.type == DioExceptionType.connectionError) {
      return 'Tidak dapat terhubung ke server.';
    }
    return error.message ?? 'Error';
  }
  return error.toString();
}

// ---- Masalah #5: unit test hanya happy path --------------------------------
// (Tanpa kasus field hilang, padahal requirement memintanya.)

/*
test('parse comment', () {
  final c = Comment.fromJson({
    'postId': 1, 'id': 1, 'name': 'a', 'email': 'b', 'body': 'c',
  });
  expect(c.id, 1);
});
*/
