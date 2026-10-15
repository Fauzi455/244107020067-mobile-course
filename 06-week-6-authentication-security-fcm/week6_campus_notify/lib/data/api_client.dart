// Klien HTTP Dio dengan **refresh otomatis satu kali** saat menerima 401.
//
// Alur yang diimplementasikan (sesuai modul Minggu 6):
//
//   request --Bearer access--> 401?
//     ya  -> tukar refresh token -> simpan access baru
//         -> ulangi request SEKALI dengan access baru
//     tidak -> teruskan
//   refresh ikut mati -> bersihkan sesi -> pengguna dipaksa login ulang
//
// Base URL diarahkan ke mock campus API (`tool/mock_api_server.js`). Server itu
// menerbitkan 401 sungguhan untuk access token yang kedaluwarsa, sehingga
// jalur refresh benar-benar teruji, bukan hanya dibaca dari kode.

import 'package:dio/dio.dart';

import 'api_log.dart';
import 'auth_repository.dart';
import 'token_store.dart';

/// Bisa ditimpa saat build: `flutter build web --dart-define=API_BASE_URL=...`
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8787',
);

/// Kunci internal pada `RequestOptions.extra` untuk mencegah retry beruntun.
const String _retriedFlag = 'campus_notify_retried';

Dio buildApiClient({
  required TokenStore store,
  required AuthRepository auth,
  required void Function(ApiLogEntry entry) log,
  /// Dipanggil saat sesi tidak bisa diselamatkan lagi (refresh token hilang
  /// atau ikut kedaluwarsa). Pemakainya (lihat `providers.dart`) membatalkan
  /// state autentikasi supaya guard GoRouter mengembalikan pengguna ke
  /// `/login` — tanpa ini token sudah dihapus tetapi UI masih diam di beranda.
  void Function()? onSessionExpired,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: kApiBaseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      // Biarkan Dio melempar untuk semua status >= 400 supaya jalur onError
      // bisa menangani 401 secara seragam.
      validateStatus: (code) => code != null && code < 400,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final access = await store.readAccess();
        if (access != null) {
          options.headers['Authorization'] = 'Bearer $access';
        }
        // Status autentikasi ikut dicatat: kalau baris ini tidak diawali
        // "Bearer", berarti permintaan berangkat TANPA token dan 401 yang
        // muncul bukan soal kedaluwarsa.
        log(
          ApiLogEntry(
            '→ ${options.method} ${options.path} '
            '${access == null ? '(TANPA token)' : '(Bearer …${access.length})'}',
          ),
        );
        handler.next(options);
      },

      onResponse: (response, handler) {
        log(
          ApiLogEntry(
            '← ${response.statusCode} ${response.requestOptions.path}',
          ),
        );
        handler.next(response);
      },

      onError: (error, handler) async {
        final options = error.requestOptions;
        final status = error.response?.statusCode;
        final alreadyRetried = options.extra[_retriedFlag] == true;

        if (status != 401 || alreadyRetried) {
          if (status != null) {
            log(
              ApiLogEntry(
                '← $status ${options.path}',
                ok: false,
              ),
            );
          }
          return handler.next(error);
        }

        final refresh = await store.readRefresh();
        if (refresh == null) {
          log(
            const ApiLogEntry(
              '401 tanpa refresh token → sesi dibersihkan, paksa login ulang',
              ok: false,
            ),
          );
          await _endSession(store, onSessionExpired);
          return handler.next(error);
        }

        try {
          log(
            const ApiLogEntry(
              '401 kedaluwarsa → menukar refresh token (sekali saja)',
              ok: false,
            ),
          );
          final renewed = await auth.refresh(refresh);
          await store.saveAccess(renewed);

          // Tandai supaya 401 kedua tidak memicu loop tak berujung.
          options.extra[_retriedFlag] = true;
          options.headers['Authorization'] = 'Bearer $renewed';

          final retry = await dio.fetch<dynamic>(options);
          log(
            ApiLogEntry(
              'ulang ${options.method} ${options.path} → ${retry.statusCode}',
            ),
          );
          return handler.resolve(retry);
        } catch (refreshError) {
          // Refresh ikut kedaluwarsa: sesi tidak bisa diselamatkan. Alasannya
          // ikut dicatat karena inilah kegagalan yang paling mahal — kalau
          // penyebabnya tidak terlihat di log, "notifikasi berhenti diam-diam"
          // sangat sulit dilacak.
          await _endSession(store, onSessionExpired);
          log(
            ApiLogEntry(
              'refresh ikut kedaluwarsa ($refreshError) → sesi dibersihkan, '
              'paksa login ulang',
              ok: false,
            ),
          );
          return handler.next(error);
        }
      },
    ),
  );

  return dio;
}

/// Membersihkan sesi lalu memberi tahu lapisan atas agar guard route
/// mengembalikan pengguna ke halaman login.
Future<void> _endSession(
  TokenStore store,
  void Function()? onSessionExpired,
) async {
  await store.clear();
  onSessionExpired?.call();
}
