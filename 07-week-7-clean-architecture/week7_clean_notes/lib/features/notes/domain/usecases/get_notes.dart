// USE CASE GetNotes (Praktikum 4, modul Minggu 7).
//
// Satu operasi bisnis: "ambil daftar catatan". Presentation hanya boleh
// memanggil use case ini, tidak pernah `NoteRepositoryImpl` atau sqflite.
//
// Use case ini juga yang diuji di `test/get_notes_test.dart` memakai
// repository palsu — tanpa SQLite, tanpa Dio, tanpa Firebase.

import '../../../../core/failures.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';

class GetNotes {
  const GetNotes(this._repository);

  final NoteRepository _repository;

  Future<({List<Note> notes, Failure? failure})> call() {
    return _repository.fetchNotes();
  }
}
