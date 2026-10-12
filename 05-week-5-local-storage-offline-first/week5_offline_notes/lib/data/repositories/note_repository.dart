// Repository sebagai satu-satunya pintu ke database catatan.
//
// Aturan arsitektur minggu 5 sama seperti minggu 4, hanya sumber datanya
// berubah menjadi SQLite lokal:
//   - UI tidak boleh memanggil sqflite secara langsung.
//   - Repository mengubah exception platform menjadi kegagalan bermakna.
//
// Constructor menerima `openDb` yang bisa disuntik (dependency injection).
// Tujuannya agar test bisa memakai database palsu/in-memory tanpa menyentuh
// SQLite sungguhan (pola ini dipakai lagi di Minggu 12 - Testing & QA).

import 'package:sqflite/sqflite.dart';

import '../local/db.dart';
import '../local/note.dart';

class NoteRepository {
  NoteRepository({Future<Database> Function()? openDb})
      : _openDb = openDb ?? openNotesDb;

  final Future<Database> Function() _openDb;

  /// Semua catatan, terbaru di atas (urut `updated_at DESC`).
  Future<List<Note>> fetchNotes() async {
    final db = await _openDb();
    final rows = await db.query('notes', orderBy: 'updated_at DESC');
    return rows.map(Note.fromMap).toList();
  }

  /// Satu catatan berdasarkan id (dipakai halaman detail `/note/:id`).
  Future<Note?> fetchNoteById(int id) async {
    final db = await _openDb();
    final rows = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Note.fromMap(rows.first);
  }

  Future<Note> addNote({required String title, String body = ''}) async {
    final db = await _openDb();
    final note = Note(
      title: title,
      body: body,
      updatedAt: DateTime.now(),
      dirty: true,
    );
    final id = await db.insert('notes', note.toMap());
    return Note(
      id: id,
      title: note.title,
      body: note.body,
      updatedAt: note.updatedAt,
      dirty: true,
    );
  }

  /// Perbarui catatan. Perubahan lokal selalu menandai `dirty = 1` agar
  /// masuk antrean sinkronisasi.
  Future<void> updateNote(Note note) async {
    if (note.id == null) return;
    final db = await _openDb();
    await db.update(
      'notes',
      {
        'title': note.title,
        'body': note.body,
        'updated_at': DateTime.now().toIso8601String(),
        'dirty': 1,
      },
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<void> deleteNote(int id) async {
    final db = await _openDb();
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  /// Jumlah catatan yang belum tersinkron (untuk badge antrean sync).
  Future<int> countDirty() async {
    final db = await _openDb();
    final rows = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM notes WHERE dirty = 1');
    return (rows.first['c'] as num?)?.toInt() ?? 0;
  }

  /// Tandai semua catatan kotor sebagai sudah sinkron.
  /// Dipanggil HANYA setelah "server" menjawab sukses.
  Future<void> markAllSynced() async {
    final db = await _openDb();
    await db.update('notes', {'dirty': 0}, where: 'dirty = 1');
  }
}
