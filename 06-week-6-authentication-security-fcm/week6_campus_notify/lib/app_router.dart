// Konstruksi GoRouter + guard route.
//
// Guard: selama tidak ada access token, SEMUA rute dialihkan ke `/login`.
// Sebaliknya, saat sudah login, `/login` dialihkan ke beranda. Ini yang
// membuat deep link dari notifikasi tetap aman: kalau notifikasi diklik saat
// pengguna sudah logout, ia mendarat di halaman login lebih dulu.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'pages/announcement_page.dart';
import 'pages/home_shell_page.dart';
import 'pages/login_page.dart';
import 'providers/auth_provider.dart';
import 'routes.dart';

GoRouter createRouter(ProviderContainer container) {
  final refresh = _AuthRefreshNotifier(container);

  // `main()` sudah menunggu sesi selesai dibaca, jadi keputusan "sudah login
  // atau belum" sudah pasti di sini. Memakainya sebagai `initialLocation`
  // mencegah beranda (beserta seluruh tab-nya) sempat dibangun saat pengguna
  // masih tamu — kalau tidak, request API berangkat tanpa token dan
  // menghasilkan 401 palsu yang mengotori log.
  final alreadyLoggedIn = container.read(authStateProvider).value ?? false;

  return GoRouter(
    initialLocation: alreadyLoggedIn ? AppRoutes.home : AppRoutes.login,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = container.read(authStateProvider);

      // Selagi sesi masih dibaca dari secure storage, jangan mengalihkan ke
      // mana-mana supaya deep link tidak "ditelan" sebelum sempat diproses.
      if (auth.isLoading) return null;

      final loggedIn = auth.value ?? false;
      final goingToLogin = state.matchedLocation == AppRoutes.login;

      if (!loggedIn && !goingToLogin) return AppRoutes.login;
      if (loggedIn && goingToLogin) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeShellPage(),
      ),
      GoRoute(
        path: AppRoutes.announcementPattern,
        builder: (context, state) => AnnouncementPage(
          id: state.pathParameters['id'] ?? '',
          // Dari state mana halaman ini dibuka — dipakai sebagai bukti
          // pada tabel pengujian tiga app state.
          openedFrom: state.extra?.toString(),
        ),
      ),
    ],
  );
}

/// Menjembatani perubahan state autentikasi ke `refreshListenable` GoRouter.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(ProviderContainer container) {
    _subscription = container.listen<AsyncValue<bool>>(
      authStateProvider,
      (previous, next) => notifyListeners(),
    );
  }

  late final ProviderSubscription<AsyncValue<bool>> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}
