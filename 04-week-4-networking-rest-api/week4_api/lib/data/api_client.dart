// Konfigurasi Dio terpusat untuk seluruh aplikasi.
//
// Seluruh konfigurasi jaringan (base URL, timeout, logging) hidup di satu
// tempat sehingga mudah diubah dan diuji. Ini juga menjadi fondasi mock API
// di Minggu 12: test cukup meng-override `dioProvider`.
//
// Mengapa Dio, bukan package http?
// Dio memberi timeout per-request, interceptor (logging/auth header), dan
// error terstruktur (`DioException` dengan `type`) tanpa boilerplate tambahan.

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
