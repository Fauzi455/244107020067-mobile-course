// Registrasi perangkat ke backend + model pengumuman kampus.
//
// `POST /devices` adalah langkah (3) pada alur FCM: setelah aplikasi memegang
// registration token, token itu harus dikirim ke backend dan disimpan **per
// pengguna**. Tanpa langkah ini, backend tidak tahu harus mengirim notifikasi
// ke perangkat siapa.

import 'package:dio/dio.dart';

class DeviceRegistry {
  DeviceRegistry(this._dio);

  final Dio _dio;

  /// Mengirim registration token FCM ke backend.
  Future<void> register({
    required String token,
    required String platform,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/devices',
      data: {'fcm_token': token, 'platform': platform},
    );
  }

  /// Daftar token yang tercatat di backend — bukti bahwa `onTokenRefresh`
  /// benar-benar memperbarui data, bukan sekadar dicetak ke log.
  Future<List<String>> registered() async {
    final res = await _dio.get<Map<String, dynamic>>('/devices');
    final list = (res.data?['devices'] as List<dynamic>? ?? const []);
    return list
        .map((e) => (e as Map<String, dynamic>)['fcm_token']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
  }
}

/// Pengumuman kampus — target deep link `/pengumuman/:id`.
class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.publishedAt,
  });

  final String id;
  final String title;
  final String body;
  final String publishedAt;

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? '(tanpa judul)',
    body: json['body']?.toString() ?? '',
    publishedAt: json['published_at']?.toString() ?? '',
  );
}

class AnnouncementRepository {
  AnnouncementRepository(this._dio);

  final Dio _dio;

  Future<List<Announcement>> list() async {
    final res = await _dio.get<Map<String, dynamic>>('/announcements');
    final items = (res.data?['items'] as List<dynamic>? ?? const []);
    return items
        .map((e) => Announcement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Announcement> byId(String id) async {
    final res = await _dio.get<Map<String, dynamic>>('/announcements/$id');
    return Announcement.fromJson(res.data ?? const {});
  }
}
