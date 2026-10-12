// Factory database untuk target web (sqlite3.wasm + shared worker).
//
// Dipakai HANYA untuk menjalankan aplikasi di browser, misalnya saat
// dokumentasi/screenshot harus diambil tanpa emulator Android. Pada target
// utama codelab (Android) jalur ini tidak pernah dieksekusi.
//
// Membutuhkan `web/sqlite3.wasm` yang dihasilkan oleh:
//   dart run sqflite_common_ffi_web:setup
//
// Varian `NoWebWorker` dipilih agar aplikasi web bisa dijalankan cukup dengan
// static file server biasa (tanpa header COOP/COEP untuk SharedArrayBuffer).

import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

Future<void> initDatabaseFactory() async {
  databaseFactory = databaseFactoryFfiWebNoWebWorker;
}

Future<String> databasePath(String name) async => name;
