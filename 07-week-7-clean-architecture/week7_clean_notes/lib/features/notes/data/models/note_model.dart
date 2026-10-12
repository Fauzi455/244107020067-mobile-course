// MODEL NoteModel — representasi data luar + mapping (Praktikum 3).
//
// Model hidup di layer `data` karena hanya data yang tahu bentuk penyimpanan
// (`updated_at`, `dirty` sebagai 0/1, dst). Model memperluas entity `Note`
// agar bisa langsung dipakai sebagai entity, lalu `.toEntity()` dipakai di
// batas data -> domain.
//
// `fromMap` dibuat aman null karena baris database bisa saja tidak lengkap
// (skema lama, kolom baru, dsb). Cast defensif mencegah crash
// `type 'Null' is not a subtype`.

import '../../domain/entities/note.dart';

class NoteModel extends Note {
  const NoteModel({
    super.id,
    required super.title,
    super.body = '',
    required super.updatedAt,
    super.dirty = false,
  });

  factory NoteModel.fromEntity(Note note) {
    return NoteModel(
      id: note.id,
      title: note.title,
      body: note.body,
      updatedAt: note.updatedAt,
      dirty: note.dirty,
    );
  }

  factory NoteModel.fromMap(Map<String, Object?> map) {
    return NoteModel(
      id: (map['id'] as num?)?.toInt(),
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      updatedAt:
          DateTime.tryParse(map['updated_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      dirty: ((map['dirty'] as num?)?.toInt() ?? 0) == 1,
    );
  }

  /// Mapping HANYA ada di model, tidak pernah di entity.
  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'body': body,
    'updated_at': updatedAt.toIso8601String(),
    'dirty': dirty ? 1 : 0,
  };

  /// Konversi di batas data -> domain.
  Note toEntity() => Note(
    id: id,
    title: title,
    body: body,
    updatedAt: updatedAt,
    dirty: dirty,
  );
}
