// Test fungsi murni parsing rute notifikasi.
//
// Bagian inilah yang paling layak diuji: Firebase tidak bisa dijalankan di unit
// test biasa (butuh platform channel), tetapi logika "payload -> rute" bisa
// diuji sepenuhnya tanpa Firebase. Modul Minggu 6 menuntut minimal dua test
// lulus; berkas ini menyumbang kelompok pertama (parsing rute).

import 'package:flutter_test/flutter_test.dart';
import 'package:week6_campus_notify/messaging/push_message.dart';
import 'package:week6_campus_notify/routes.dart';

void main() {
  group('routeFromMessage', () {
    test('payload tanpa route kembali ke beranda', () {
      expect(routeFromMessage(const {}), AppRoutes.home);
      expect(routeFromMessage(const {'route': null}), AppRoutes.home);
      expect(routeFromMessage(const {'route': ''}), AppRoutes.home);
      expect(routeFromMessage(const {'route': '   '}), AppRoutes.home);
      expect(routeFromMessage(const {'route': '/'}), AppRoutes.home);
    });

    test('menambahkan garis miring di depan bila backend lupa', () {
      expect(
        routeFromMessage(const {'route': 'pengumuman/3'}),
        '/pengumuman/3',
      );
    });

    test('membiarkan rute yang sudah absolut', () {
      expect(
        routeFromMessage(const {'route': '/pengumuman/3'}),
        '/pengumuman/3',
      );
    });

    test('tahan terhadap nilai non-string', () {
      expect(routeFromMessage(const {'route': 3}), '/3');
    });
  });

  group('announcementIdFromMessage', () {
    test('memprioritaskan field id', () {
      expect(announcementIdFromMessage(const {'id': '3'}), '3');
      expect(announcementIdFromMessage(const {'id': 3}), '3');
    });

    test('menurunkan id dari route bila field id tidak ada', () {
      expect(announcementIdFromMessage(const {'route': '/pengumuman/7'}), '7');
      expect(announcementIdFromMessage(const {'route': 'pengumuman/7'}), '7');
    });

    test('null bila bukan rute pengumuman', () {
      expect(announcementIdFromMessage(const {'route': '/'}), isNull);
      expect(announcementIdFromMessage(const {}), isNull);
    });
  });

  group('PushMessage', () {
    test('memakai judul default saat notification tidak dikirim', () {
      const message = PushMessage(data: {'route': '/pengumuman/3'});
      expect(message.safeTitle, 'Pengumuman Kampus');
      expect(message.safeBody, '');
      expect(message.route, '/pengumuman/3');
    });

    test('payload contoh modul menghasilkan rute yang benar', () {
      const message = PushMessage(
        title: 'Jadwal kuliah berubah',
        body: 'Kelas Mobile pindah ke Ruang A2',
        data: PushMessage.samplePayload,
      );
      expect(message.route, '/pengumuman/3');
      expect(announcementIdFromMessage(message.data), '3');
    });
  });

  group('AppRoutes', () {
    test('konstanta rute konsisten dengan pola GoRouter', () {
      expect(AppRoutes.announcement(3), '/pengumuman/3');
      expect(AppRoutes.announcementPattern, '/pengumuman/:id');
      expect(AppRoutes.login, '/login');
      expect(AppRoutes.home, '/');
    });
  });
}
