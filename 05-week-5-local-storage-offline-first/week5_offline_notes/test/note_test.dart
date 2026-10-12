// Unit test model Note + provider dengan repository palsu
// (tanpa SQLite sungguhan). Mengikuti contoh pada modul Minggu 5.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/data/providers.dart';
import 'package:week5_offline_notes/data/repositories/note_repository.dart';

class FakeNoteRepository extends NoteRepository {
  FakeNoteRepository({this.items = const [], this.throwError = false})
      : super(openDb: () => throw UnimplementedError());

  final List<Note> items;
  final bool throwError;

  @override
  Future<List<Note>> fetchNotes() async {
    if (throwError) throw Exception('db locked (simulasi)');
    return items;
  }

  @override
  Future<int> countDirty() =>
      Future.value(items.where((n) => n.dirty).length);
}

void main() {
  group('Note.fromMap', () {
    test('aman terhadap field yang hilang', () {
      final note = Note.fromMap({'title': 'Belanja'});
      expect(note.title, 'Belanja');
      expect(note.body, '');
      expect(note.dirty, isFalse);
      expect(note.id, isNull);
    });

    test('flag dirty bertahan pada serialisasi', () {
      final note = Note(
        title: 'a',
        updatedAt: DateTime(2026, 9, 18),
        dirty: true,
      );
      final restored = Note.fromMap(note.toMap());
      expect(restored.dirty, isTrue);
      expect(restored.updatedAt, DateTime(2026, 9, 18));
    });

    test('dirty=0 pada map dibaca sebagai false (edge case)', () {
      final note = Note.fromMap({
        'id': 3,
        'title': 'x',
        'body': 'y',
        'updated_at': '2026-09-18T10:00:00.000',
        'dirty': 0,
      });
      expect(note.id, 3);
      expect(note.dirty, isFalse);
    });
  });

  group('notesProvider', () {
    test('sukses dengan repository palsu', () async {
      final container = ProviderContainer(
        overrides: [
          noteRepositoryProvider.overrideWithValue(
            FakeNoteRepository(items: [
              Note(title: 'Tes', updatedAt: DateTime.now()),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);
      final notes = await container.read(notesProvider.future);
      expect(notes.length, 1);
      expect(notes.first.title, 'Tes');
    });

    test('error dengan repository palsu', () async {
      final container = ProviderContainer(
        overrides: [
          noteRepositoryProvider.overrideWithValue(
            FakeNoteRepository(throwError: true),
          ),
        ],
      );
      addTearDown(container.dispose);
      await expectLater(
        container.read(notesProvider.future),
        throwsA(isA<Exception>()),
      );
    });
  });
}
