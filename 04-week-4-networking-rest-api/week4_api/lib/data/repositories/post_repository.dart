// Repository sebagai satu-satunya pintu ke sumber data (API).
//
// Aturan arsitektur minggu ini:
// - UI tidak boleh memanggil Dio/http secara langsung. UI hanya membaca
//   provider.
// - Repository mengubah exception jaringan menjadi kegagalan yang bermakna
//   bagi UI.
//
// Peran penting: repository tidak menampilkan UI apa pun dan tidak menangkap
// exception menjadi nilai diam-diam. Exception dibiarkan naik agar provider
// mengubahnya menjadi `AsyncError` secara otomatis.

import 'package:dio/dio.dart';
import '../models/post.dart';

class PostRepository {
  PostRepository(this._dio);
  final Dio _dio;

  /// Ambil semua post (endpoint `GET /posts`).
  Future<List<Post>> fetchPosts() async {
    final response = await _dio.get<List>('/posts');
    final data = response.data ?? [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(Post.fromJson)
        .toList();
  }

  /// Ambil post per halaman (pagination, `GET /posts?_page=N&_limit=M`).
  Future<List<Post>> fetchPostsPage({
    required int page,
    int limit = 10,
  }) async {
    final response = await _dio.get<List>(
      '/posts',
      queryParameters: {'_page': page, '_limit': limit},
    );
    final data = response.data ?? [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(Post.fromJson)
        .toList();
  }

  /// Ambil satu post berdasarkan id (`GET /posts/{id}`).
  ///
  /// Dipakai halaman detail (`/post/:id`) ketika post tersebut belum ada di
  /// daftar yang sudah dimuat — misalnya saat pengguna membuka deep link
  /// langsung ke halaman detail.
  Future<Post> fetchPostById(int id) async {
    final response = await _dio.get<Map<String, dynamic>>('/posts/$id');
    return Post.fromJson(response.data ?? const <String, dynamic>{});
  }
}
