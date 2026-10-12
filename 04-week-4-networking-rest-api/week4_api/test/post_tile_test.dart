// Widget test untuk `PostTile` (Refactoring Challenge no. 1).
//
// Membuktikan widget hasil ekstraksi tetap menampilkan data dengan benar
// dan memanggil `onTap` saat diketuk.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/models/post.dart';
import 'package:week4_api/widgets/post_tile.dart';

void main() {
  testWidgets('PostTile menampilkan id, judul, dan isi post',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PostTile(
            post: Post(userId: 1, id: 5, title: 'Judul Post', body: 'Isi post'),
          ),
        ),
      ),
    );

    expect(find.text('5'), findsOneWidget);
    expect(find.text('Judul Post'), findsOneWidget);
    expect(find.text('Isi post'), findsOneWidget);
  });

  testWidgets('PostTile memanggil onTap saat diketuk', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PostTile(
            post: const Post(userId: 1, id: 1, title: 'A', body: 'B'),
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(PostTile));
    expect(tapped, isTrue);
  });
}
