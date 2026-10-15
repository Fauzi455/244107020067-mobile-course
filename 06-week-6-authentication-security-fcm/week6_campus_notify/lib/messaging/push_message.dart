// Pemodelan pesan push + fungsi murni `routeFromMessage`.
//
// Refactoring Challenge 2 modul Minggu 6: parsing `RemoteMessage -> route`
// diekstrak ke fungsi murni supaya bisa diunit-test **tanpa Firebase**.
// Firebase tidak bisa jalan di unit test biasa (butuh platform channel),
// jadi justru bagian inilah yang paling penting untuk diuji.

import '../routes.dart';

/// Mengubah `data` payload FCM menjadi rute GoRouter yang valid.
///
/// Aturan yang ditangani:
///   {}                          -> '/'
///   {route: null}               -> '/'
///   {route: ''}                 -> '/'
///   {route: 'pengumuman/3'}     -> '/pengumuman/3'   (garis miring ditambah)
///   {route: '/pengumuman/3'}    -> '/pengumuman/3'   (sudah benar)
///
/// Nilai yang tidak dikenali tetap dikembalikan apa adanya setelah dinormalkan
/// garis miringnya; guard GoRouter akan mengarahkannya ke halaman yang tepat.
String routeFromMessage(Map<String, dynamic> data) {
  final raw = data['route']?.toString().trim() ?? '';
  if (raw.isEmpty) return AppRoutes.home;
  if (raw == '/') return AppRoutes.home;
  return raw.startsWith('/') ? raw : '/$raw';
}

/// Mengambil id pengumuman dari payload (`data.id`).
///
/// Bila field `id` tidak ada, id diturunkan dari segmen terakhir `route`
/// (`/pengumuman/3` -> `3`) supaya notifikasi yang hanya membawa `route`
/// tetap bisa dibuka.
String? announcementIdFromMessage(Map<String, dynamic> data) {
  final id = data['id']?.toString().trim();
  if (id != null && id.isNotEmpty) return id;

  final route = routeFromMessage(data);
  if (!route.startsWith(AppRoutes.announcementPrefix)) return null;

  final rest = route.substring(AppRoutes.announcementPrefix.length);
  final candidate = rest.startsWith('/') ? rest.substring(1) : rest;
  return candidate.isEmpty ? null : candidate;
}

/// Satu pesan push yang sudah dinormalkan, lepas dari tipe milik Firebase.
///
/// Dengan begitu lapisan UI dan test tidak perlu mengimpor `firebase_messaging`
/// hanya untuk membaca judul/isi/rute.
class PushMessage {
  const PushMessage({this.title, this.body, required this.data});

  final String? title;
  final String? body;
  final Map<String, dynamic> data;

  String get route => routeFromMessage(data);

  String get safeTitle => (title == null || title!.isEmpty)
      ? 'Pengumuman Kampus'
      : title!;

  String get safeBody => body ?? '';

  /// Contoh payload gabungan yang dikirim backend (notification + data).
  static const Map<String, dynamic> samplePayload = {
    'route': '/pengumuman/3',
    'id': '3',
  };
}
