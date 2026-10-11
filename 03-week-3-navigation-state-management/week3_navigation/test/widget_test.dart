// Widget test untuk Praktikum 1: memastikan UI bereaksi terhadap
// navigasi GoRouter. Dua skenario diuji:
// 1. Home page tampil dengan 10 item dan tidak ada detail.
// 2. Mengetuk "Item 3" memindah ke detail, UI menampilkan
//    teks berisi id-nya (bukti path parameter ":id" berfungsi).
import 'package:flutter_test/flutter_test.dart';
import 'package:week3_navigation/main.dart';

void main() {
  testWidgets('home menampilkan daftar 10 item', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    for (var i = 1; i <= 10; i++) {
      expect(find.text('Item $i'), findsOneWidget);
    }
    expect(find.textContaining('Anda membuka item'), findsNothing);
  });

  testWidgets('mengetuk Item 3 membuka halaman detail id 3', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Item 3'));
    await tester.pumpAndSettle();

    expect(find.text('Detail 3'), findsOneWidget);
    expect(find.text('Anda membuka item dengan id: 3'), findsOneWidget);
  });
}
