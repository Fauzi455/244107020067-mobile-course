// Data source lokal catatan (SQLite/sqflite).
//
// Ini satu-satunya tempat di fitur notes yang berbicara SQL. Datasource
// mengembalikan baris mentah (`Map`) atau jumlah baris — pemetaan ke entity
// dilakukan oleh `NoteRepositoryImpl` lewat `NoteModel`.
//
// `openDb` disuntikkan lewat constructor supaya test bisa memakai database
// in-memory tanpa menyentuh SQLite sungguhan.

import 'package:sqflite/sqflite.dart';

import '../../../../shared/data/local/app_database.dart';

class NotesLocalDataSource {
  NotesLocalDataSource({Future<Database> Function()? openDb})
    : _openDb = openDb ?? openAppDb;

  final Future<Database> Function() _openDb;

  Future<List<Map<String, Object?>>> selectAll() async {
    final db = await _openDb();
    return db.query('notes', orderBy: 'updated_at DESC');
  }

  Future<Map<String, Object?>?> selectById(int id) async {
    final db = await _openDb();
    final rows = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<int> insert(Map<String, Object?> values) async {
    final db = await _openDb();
    return db.insert('notes', values);
  }

  Future<int> update(int id, Map<String, Object?> values) async {
    final db = await _openDb();
    return db.update('notes', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(int id) async {
    final db = await _openDb();
    return db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> countDirty() async {
    final db = await _openDb();
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM notes WHERE dirty = 1',
    );
    return (rows.first['c'] as num?)?.toInt() ?? 0;
  }

  Future<int> markAllSynced() async {
    final db = await _openDb();
    return db.update('notes', {'dirty': 0}, where: 'dirty = 1');
  }
}
