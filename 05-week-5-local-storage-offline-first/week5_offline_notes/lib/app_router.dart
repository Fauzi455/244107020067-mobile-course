// Konfigurasi navigasi terpusat dengan GoRouter (Refactoring Challenge no. 3).
//
//   /          -> HomePage (tab Catatan / Posts / Pengaturan)
//   /note/:id  -> NoteDetailPage (baca dari repository lokal)

import 'package:go_router/go_router.dart';

import 'pages/home_page.dart';
import 'pages/note_detail_page.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/note/:id',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return NoteDetailPage(noteId: id);
      },
    ),
  ],
);
