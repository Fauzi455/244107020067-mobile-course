// Kontrak layanan push + model peristiwanya.
//
// Ada dua implementasi:
//   * `FirebasePushService`   -> FCM sungguhan (Android/iOS).
//   * `SimulatedPushService`  -> kanal tiruan untuk web/desktop/demo, supaya
//                                tiga app state tetap bisa dibuktikan dan
//                                difoto tanpa perangkat fisik.
//
// Lapisan halaman hanya berinteraksi dengan abstraksi ini, sehingga tidak ada
// satu pun widget yang mengimpor `firebase_messaging`.

import 'package:flutter/foundation.dart';

import 'push_message.dart';

/// Tiga keadaan aplikasi yang wajib diuji pada modul Minggu 6.
enum PushEventKind {
  /// Aplikasi terbuka -> sistem tidak menampilkan banner otomatis.
  foreground,

  /// Aplikasi diminimize lalu notifikasi diklik -> `onMessageOpenedApp`.
  opened,

  /// Aplikasi dimatikan lalu dibuka dari notifikasi -> `getInitialMessage`.
  initial,
}

class PushEvent {
  const PushEvent({required this.kind, required this.message});

  final PushEventKind kind;
  final PushMessage message;

  String get label => switch (kind) {
    PushEventKind.foreground => 'foreground',
    PushEventKind.opened => 'background',
    PushEventKind.initial => 'terminated',
  };
}

class PushBootstrap {
  const PushBootstrap({
    required this.permissionGranted,
    required this.token,
    required this.topicSubscribed,
  });

  final bool permissionGranted;
  final String? token;
  final bool topicSubscribed;
}

abstract class PushService {
  /// Nama implementasi yang ditampilkan di halaman Push & Token.
  String get label;

  /// `true` kalau ini FCM sungguhan (bukan kanal tiruan).
  bool get isReal;

  /// Topik broadcast kampus.
  static const String campusTopic = 'pengumuman-kampus';

  Stream<PushEvent> get events;

  /// Token terbaru — ikut berubah saat `onTokenRefresh` menyala.
  ValueListenable<String?> get token;

  ValueListenable<bool> get topicSubscribed;

  /// Minta izin, ambil token, pasang listener `onTokenRefresh`, langganan topik.
  ///
  /// [onToken] dipanggil untuk token awal DAN setiap kali token berubah —
  /// inilah yang mengirim token ke backend (`POST /devices`).
  Future<PushBootstrap> start({
    required Future<void> Function(String token) onToken,
  });

  Future<void> subscribe(String topic);
  Future<void> unsubscribe(String topic);

  /// Non-null hanya pada implementasi tiruan.
  PushSimulator? get simulator => null;

  Future<void> dispose();
}

/// Kemampuan tambahan khusus implementasi tiruan (dipakai panel simulator).
abstract class PushSimulator {
  /// Menyuntikkan pesan seolah diterima FCM pada salah satu app state.
  Future<void> emit({required PushEventKind kind, PushMessage? message});

  /// Meniru "hapus data aplikasi / reinstall": FCM menerbitkan token baru
  /// sehingga `onTokenRefresh` wajib menyala.
  Future<void> rotateToken();
}
