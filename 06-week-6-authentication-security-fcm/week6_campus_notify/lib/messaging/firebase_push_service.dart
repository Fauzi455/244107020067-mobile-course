// Implementasi FCM sungguhan (Android/iOS).
//
// Bagian yang WAJIB diperhatikan dan sering salah:
//   * background handler HARUS fungsi top-level + `@pragma('vm:entry-point')`
//     karena berjalan di isolate terpisah (tidak ada BuildContext/Riverpod).
//   * `onTokenRefresh` harus MENGIRIM token ke backend, bukan sekadar
//     `print` — kalau tidak, backend menyimpan token basi dan notifikasi
//     berhenti sampai diam-diam.
//   * foreground butuh notifikasi lokal manual (lihat NotificationPresenter).

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'push_message.dart';
import 'push_service.dart';

/// Handler background — WAJIB top-level, bukan method kelas.
///
/// Isolate ini tidak punya `BuildContext`, tidak punya ProviderContainer, dan
/// tidak boleh menyentuh widget apa pun. Tugasnya hanya pekerjaan ringan:
/// mencatat / menyimpan. Navigasi dilakukan saat pengguna mengklik notifikasi
/// (`onMessageOpenedApp` / `getInitialMessage`).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint(
    '[FCM][background] messageId=${message.messageId} data=${message.data}',
  );
}

class FirebasePushService implements PushService {
  FirebasePushService();

  final StreamController<PushEvent> _events =
      StreamController<PushEvent>.broadcast();

  final ValueNotifier<String?> _token = ValueNotifier<String?>(null);
  final ValueNotifier<bool> _topic = ValueNotifier<bool>(false);

  final List<StreamSubscription<dynamic>> _subs = [];

  @override
  String get label => 'FirebaseMessaging';

  @override
  bool get isReal => true;

  @override
  Stream<PushEvent> get events => _events.stream;

  @override
  ValueListenable<String?> get token => _token;

  @override
  ValueListenable<bool> get topicSubscribed => _topic;

  @override
  PushSimulator? get simulator => null;

  @override
  Future<PushBootstrap> start({
    required Future<void> Function(String token) onToken,
  }) async {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    // 1. Token saat ini -> kirim ke backend.
    final initialToken = await messaging.getToken();
    if (initialToken != null) {
      _token.value = initialToken;
      await onToken(initialToken);
    }

    // 2. Token bisa berubah (reinstall, clear data, rotasi keamanan).
    _subs.add(
      messaging.onTokenRefresh.listen((newToken) async {
        _token.value = newToken;
        await onToken(newToken);
      }),
    );

    // 3. Langganan topik broadcast kampus.
    await subscribe(PushService.campusTopic);

    // 4. Tiga app state.
    _subs.add(
      FirebaseMessaging.onMessage.listen((message) {
        _events.add(
          PushEvent(
            kind: PushEventKind.foreground,
            message: _toPushMessage(message),
          ),
        );
      }),
    );
    _subs.add(
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _events.add(
          PushEvent(
            kind: PushEventKind.opened,
            message: _toPushMessage(message),
          ),
        );
      }),
    );

    // 5. Terminated: aplikasi dibuka dari notifikasi.
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _events.add(
        PushEvent(
          kind: PushEventKind.initial,
          message: _toPushMessage(initialMessage),
        ),
      );
    }

    return PushBootstrap(
      permissionGranted: granted,
      token: _token.value,
      topicSubscribed: _topic.value,
    );
  }

  @override
  Future<void> subscribe(String topic) async {
    await FirebaseMessaging.instance.subscribeToTopic(topic);
    if (topic == PushService.campusTopic) _topic.value = true;
  }

  @override
  Future<void> unsubscribe(String topic) async {
    await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    if (topic == PushService.campusTopic) _topic.value = false;
  }

  @override
  Future<void> dispose() async {
    for (final sub in _subs) {
      await sub.cancel();
    }
    await _events.close();
  }

  PushMessage _toPushMessage(RemoteMessage message) => PushMessage(
    title: message.notification?.title,
    body: message.notification?.body,
    data: Map<String, dynamic>.from(message.data),
  );
}
