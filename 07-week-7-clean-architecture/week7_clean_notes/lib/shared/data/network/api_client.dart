// Klien HTTP terpusat (Dio) — infrastruktur bersama.
//
// Diletakkan di `shared/` (bukan `core/`) dengan alasan tertulis:
// modul Minggu 7 mewajibkan `lib/core/` BEBAS framework (grep sterilitas
// no. 2). Karena Dio adalah framework I/O, klien HTTP masuk ke `shared/data`,
// yang hanya boleh dipakai oleh layer `data` tiap fitur.
//
// Dipakai ulang dari Minggu 4: base URL, timeout, dan logging hidup di satu
// tempat.

import 'package:dio/dio.dart';

Dio createDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://jsonplaceholder.typicode.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Accept': 'application/json'},
    ),
  );
  dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: false));
  return dio;
}
