// Klien HTTP terpusat (Dio) untuk fitur cache-first read.
//
// Dipakai kembali dari Minggu 4: base URL, timeout, dan logging hidup di satu
// tempat. Hanya baca (`GET /posts`) yang dipakai di minggu ini.

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
  dio.interceptors.add(
    LogInterceptor(requestBody: true, responseBody: false),
  );
  return dio;
}
