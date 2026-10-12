// KONTRAK repository catatan — tinggal di `domain` (Praktikum 2).
//
// Interface ada di domain karena domain-lah yang "membutuhkan" operasi ini;
// layer `data` hanya menyediakan cara memenuhinya. Kalau interface ditaruh di
// `data`, maka domain harus mengimpor data -> arah panah dependensi terbalik
// dan logika bisnis tidak lagi bisa diuji tanpa SQLite.
//
// Semua method mengembalikan *record* Dart `({hasil, Failure? failure})`
// supaya sukses/gagal eksplisit dan exception tidak bocor ke presentation.
//
// Perhatikan: tidak ada method serialisasi di sini. Domain hanya berbicara
// dengan entity `Note`, bukan representasi baris database.

import '../../../../core/failures.dart';
import '../entities/note.dart';

abstract class NoteRepository {
  /// Semua catatan, terbaru di atas (`updated_at DESC`).
  Future<({List<Note> notes, Failure? failure})> fetchNotes();

  /// Satu catatan berdasarkan id (dipakai rute `/note/:id`).
  Future<({Note? note, Failure? failure})> fetchNoteById(int id);

  /// Tambah catatan baru; implementasi menandai `dirty = true`.
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body,
  });

  /// Perbarui catatan; selalu menandai `dirty = true` (masuk antrean sync).
  Future<Failure?> updateNote(Note note);

  /// Hapus catatan permanen dari perangkat.
  Future<Failure?> deleteNote(int id);

  /// Jumlah catatan yang belum tersinkron (badge antrean sync).
  Future<({int dirtyCount, Failure? failure})> countDirty();

  /// Kirim antrean perubahan ke "server".
  ///
  /// Codelab ini belum punya backend tulis, jadi implementasi menyimulasikan
  /// proses upload. Yang dinilai adalah kontraknya: mengembalikan jumlah
  /// catatan yang berhasil dikirim.
  Future<({int uploaded, Failure? failure})> uploadPending();

  /// Tandai semua catatan kotor sebagai tersinkron.
  /// HANYA dipanggil setelah `uploadPending()` sukses.
  Future<Failure?> markAllSynced();
}
