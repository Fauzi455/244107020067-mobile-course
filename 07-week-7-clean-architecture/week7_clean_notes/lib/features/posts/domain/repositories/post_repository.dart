// KONTRAK repository posts — di `domain`.
//
// Kontraknya sengaja dinyatakan dalam bahasa bisnis ("ambil dari cache",
// "ambil dari jaringan lalu simpan ke cache"), bukan dalam bahasa teknis
// ("GET /posts", "INSERT INTO cached_posts"). Detail HTTP/SQL adalah urusan
// layer data.

import '../../../../core/failures.dart';
import '../entities/post.dart';

abstract class PostRepository {
  /// Cache-first: kembalikan isi cache lokal seketika (bisa kosong).
  Future<({List<Post> posts, Failure? failure})> cachedPosts();

  /// Ambil dari jaringan; bila berhasil, simpan ke cache agar kunjungan
  /// berikutnya tetap bisa dibuka tanpa internet.
  Future<({List<Post> posts, Failure? failure})> refresh({int limit});
}
