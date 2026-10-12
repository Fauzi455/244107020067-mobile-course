// Konfigurasi navigasi terpusat dengan GoRouter (Refactoring Challenge no. 3).
//
// Rute:
//   /            -> HomePage (menu fitur)
//   /posts       -> PostListPage (daftar + empat state)
//   /paged       -> PagedPostPage (infinite scroll)
//   /post/:id    -> PostDetailPage (judul + isi lengkap + komentar)

import 'package:go_router/go_router.dart';
import 'pages/home_page.dart';
import 'pages/paged_post_page.dart';
import 'pages/post_detail_page.dart';
import 'pages/post_list_page.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/posts',
      builder: (context, state) => const PostListPage(),
    ),
    GoRoute(
      path: '/paged',
      builder: (context, state) => const PagedPostPage(),
    ),
    GoRoute(
      path: '/post/:id',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return PostDetailPage(postId: id);
      },
    ),
  ],
);
