// ENTITY Note — objek bisnis murni (Praktikum 1, modul Minggu 7).
//
// Aturan yang dipegang:
//   - Tanpa import Flutter/Dio/SQLite (bisa diuji dengan `dart test` polos).
//   - TANPA method serialisasi apa pun — mapping adalah tanggung jawab model
//     (`features/notes/data/models/note_model.dart`).
//
// Field `dirty` menandai catatan yang belum tersinkron:
//   dirty = true  -> ada perubahan lokal yang belum terkirim ke server.
//   dirty = false -> catatan sudah sinkron.

class Note {
  const Note({
    this.id,
    required this.title,
    this.body = '',
    required this.updatedAt,
    this.dirty = false,
  });

  final int? id;
  final String title;
  final String body;
  final DateTime updatedAt;
  final bool dirty;

  /// Salinan dengan sebagian field diubah (dipakai dialog edit & antrean sync).
  Note copyWith({
    int? id,
    String? title,
    String? body,
    DateTime? updatedAt,
    bool? dirty,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      updatedAt: updatedAt ?? this.updatedAt,
      dirty: dirty ?? this.dirty,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Note &&
        other.id == id &&
        other.title == title &&
        other.body == body &&
        other.updatedAt == updatedAt &&
        other.dirty == dirty;
  }

  @override
  int get hashCode => Object.hash(id, title, body, updatedAt, dirty);

  @override
  String toString() => 'Note(id: $id, title: $title, dirty: $dirty)';
}
