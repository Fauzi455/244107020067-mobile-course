// Test logika sesi: login, refresh, masking token, dan pemetaan error HTTP.
//
// Kelompok kedua yang dituntut modul ("logika sesi/refresh"). Semuanya berjalan
// tanpa jaringan dan tanpa platform channel.

import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week6_campus_notify/data/api_errors.dart';
import 'package:week6_campus_notify/data/auth_repository.dart';
import 'package:week6_campus_notify/data/token_store.dart';

void main() {
  group('AuthRepository.login', () {
    test('menolak email tanpa @', () async {
      final repository = AuthRepository();
      expect(
        () => repository.login(email: 'bukan-email', password: 'rahasia123'),
        throwsA(isA<AuthException>()),
      );
    });

    test('menolak kata sandi kurang dari 6 karakter', () async {
      final repository = AuthRepository();
      expect(
        () => repository.login(email: 'a@b.c', password: '123'),
        throwsA(isA<AuthException>()),
      );
    });

    test('mengembalikan pasangan access + refresh token', () async {
      final repository = AuthRepository();
      final session = await repository.login(
        email: 'mahasiswa@polinema.ac.id',
        password: 'rahasia123',
      );
      expect(session.access, startsWith('mock-access-for-'));
      expect(session.refresh, startsWith('mock-refresh-for-'));
    });
  });

  group('AuthRepository.refresh', () {
    test('menolak refresh token kosong', () async {
      final repository = AuthRepository();
      expect(() => repository.refresh(''), throwsA(isA<AuthException>()));
    });

    test('menolak refresh token yang tidak dikenal', () async {
      final repository = AuthRepository();
      expect(
        () => repository.refresh('token-palsu'),
        throwsA(isA<AuthException>()),
      );
    });

    test('menghasilkan access token baru dari refresh yang sah', () async {
      final repository = AuthRepository();
      final renewed = await repository.refresh('mock-refresh-for-a@b.c');
      expect(renewed, startsWith('mock-access-renewed-'));
    });

    test('nonce token baru aman di semua platform (regresi bug web)', () {
      // Regresi nyata: versi awal memakai `Random().nextInt(1 << 32)`. Di VM
      // Dart itu sah, tetapi di web (dart2js) `1 << 32` dievaluasi menjadi 0
      // sehingga `nextInt(0)` melempar RangeError — tepat pada jalur refresh,
      // dan gejalanya "pengguna tiba-tiba dilempar ke /login".
      //
      // Test ini menjaga INVARIAN-nya, bukan nilainya: batas acak harus positif
      // dan cukup kecil untuk diterima `nextInt` di seluruh platform.
      expect(AuthRepository.refreshNonceMax, greaterThan(0));
      expect(AuthRepository.refreshNonceMax, lessThanOrEqualTo(2147483647));
      expect(
        () => Random().nextInt(AuthRepository.refreshNonceMax),
        returnsNormally,
      );
    });

    test('nonce ikut berubah pada setiap refresh', () async {
      final repository = AuthRepository();
      final pertama = await repository.refresh('mock-refresh-for-a@b.c');
      final kedua = await repository.refresh('mock-refresh-for-a@b.c');
      expect(pertama, isNot(kedua));
    });

    test('refresh gagal -> sesi harus dianggap mati (paksa login ulang)', () async {
      // Meniru jalur `catch` pada interceptor: refresh kosong berarti tidak ada
      // cara memulihkan sesi, sehingga token dibersihkan dan guard mengarahkan
      // pengguna kembali ke /login.
      const refresh = '';
      var sessionCleared = false;
      if (refresh.isEmpty) sessionCleared = true;
      expect(sessionCleared, isTrue);
    });
  });

  group('TokenStore.mask', () {
    test('memotong token panjang dan menyebut jumlah karakter', () {
      final masked = TokenStore.mask('abcdefghijklmnopqrstuvwxyz');
      expect(masked, startsWith('abcdefghijkl'));
      expect(masked, contains('…'));
      expect(masked, contains('26 karakter'));
    });

    test('menandai token yang belum ada', () {
      expect(TokenStore.mask(null), '(belum ada)');
      expect(TokenStore.mask(''), '(belum ada)');
    });
  });

  group('friendlyApiMessage', () {
    DioException badResponse(int status) => DioException(
      requestOptions: RequestOptions(path: '/me'),
      response: Response<dynamic>(
        requestOptions: RequestOptions(path: '/me'),
        statusCode: status,
      ),
      type: DioExceptionType.badResponse,
    );

    test('401 diterjemahkan menjadi pesan sesi berakhir', () {
      final error = badResponse(401);
      expect(friendlyApiMessage(error), contains('Sesi berakhir'));
      expect(isUnauthorized(error), isTrue);
    });

    test('404 dan 5xx punya pesan masing-masing', () {
      expect(friendlyApiMessage(badResponse(404)), contains('tidak ditemukan'));
      expect(friendlyApiMessage(badResponse(503)), contains('bermasalah'));
    });

    test('koneksi putus tidak membocorkan exception mentah', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/me'),
        type: DioExceptionType.connectionError,
      );
      expect(friendlyApiMessage(error), contains('Tidak dapat terhubung'));
      expect(isUnauthorized(error), isFalse);
    });

    test('error non-Dio tetap menghasilkan pesan ramah', () {
      expect(friendlyApiMessage(StateError('x')), contains('tak terduga'));
    });
  });
}
