// Unit test logika offline-first (syncNotes) dengan repository palsu.
//
// Membuktikan:
//   - catatan bersih tidak memicu sync,
//   - catatan kotor ditandai bersih setelah sync sukses,
//   - mode offline melempar SyncOfflineException TANPA menandai bersih.

import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/data/repositories/note_repository.dart';
import 'package:week5_offline_notes/data/sync.dart';

class FakeNoteRepository extends NoteRepository {
  FakeNoteRepository(this.items)
      : super(openDb: () => throw UnimplementedError());

  final List<Note> items;
  int markAllSyncedCalls = 0;

  @override
  Future<int> countDirty() async =>
      items.where((n) => n.dirty).length;

  @override
  Future<void> markAllSynced() async {
    markAllSyncedCalls++;
    for (var i = 0; i < items.length; i++) {
      items[i] = items[i].copyWith(dirty: false);
    }
  }
}

void main() {
  Note dirtyNote(String title) => Note(
        title: title,
        updatedAt: DateTime.now(),
        dirty: true,
      );

  test('tidak melakukan apa-apa bila tidak ada catatan kotor', () async {
    final repo = FakeNoteRepository([dirtyNote('a').copyWith(dirty: false)]);
    final count = await syncNotes(repo);
    expect(count, 0);
    expect(repo.markAllSyncedCalls, 0);
  });

  test('menandai bersih setelah sync sukses', () async {
    final repo = FakeNoteRepository([dirtyNote('a'), dirtyNote('b')]);
    final count = await syncNotes(repo);
    expect(count, 2);
    expect(repo.markAllSyncedCalls, 1);
    expect(await repo.countDirty(), 0);
  });

  test('mode offline melempar tanpa menandai bersih', () async {
    final repo = FakeNoteRepository([dirtyNote('a')]);
    await expectLater(
      syncNotes(repo, forceOffline: true),
      throwsA(isA<SyncOfflineException>()),
    );
    expect(repo.markAllSyncedCalls, 0);
    expect(await repo.countDirty(), 1);
  });
}
