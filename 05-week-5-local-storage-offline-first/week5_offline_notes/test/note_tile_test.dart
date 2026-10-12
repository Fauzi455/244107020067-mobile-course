// Widget test untuk `NoteTile` (Refactoring Challenge no. 1).
//
// Membuktikan badge "Belum tersinkron" muncul tepat saat `dirty == true`,
// dan `onTap` dipanggil saat baris diketuk.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/widgets/note_tile.dart';

void main() {
  Note note({bool dirty = false}) => Note(
        id: 1,
        title: 'Belanja',
        body: 'Beli sayur dan buah',
        updatedAt: DateTime(2026, 9, 18, 10, 30),
        dirty: dirty,
      );

  testWidgets('menampilkan judul, isi, dan tanpa badge saat sudah sinkron',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: NoteTile(note: note()))),
    );
    expect(find.text('Belanja'), findsOneWidget);
    expect(find.text('Beli sayur dan buah'), findsOneWidget);
    expect(find.text('Belum tersinkron'), findsNothing);
  });

  testWidgets('menampilkan badge saat dirty', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: NoteTile(note: note(dirty: true)))),
    );
    expect(find.text('Belum tersinkron'), findsOneWidget);
  });

  testWidgets('memanggil onTap saat diketuk', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteTile(note: note(), onTap: () => tapped = true),
        ),
      ),
    );
    await tester.tap(find.byType(NoteTile));
    expect(tapped, isTrue);
  });
}
