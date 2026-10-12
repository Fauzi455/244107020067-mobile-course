// IMPLEMENTASI kontrak NoteRepository (Praktikum 3, modul Minggu 7).
//
// Tanggung jawab kelas ini hanya dua:
//   1. memenuhi kontrak domain memakai datasource lokal, dan
//   2. menerjemahkan exception platform menjadi `Failure` yang ramah.
//
// Tidak ada widget, tidak ada state UI, dan tidak ada keputusan navigasi di
// sini. Implementasi ini juga tidak dipanggil langsung oleh presentation —
// hanya lewat provider DI.

import '../../../../core/failures.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../datasources/notes_local_datasource.dart';
import '../models/note_model.dart';

class NoteRepositoryImpl implements NoteRepository {
  NoteRepositoryImpl(this._local);

  final NotesLocalDataSource _local;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    try {
      final rows = await _local.selectAll();
      final notes = rows
          .map((row) => NoteModel.fromMap(row).toEntity())
          .toList();
      return (notes: notes, failure: null);
    } catch (e) {
      return (
        notes: const <Note>[],
        failure: LocalFailure('Gagal membaca catatan: $e'),
      );
    }
  }

  @override
  Future<({Note? note, Failure? failure})> fetchNoteById(int id) async {
    try {
      final row = await _local.selectById(id);
      if (row == null) return (note: null, failure: null);
      return (note: NoteModel.fromMap(row).toEntity(), failure: null);
    } catch (e) {
      return (note: null, failure: LocalFailure('Gagal memuat catatan: $e'));
    }
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    try {
      final now = DateTime.now();
      final model = NoteModel(
        title: title,
        body: body,
        updatedAt: now,
        dirty: true,
      );
      final id = await _local.insert(model.toMap());
      return (
        note: Note(
          id: id,
          title: title,
          body: body,
          updatedAt: now,
          dirty: true,
        ),
        failure: null,
      );
    } catch (e) {
      return (note: null, failure: LocalFailure('Gagal menyimpan catatan: $e'));
    }
  }

  @override
  Future<Failure?> updateNote(Note note) async {
    if (note.id == null) {
      return const LocalFailure('Catatan tanpa id tidak bisa diperbarui.');
    }
    try {
      // Perubahan lokal selalu menandai dirty agar masuk antrean sync.
      await _local.update(note.id!, {
        'title': note.title,
        'body': note.body,
        'updated_at': DateTime.now().toIso8601String(),
        'dirty': 1,
      });
      return null;
    } catch (e) {
      return LocalFailure('Gagal memperbarui catatan: $e');
    }
  }

  @override
  Future<Failure?> deleteNote(int id) async {
    try {
      await _local.delete(id);
      return null;
    } catch (e) {
      return LocalFailure('Gagal menghapus catatan: $e');
    }
  }

  @override
  Future<({int dirtyCount, Failure? failure})> countDirty() async {
    try {
      return (dirtyCount: await _local.countDirty(), failure: null);
    } catch (e) {
      return (
        dirtyCount: 0,
        failure: LocalFailure('Gagal menghitung antrean: $e'),
      );
    }
  }

  @override
  Future<({int uploaded, Failure? failure})> uploadPending() async {
    try {
      final dirty = await _local.countDirty();
      if (dirty == 0) return (uploaded: 0, failure: null);
      // Simulasi jaringan: pada project nyata, di sini Dio mengirim antrean.
      await Future<void>.delayed(const Duration(seconds: 1));
      return (uploaded: dirty, failure: null);
    } catch (e) {
      return (
        uploaded: 0,
        failure: NetworkFailure('Gagal mengirim catatan ke server: $e'),
      );
    }
  }

  @override
  Future<Failure?> markAllSynced() async {
    try {
      await _local.markAllSynced();
      return null;
    } catch (e) {
      return LocalFailure('Gagal menandai catatan tersinkron: $e');
    }
  }
}
