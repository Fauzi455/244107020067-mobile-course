// Penyaji notifikasi foreground.
//
// Modul Minggu 6 menegaskan: saat aplikasi **foreground**, sistem TIDAK
// menampilkan banner otomatis. Banner harus dibuat sendiri. Ada dua kanal:
//
//  1. `flutter_local_notifications` -> banner sistem Android/iOS (dipakai di
//     perangkat sungguhan).
//  2. Banner dalam aplikasi (`InAppBanner`) -> dipakai di web/desktop dan
//     sebagai jaring pengaman saat kanal sistem tidak tersedia.
//
// Keduanya digerakkan dari satu kelas ini supaya halaman tidak pernah
// memanggil plugin notifikasi secara langsung.

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Data banner yang sedang tampil (kanal dalam aplikasi).
class PushBanner {
  const PushBanner({
    required this.title,
    required this.body,
    required this.route,
    this.fromSystemChannel = false,
  });

  final String title;
  final String body;
  final String route;

  /// `true` kalau banner sistem juga ikut ditembakkan (perangkat mobile).
  final bool fromSystemChannel;
}

class NotificationPresenter {
  NotificationPresenter({this.enableSystemChannel = false});

  /// Kanal sistem hanya diinisialisasi di Android/iOS. Di web/desktop kita
  /// mengandalkan banner dalam aplikasi.
  final bool enableSystemChannel;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  final ValueNotifier<PushBanner?> banner = ValueNotifier<PushBanner?>(null);

  /// Dipanggil saat pengguna mengetuk **banner sistem** (notifikasi lokal).
  ///
  /// Diisi oleh `main.dart` dengan `router.go(...)` supaya presenter ini tidak
  /// perlu tahu apa-apa soal GoRouter.
  void Function(String route)? onRouteTap;

  bool _systemReady = false;

  /// Harus sama dengan `com.google.firebase.messaging.default_notification_channel_id`
  /// di `AndroidManifest.xml`, supaya notifikasi FCM yang tampil otomatis saat
  /// background masuk ke kanal yang sama dengan notifikasi lokal.
  static const String channelId = 'pengumuman_kampus';
  static const String channelName = 'Pengumuman Kampus';

  Future<void> init() async {
    if (!enableSystemChannel) return;
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      await _plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: (response) {
          // Klik banner sistem -> payload berisi rute tujuan.
          final payload = response.payload;
          if (payload == null || payload.isEmpty) return;
          banner.value = null;
          onRouteTap?.call(payload);
        },
      );

      // Kanal dibuat lebih awal. Kalau tidak, Android membuat kanal "Miscellaneous"
      // sendiri untuk notifikasi FCM dan pengaturan penting/prioritas kita
      // diabaikan.
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              channelId,
              channelName,
              description: 'Notifikasi pengumuman kampus',
              importance: Importance.high,
            ),
          );

      _systemReady = true;
    } catch (error) {
      // Jangan pernah membuat aplikasi gagal total hanya karena notifikasi
      // lokal tidak tersedia (mis. plugin belum terdaftar di platform ini).
      debugPrint('[notifikasi] kanal sistem tidak aktif: $error');
      _systemReady = false;
    }
  }

  /// Menampilkan notifikasi foreground pada semua kanal yang tersedia.
  Future<void> show({
    required String title,
    required String body,
    required String route,
  }) async {
    banner.value = PushBanner(
      title: title,
      body: body,
      route: route,
      fromSystemChannel: _systemReady,
    );

    if (!_systemReady) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'Notifikasi pengumuman kampus',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
      payload: route,
    );
  }

  void dismiss() => banner.value = null;

  void dispose() {
    banner.dispose();
  }
}
