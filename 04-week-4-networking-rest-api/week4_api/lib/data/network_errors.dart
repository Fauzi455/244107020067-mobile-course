// Pemetaan error jaringan -> pesan ramah pengguna.
//
// Dipindahkan ke file tersendiri (Refactoring Challenge no. 2) supaya
// `friendlyErrorMessage` bisa dipakai ulang oleh halaman paged, halaman
// daftar non-paged, maupun halaman detail tanpa duplikasi kode.
//
// Aturan: UI TIDAK PERNAH menampilkan pesan teknis mentah (mis. string
// `DioException`) ke pengguna. Semua jenis kegagalan jaringan diterjemahkan
// di sini menjadi satu kalimat yang bisa dimengerti pengguna awam.

import 'package:dio/dio.dart';

String friendlyErrorMessage(Object error) {
  if (error is DioException) {
    switch (error.type) {
      // Timeout: koneksi lambat / server tidak menjawab tepat waktu.
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi lambat atau timeout. Periksa internet Anda lalu coba lagi.';

      // Tidak bisa membuka koneksi sama sekali (mode pesawat, DNS gagal).
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Periksa internet Anda.';

      // Server membalas dengan status code 4xx/5xx.
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        if (code == 404) return 'Data tidak ditemukan (404).';
        if (code == 401 || code == 403) {
          return 'Akses ditolak ($code). Periksa kredensial Anda.';
        }
        if (code != null && code >= 500) {
          return 'Server bermasalah ($code). Coba lagi nanti.';
        }
        return 'Permintaan ditolak ($code). Coba lagi.';

      // Sisanya (cancel, badCertificate, unknown, dll).
      default:
        return 'Terjadi kesalahan jaringan. Coba lagi.';
    }
  }
  return 'Terjadi kesalahan tak terduga: $error';
}
