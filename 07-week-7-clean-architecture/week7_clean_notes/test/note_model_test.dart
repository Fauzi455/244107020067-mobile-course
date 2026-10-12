// TEST model NoteModel (layer data).
//
// Membuktikan mapping HANYA hidup di model: entity `Note` tidak punya
// `toMap/fromMap`, sedangkan `NoteModel` mengonversi baris database yang
// tidak lengkap tanpa crash (`type 'Null' is not a subtype`).

import 'package:flutter_test/flutter_test.dart';
import 'package:week7_clean_notes/features/notes/data/models/note_model.dart';
import 'package:week7_clean_notes/features/notes/domain/entities/note.dart';

void main() {
  group('NoteModel.fromMap', () {
    test('aman terhadap field yang hilang', () {
      final note = NoteModel.fromMap({'title': 'Belanja'});

      expect(note.title, 'Belanja');
      expect(note.body, '');
      expect(note.dirty, isFalse);
      expect(note.id, isNull);
    });

    test('flag dirty bertahan pada serialisasi', () {
      final model = NoteModel(
        title: 'a',
        updatedAt: DateTime(2026, 10, 13),
        dirty: true,
      );

      final restored = NoteModel.fromMap(model.toMap());

      expect(restored.dirty, isTrue);
      expect(restored.updatedAt, DateTime(2026, 10, 13));
    });

    test('dirty=0 pada map dibaca sebagai false (edge case)', () {
      final note = NoteModel.fromMap({
        'id': 3,
        'title': 'x',
        'body': 'y',
        'updated_at': '2026-10-13T10:00:00.000',
        'dirty': 0,
      });

      expect(note.id, 3);
      expect(note.dirty, isFalse);
    });
  });

  test('toEntity() menghasilkan entity murni dengan nilai yang sama', () {
    final model = NoteModel(
      id: 7,
      title: 'Refactor',
      body: 'Pisahkan layer',
      updatedAt: DateTime(2026, 10, 13, 9, 30),
      dirty: true,
    );

    final Note entity = model.toEntity();

    expect(entity.id, 7);
    expect(entity.title, 'Refactor');
    expect(entity.body, 'Pisahkan layer');
    expect(entity.updatedAt, DateTime(2026, 10, 13, 9, 30));
    expect(entity.dirty, isTrue);
    expect(entity, isA<Note>());
  });

  test('fromEntity() menyalin seluruh field', () {
    final model = NoteModel.fromEntity(
      Note(
        id: 1,
        title: 'a',
        body: 'b',
        updatedAt: DateTime(2026, 1, 2),
        dirty: true,
      ),
    );

    expect(model.toMap()['dirty'], 1);
    expect(model.toMap()['updated_at'], DateTime(2026, 1, 2).toIso8601String());
  });
}
