// Provider detail post (Refactoring Challenge no. 3).
//
// Strategi "list-first, network-fallback": bila post sudah ada di daftar
// paged yang sudah dimuat, pakai data itu (instan, tanpa request). Bila tidak
// ada (misalnya deep link langsung ke `/post/:id`), baru ambil dari API lewat
// `PostRepository.fetchPostById`.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/post.dart';
import 'paged_posts.dart';
import 'providers.dart';

final postDetailProvider = FutureProvider.family<Post, int>((ref, id) async {
  final repository = ref.watch(postRepositoryProvider);

  // 1) Coba temukan dari cache daftar yang sudah dimuat.
  final cached = ref.read(pagedPostsProvider).items;
  for (final post in cached) {
    if (post.id == id) return post;
  }

  // 2) Fallback ke API bila belum ada di cache.
  return repository.fetchPostById(id);
});
