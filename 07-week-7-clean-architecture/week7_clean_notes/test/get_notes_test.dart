// TEST use case GetNotes dengan REPOSITORY PALSU (modul Minggu 7).
//
// Domain diuji murni: tanpa SQLite, tanpa Dio, tanpa Firebase. Yang diuji
// adalah kontrak `NoteRepository`, bukan implementasinya — inilah keuntungan
// utama menaruh interface di layer domain.

import 'package:flutter_test/flutter_test.dart';
import 'package:week7_clean_notes/core/failures.dart';
import 'package:week7_clean_notes/features/notes/domain/entities/note.dart';
import 'package:week7_clean_notes/features/notes/domain/repositories/note_repository.dart';
import 'package:week7_clean_notes/features/notes/domain/usecases/get_notes.dart';

class FakeNoteRepository implements NoteRepository {
  FakeNoteRepository({this.items = const <Note>[], this.fail = false});

  final List<Note> items;
  final bool fail;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    if (fail) {
      return (
        notes: const <Note>[],
        failure: const LocalFailure('db locked (simulasi)'),
      );
    }
    return (notes: items, failure: null);
  }

  @override
  Future<({Note? note, Failure? failure})> fetchNoteById(int id) async {
    final found = items.where((n) => n.id == id).toList();
    return (note: found.isEmpty ? null : found.first, failure: null);
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Failure?> updateNote(Note note) {
    throw UnimplementedError();
  }

  @override
  Future<Failure?> deleteNote(int id) {
    throw UnimplementedError();
  }

  @override
  Future<({int dirtyCount, Failure? failure})> countDirty() async =>
      (dirtyCount: items.where((n) => n.dirty).length, failure: null);

  @override
  Future<({int uploaded, Failure? failure})> uploadPending() async =>
      (uploaded: 0, failure: null);

  @override
  Future<Failure?> markAllSynced() async => null;
}

void main() {
  test('GetNotes meneruskan daftar dari repository', () async {
    final repo = FakeNoteRepository(
      items: [Note(title: 'A', updatedAt: DateTime(2026, 10, 13))],
    );

    final result = await GetNotes(repo).call();

    expect(result.failure, isNull);
    expect(result.notes.length, 1);
    expect(result.notes.first.title, 'A');
  });

  test('GetNotes meneruskan failure tanpa melempar', () async {
    final repo = FakeNoteRepository(fail: true);

    final result = await GetNotes(repo).call();

    expect(result.failure, isA<LocalFailure>());
    expect(result.notes, isEmpty);
  });

  test('GetNotes tidak pernah menyentuh database sungguhan', () async {
    // Bila use case diam-diam membuat koneksi SQLite, test ini akan gagal
    // karena `FakeNoteRepository` sama sekali tidak memakai sqflite.
    final repo = FakeNoteRepository(
      items: [
        Note(id: 1, title: 'Disk', updatedAt: DateTime(2026, 10, 13)),
        Note(id: 2, title: 'Hdd', updatedAt: DateTime(2026, 10, 12)),
      ],
    );

    final result = await GetNotes(repo).call();

    expect(result.notes.map((n) => n.title), ['Disk', 'Hdd']);
  });
}
