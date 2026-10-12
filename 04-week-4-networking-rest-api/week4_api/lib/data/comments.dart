// Provider komentar (AI Prompt Challenge).
//
// Menggunakan `AsyncNotifierProvider.family` sehingga UI cukup memanggil
// `ref.watch(commentsProvider(postId))` dan langsung mendapatkan
// `AsyncValue<List<Comment>>` (loading / error / data) tanpa try/catch.
//
// Argumen family diteruskan lewat konstruktor notifier (pola Riverpod 3),
// sedangkan `build()` tetap tanpa parameter.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/comment.dart';
import 'providers.dart';

class CommentListNotifier extends AsyncNotifier<List<Comment>> {
  CommentListNotifier(this.postId);

  final int postId;

  @override
  Future<List<Comment>> build() async {
    // Exception dari repository otomatis menjadi AsyncError.
    final repository = ref.watch(commentRepositoryProvider);
    return repository.fetchComments(postId);
  }

  /// Muat ulang komentar (dipanggil tombol "Coba lagi").
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(commentRepositoryProvider).fetchComments(postId);
    });
  }
}

final commentsProvider =
    AsyncNotifierProvider.family<CommentListNotifier, List<Comment>, int>(
  CommentListNotifier.new,
  // Matikan retry otomatis Riverpod 3 agar error langsung final dan
  // mudah diuji (tanpa ini test akan menggantung menunggu retry).
  retry: (retryCount, error) => null,
);
