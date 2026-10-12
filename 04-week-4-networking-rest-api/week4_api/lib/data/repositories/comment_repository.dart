// Repository untuk resource Comment (AI Prompt Challenge).
//
// Satu-satunya pintu ke endpoint `GET /comments?postId={id}`. UI tidak boleh
// memanggil Dio secara langsung; seluruh akses lewat repository + provider.
//
// Timeout tidak ditulis ulang di sini karena sudah terpusat pada
// `createDio()` (connectTimeout/receiveTimeout 10 detik) — inilah gunanya
// client jaringan terpusat.

import 'package:dio/dio.dart';
import '../models/comment.dart';

class CommentRepository {
  CommentRepository(this._dio);
  final Dio _dio;

  /// Ambil semua komentar milik sebuah post.
  Future<List<Comment>> fetchComments(int postId) async {
    final response = await _dio.get<List>(
      '/comments',
      queryParameters: {'postId': postId},
    );
    final data = response.data ?? [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(Comment.fromJson)
        .toList();
  }
}
