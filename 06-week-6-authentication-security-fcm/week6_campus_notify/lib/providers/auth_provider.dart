// State autentikasi + guard route.
//
// `authStateProvider` sengaja bertipe `bool` (persis seperti modul): nilainya
// hanya menjawab satu pertanyaan — "sudah punya access token atau belum?".
// Detail pengguna (email) diturunkan terpisah lewat `currentUserEmailProvider`
// supaya guard tetap sederhana dan tidak ikut bergetar saat data profil
// berubah.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    // Sumber kebenaran sesi adalah secure storage, bukan variabel di memori.
    final token = await ref.watch(tokenStoreProvider).readAccess();
    return token != null && token.isNotEmpty;
  }

  /// Login mock. Bila kelak memakai Firebase Auth, hanya isi method ini yang
  /// berganti (`signInWithEmailAndPassword`), tanda tangannya tetap.
  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = await ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);
      await ref
          .read(tokenStoreProvider)
          .save(access: session.access, refresh: session.refresh);
      return true;
    });
  }

  /// Logout lokal: hapus seluruh token. Refresh token ikut terhapus sehingga
  /// tidak ada cara memulihkan sesi tanpa login ulang.
  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    await ref.read(tokenStoreProvider).clear();
    ref.invalidateSelf();
    await future;
  }

  /// Dipakai interceptor Dio ketika sesi tidak bisa diselamatkan lagi
  /// (refresh token hilang / kedaluwarsa). Tidak memanggil backend karena
  /// memang tidak ada lagi kredensial yang sah; cukup bersihkan lalu paksa
  /// guard route mengarahkan pengguna ke `/login`.
  Future<void> forceLogout() async {
    await ref.read(tokenStoreProvider).clear();
    ref.invalidateSelf();
    await future;
  }
}

final authStateProvider = AsyncNotifierProvider<AuthNotifier, bool>(
  AuthNotifier.new,
  retry: (retryCount, error) => null,
);

/// Email pengguna aktif, diturunkan dari access token mock.
///
/// Pada versi Firebase, nilai ini diganti
/// `FirebaseAuth.instance.currentUser?.email`.
final currentUserEmailProvider = FutureProvider<String?>((ref) async {
  await ref.watch(authStateProvider.future);
  final token = await ref.read(tokenStoreProvider).readAccess();
  if (token == null || !token.startsWith('mock-access-for-')) return null;
  return token.substring('mock-access-for-'.length);
});
