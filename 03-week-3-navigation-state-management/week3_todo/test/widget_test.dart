// Widget test yang diminta codelab: memastikan UI bereaksi
// terhadap perubahan state provider.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week3_todo/main.dart';
import 'package:week3_todo/providers/todo_provider.dart';
import 'package:week3_todo/pages/stats_page.dart';

void main() {
  testWidgets('menambah tugas baru', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    expect(find.text('Belum ada tugas'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Kerjakan PR minggu 3');
    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();

    // Dialog menutup: teks muncul tepat sekali, di list.
    // (findsOneWidget, bukan findsWidgets, karena dialog sudah tutup.)
    expect(find.text('Kerjakan PR minggu 3'), findsOneWidget);
  });

  testWidgets('toggle dan hapus tugas', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const ProviderScope(child: MyApp()),
      ),
    );

    // Tambah dua tugas.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Tugas A');
    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Tugas B');
    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();

    // Tandai tugas pertama selesai lewat checkbox.
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    expect(
      container.read(todoListProvider).first.done,
      isTrue,
      reason: 'tugas pertama seharusnya jadi selesai',
    );

    // Hapus tugas terakhir lewat tombol delete.
    final deleteButtons = find.byIcon(Icons.delete);
    await tester.tap(deleteButtons.last);
    await tester.pumpAndSettle();
    expect(container.read(todoListProvider).length, 1);
    expect(find.text('Tugas B'), findsNothing);
  });

  group('halaman statistik (AsyncValue)', () {
    // Test fase-fase AsyncValue secara deterministik:
    // loading -> data (forceFail = false) dan error -> coba lagi.
    testWidgets(
        'menampilkan loading lalu data setelah 2 detik simulasi network',
        (tester) async {
      StatsNotifier.forceFail = false;
      addTearDown(() => StatsNotifier.forceFail = null);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: StatsPage()),
        ),
      );

      // Fase loading: spinner tampil.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Skip 2 detik simulasi network, lalu data muncul.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('Total tugas'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);
      expect(find.text('Belum selesai'), findsOneWidget);
    });

    testWidgets('menampilkan error dengan tombol coba lagi saat fetch gagal',
        (tester) async {
      StatsNotifier.forceFail = true;
      addTearDown(() => StatsNotifier.forceFail = null);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: StatsPage()),
        ),
      );

      // Gagal setelah delay: pesan error + tombol "Coba lagi" tampil.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.textContaining('Gagal terhubung'), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);

      // Pulihkan fetch dan klik "Coba lagi": refresh -> data.
      StatsNotifier.forceFail = false;
      await tester.tap(find.text('Coba lagi'));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('Total tugas'), findsOneWidget);
    });
  });

  testWidgets('pindah ke halaman statistik lewat NavigationBar',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // Ketuk tab Statistik di NavigationBar (label "Statistik").
    await tester.tap(find.text('Statistik'));
    await tester.pumpAndSettle();

    // Halaman stats tampil: AppBar-nya juga bertuliskan "Statistik",
    // jadi ada dua. Cukup pastikan heading data/loading muncul --
    // cek lewat tombol aksi "Ke daftar tugas" yang hanya ada di stats.
    expect(find.byTooltip('Ke daftar tugas'), findsOneWidget);
  });
}
