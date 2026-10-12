// Pembuka database SQLite terpusat — infrastruktur bersama.
//
// Satu fungsi `openAppDb()` dipakai dua fitur (notes & posts) sehingga skema
// hanya didefinisikan sekali. Berada di `shared/data` karena memakai sqflite
// (framework), sedangkan `core/` wajib murni Dart.
//
// Catatan lintas platform: sqflite native hanya berjalan di Android/iOS. Agar
// demo/screenshot bisa dilakukan di browser, factory database dipilih lewat
// conditional import:
//   - Android/iOS  -> sqflite native (default)
//   - Desktop      -> sqflite_common_ffi
//   - Web          -> sqflite_common_ffi_web (sqlite3.wasm)
// Target utama codelab tetap Android; web hanya dipakai untuk dokumentasi.

import 'package:sqflite/sqflite.dart';

import 'db_factory_stub.dart'
    if (dart.library.io) 'db_factory_io.dart'
    if (dart.library.js_interop) 'db_factory_web.dart'
    as platform;

const String appDbFileName = 'clean_notes.db';

Future<Database> openAppDb() async {
  await platform.initDatabaseFactory();
  final path = await platform.databasePath(appDbFileName);
  return openDatabase(
    path,
    version: 1,
    onCreate: _onCreate,
    onUpgrade: _onUpgrade,
  );
}

Future<void> _onCreate(Database db, int version) async {
  await db.execute('''
    CREATE TABLE notes(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      body TEXT NOT NULL DEFAULT '',
      updated_at TEXT NOT NULL,
      dirty INTEGER NOT NULL DEFAULT 0
    )
  ''');
  await db.execute('''
    CREATE TABLE cached_posts(
      id INTEGER PRIMARY KEY,
      payload TEXT NOT NULL,
      cached_at TEXT NOT NULL
    )
  ''');
}

// Titik masuk migrasi skema untuk versi berikutnya.
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  // Contoh: if (oldVersion < 2) { await db.execute('ALTER TABLE ...'); }
}
