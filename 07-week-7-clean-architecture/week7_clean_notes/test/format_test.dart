// TEST fungsi murni di `lib/core/format.dart`.
//
// Karena formatting dipindah keluar dari widget, pengujiannya tidak butuh
// widget test sama sekali (Refactoring Challenge no. 2).

import 'package:flutter_test/flutter_test.dart';
import 'package:week7_clean_notes/core/format.dart';

void main() {
  group('formatDateTime', () {
    test('menghasilkan tanggal Indonesia + jam', () {
      expect(
        formatDateTime(DateTime(2026, 10, 13, 14, 5)),
        '13 Okt 2026, 14:05',
      );
    });

    test('bulan Januari dan Desember benar', () {
      expect(formatDate(DateTime(2026, 1, 2)), '2 Jan 2026');
      expect(formatDate(DateTime(2026, 12, 31)), '31 Des 2026');
    });

    test('formatDateTimeWithSeconds menambahkan detik', () {
      expect(
        formatDateTimeWithSeconds(DateTime(2026, 10, 13, 9, 0, 7)),
        '13 Okt 2026, 09:00:07',
      );
    });
  });

  group('formatRelative', () {
    final now = DateTime(2026, 10, 13, 12, 0);

    test('kurang dari satu menit -> baru saja', () {
      expect(
        formatRelative(now.subtract(const Duration(seconds: 30)), now: now),
        'baru saja',
      );
    });

    test('menit, jam, dan hari', () {
      expect(
        formatRelative(now.subtract(const Duration(minutes: 5)), now: now),
        '5 menit lalu',
      );
      expect(
        formatRelative(now.subtract(const Duration(hours: 3)), now: now),
        '3 jam lalu',
      );
      expect(
        formatRelative(now.subtract(const Duration(days: 2)), now: now),
        '2 hari lalu',
      );
    });
  });

  group('parseNoteId', () {
    test('angka valid dikembalikan apa adanya', () {
      expect(parseNoteId('42'), 42);
    });

    test('null / kosong / bukan angka -> 0', () {
      expect(parseNoteId(null), 0);
      expect(parseNoteId(''), 0);
      expect(parseNoteId('abc'), 0);
    });
  });

  group('parseIsoDate', () {
    test('ISO valid diparse', () {
      expect(parseIsoDate('2026-10-13T10:00:00.000'), isNotNull);
    });

    test('kosong / invalid -> null', () {
      expect(parseIsoDate(null), isNull);
      expect(parseIsoDate(''), isNull);
      expect(parseIsoDate('bukan-tanggal'), isNull);
    });
  });
}
