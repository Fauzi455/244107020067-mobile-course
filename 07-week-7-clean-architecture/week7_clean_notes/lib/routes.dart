// Konfigurasi navigasi terpusat (GoRouter) + konstanta rute.
//
//   /          -> HomeShellPage (tab Catatan / Posts / Pengaturan)
//   /note/:id  -> NoteDetailPage (baca dari repository lokal)
//
// Halaman TIDAK menulis string rute secara literal; semuanya lewat
// `AppRoutes`. Parsing parameter rute diserahkan ke fungsi murni
// `parseNoteId` di `core/format.dart` agar bisa diuji tanpa GoRouter.

import 'package:go_router/go_router.dart';

import 'core/format.dart';
import 'features/home/presentation/pages/home_shell_page.dart';
import 'features/notes/presentation/pages/note_detail_page.dart';

abstract final class AppRoutes {
  static const String home = '/';
  static const String noteDetailPattern = '/note/:id';

  static String noteDetail(int id) => '/note/$id';
}

final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeShellPage(),
    ),
    GoRoute(
      path: AppRoutes.noteDetailPattern,
      builder: (context, state) =>
          NoteDetailPage(noteId: parseNoteId(state.pathParameters['id'])),
    ),
  ],
);
