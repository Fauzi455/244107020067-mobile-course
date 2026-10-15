// Pemetaan DioException -> pesan ramah pengguna (Refactoring Challenge 3).
//
// Lapisan UI hanya boleh menerima **pesan siap tampil**, bukan exception
// mentah. Kalau `DioException` bocor ke widget, setiap halaman akan menulis
// terjemahannya sendiri-sendiri dan teksnya cepat tidak konsisten.
//
// Fungsi ini murni (tidak menyentuh Dio runtime) sehingga bisa diuji tanpa
// jaringan.

import 'package:dio/dio.dart';

String friendlyApiMessage(Object error) {
  if (error is! DioException) {
    return 'Terjadi kesalahan tak terduga.';
  }

  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return 'Koneksi ke server lambat atau tidak merespons. Coba lagi.';
    case DioExceptionType.connectionError:
      return 'Tidak dapat terhubung ke server kampus. Periksa jaringan Anda.';
    case DioExceptionType.badCertificate:
      return 'Sertifikat server tidak valid — koneksi dihentikan.';
    case DioExceptionType.cancel:
      return 'Permintaan dibatalkan.';
    case DioExceptionType.badResponse:
      final code = error.response?.statusCode ?? 0;
      if (code == 401) return 'Sesi berakhir. Silakan masuk kembali.';
      if (code == 403) return 'Anda tidak punya akses ke data ini.';
      if (code == 404) return 'Data tidak ditemukan.';
      if (code >= 500) return 'Server kampus sedang bermasalah. Coba lagi nanti.';
      return 'Permintaan ditolak (HTTP $code).';
    case DioExceptionType.unknown:
      return 'Terjadi kesalahan tak terduga saat menghubungi server.';
  }
}

/// Dipakai halaman untuk memutuskan apakah pengguna harus diarahkan ke login.
bool isUnauthorized(Object error) =>
    error is DioException && error.response?.statusCode == 401;
