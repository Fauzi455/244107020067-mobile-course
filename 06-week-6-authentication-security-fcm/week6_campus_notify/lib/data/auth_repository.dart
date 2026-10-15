// Repository autentikasi.
//
// Codelab ini memakai **mock auth provider + JWT simulasi** supaya aplikasi
// bisa berjalan tanpa backend sungguhan. Bentuk kelasnya sengaja dibuat sama
// dengan yang akan dipakai Firebase Auth, sehingga migrasi nanti hanya
// mengganti ISI method, bukan tanda tangannya.
//
// Titik penggantian ke Firebase Auth:
//   FirebaseAuth.instance.signInWithEmailAndPassword(email:, password:)
//     -> user.getIdToken()  (ID token)  -> dipakai sebagai `access`
//     -> refresh token ditangani SDK (secure storage internal)
// Untuk Google Sign-In: GoogleSignIn().signIn() -> authentication ->
//   GoogleAuthProvider.credential(...) -> signInWithCredential(...).

import 'dart:math';

/// Pasangan token hasil login. Keduanya RAHASIA.
class AuthSession {
  const AuthSession({required this.access, required this.refresh});

  /// Umur pendek (simulasi 15 menit). Dikirim sebagai `Authorization: Bearer`.
  final String access;

  /// Umur panjang (simulasi 7 hari). Hanya boleh ada di secure storage.
  final String refresh;
}

class AuthRepository {
  AuthRepository({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Batas atas nonce access token baru.
  ///
  /// Ditulis sebagai **literal**, bukan `1 << 32`, karena aritmetika bitwise di
  /// web (dart2js) berjalan 32-bit: `1 << 32` di sana TIDAK menghasilkan 2^32
  /// melainkan 0, sehingga `Random.nextInt(0)` melempar
  /// `RangeError: max must be in range 0 < max ≤ 2^32, was 0`. Efeknya bukan
  /// sekadar token aneh — seluruh **jalur refresh gagal di web**, interceptor
  /// menganggap sesi mati, dan pengguna terlempar ke `/login` tanpa sebab yang
  /// terlihat. Nilai di bawah aman di VM, dart2js, maupun AOT.
  static const int refreshNonceMax = 2147483647;

  /// Menggantikan `FirebaseAuth.instance.signInWithEmailAndPassword`.
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));

    if (!email.contains('@')) {
      throw const AuthException('Format email tidak valid');
    }
    if (password.length < 6) {
      throw const AuthException('Kata sandi minimal 6 karakter');
    }

    // Simulasi JWT `header.payload.signature`. JANGAN pernah mem-parse JWT
    // secara manual di produksi — verifikasi selalu di sisi server.
    return AuthSession(
      access: 'mock-access-for-$email',
      refresh: 'mock-refresh-for-$email',
    );
  }

  /// Menukar refresh token dengan access token baru.
  ///
  /// Dipanggil interceptor Dio **hanya sekali** per 401. Kalau method ini ikut
  /// gagal, sesi dianggap mati dan pengguna dipaksa login ulang.
  Future<String> refresh(String refreshToken) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (refreshToken.isEmpty) {
      throw const AuthException('Refresh token hilang');
    }
    if (!refreshToken.startsWith('mock-refresh-for-')) {
      throw const AuthException('Refresh token tidak dikenal server');
    }
    return 'mock-access-renewed-${_random.nextInt(refreshNonceMax)}';
  }

  Future<void> logout() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
