// Factory database untuk web (sqlite3.wasm + shared worker).
//
// Membutuhkan `web/sqlite3.wasm` dan `web/sqflite_sw.js` yang dihasilkan oleh:
//   dart run sqflite_common_ffi_web:setup

import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

Future<void> initDatabaseFactory() async {
  databaseFactory = databaseFactoryFfiWeb;
}

Future<String> databasePath(String name) async => name;
