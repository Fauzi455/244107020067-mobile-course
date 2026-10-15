// Satu sumber kebenaran untuk seluruh rute aplikasi.
//
// Refactoring Challenge 1 modul Minggu 6: deep link dari FCM
// (`data: { "route": "/pengumuman/3" }`) dan definisi GoRouter WAJIB memakai
// konstanta yang sama. Kalau string rute ditulis ulang di dua tempat, cepat
// atau lambat akan ada rute "nyasar" yang hanya berbeda satu garis miring.
//
// File ini SENGAJA tidak mengimpor halaman apa pun supaya bisa dipakai
// di mana saja tanpa risiko impor melingkar. Konstruksi GoRouter-nya ada di
// `app_router.dart`.

abstract final class AppRoutes {
  /// Halaman masuk. Guard akan memaksa ke sini selama belum ada token.
  static const String login = '/login';

  /// Beranda (shell bertab: Beranda, Sesi & API, Push & Token).
  static const String home = '/';

  /// Detail pengumuman — tujuan deep link notifikasi.
  static const String announcementPattern = '/pengumuman/:id';

  /// Prefiks rute pengumuman, dipakai fungsi murni `routeFromMessage`.
  static const String announcementPrefix = '/pengumuman';

  /// Rute tujuan deep link untuk satu pengumuman.
  static String announcement(Object? id) => '$announcementPrefix/$id';
}
