// TEST use case SyncNotes dengan repository palsu.
//
// Membuktikan aturan bisnis antrean sinkronisasi:
//   - catatan bersih -> tidak menyentuh server sama sekali,
//   - catatan kotor -> upload dulu, baru tandai bersih,
//   - mode offline   -> OfflineFailure tanpa menandai bersih,
//   - upload gagal   -> catatan tetap kotor (tidak ada data yang "hilang").

import 'package:flutter_test/flutter_test.dart';
import 'package:week7_clean_notes/core/failures.dart';
import 'package:week7_clean_notes/features/notes/domain/entities/note.dart';
import 'package:week7_clean_notes/features/notes/domain/repositories/note_repository.dart';
import 'package:week7_clean_notes/features/notes/domain/usecases/sync_notes.dart';

class FakeNoteRepository implements NoteRepository {
  FakeNoteRepository(this.items, {this.uploadFailure});

  final List<Note> items;
  final Failure? uploadFailure;

  int uploadCalls = 0;
  int markAllSyncedCalls = 0;

  @override
  Future<({int dirtyCount, Failure? failure})> countDirty() async =>
      (dirtyCount: items.where((n) => n.dirty).length, failure: null);

  @override
  Future<({int uploaded, Failure? failure})> uploadPending() async {
    uploadCalls++;
    if (uploadFailure != null) {
      return (uploaded: 0, failure: uploadFailure);
    }
    return (uploaded: items.where((n) => n.dirty).length, failure: null);
  }

  @override
  Future<Failure?> markAllSynced() async {
    markAllSyncedCalls++;
    for (var i = 0; i < items.length; i++) {
      items[i] = items[i].copyWith(dirty: false);
    }
    return null;
  }

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() {
    throw UnimplementedError();
  }

  @override
  Future<({Note? note, Failure? failure})> fetchNoteById(int id) {
    throw UnimplementedError();
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
}

Note dirtyNote(String title) =>
    Note(title: title, updatedAt: DateTime(2026, 10, 13), dirty: true);

void main() {
  test('tidak melakukan apa-apa bila tidak ada catatan kotor', () async {
    final repo = FakeNoteRepository([dirtyNote('a').copyWith(dirty: false)]);

    final result = await SyncNotes(repo).call();

    expect(result.synced, 0);
    expect(result.failure, isNull);
    expect(repo.uploadCalls, 0);
    expect(repo.markAllSyncedCalls, 0);
  });

  test('menandai bersih setelah upload sukses', () async {
    final repo = FakeNoteRepository([dirtyNote('a'), dirtyNote('b')]);

    final result = await SyncNotes(repo).call();

    expect(result.synced, 2);
    expect(result.failure, isNull);
    expect(repo.uploadCalls, 1);
    expect(repo.markAllSyncedCalls, 1);
    expect((await repo.countDirty()).dirtyCount, 0);
  });

  test('mode offline menolak tanpa menyentuh server', () async {
    final repo = FakeNoteRepository([dirtyNote('a')]);

    final result = await SyncNotes(repo).call(forceOffline: true);

    expect(result.failure, isA<OfflineFailure>());
    expect(result.synced, 0);
    expect(repo.uploadCalls, 0);
    expect(repo.markAllSyncedCalls, 0);
    expect((await repo.countDirty()).dirtyCount, 1);
  });

  test(
    'upload gagal -> catatan tetap kotor (tidak hilang dari antrean)',
    () async {
      final repo = FakeNoteRepository([
        dirtyNote('a'),
      ], uploadFailure: const NetworkFailure('server tidak merespons'));

      final result = await SyncNotes(repo).call();

      expect(result.failure, isA<NetworkFailure>());
      expect(repo.markAllSyncedCalls, 0);
      expect((await repo.countDirty()).dirtyCount, 1);
    },
  );
}
