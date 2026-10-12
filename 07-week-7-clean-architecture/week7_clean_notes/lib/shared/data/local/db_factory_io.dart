// Factory database untuk platform native (Android/iOS) dan desktop.
//
// Android/iOS memakai sqflite native (factory default sudah benar).
// Desktop memakai sqflite_common_ffi karena sqflite tidak menyediakan
// implementasi desktop.

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> initDatabaseFactory() async {
  if (defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS) {
    // sqflite native sudah menjadi factory default.
    return;
  }
  // Windows / Linux / macOS -> gunakan FFI.
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

Future<String> databasePath(String name) async {
  final dir = await getDatabasesPath();
  return p.join(dir, name);
}
