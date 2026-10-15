// Kanal push TIRUAN untuk web/desktop/demo.
//
// Mengapa ada? Modul Minggu 6 mengakui bahwa notifikasi paling mudah diuji di
// perangkat fisik, dan FCM sendiri tidak berjalan di web tanpa konfigurasi
// Firebase. Supaya tiga app state tetap bisa **dibuktikan dan difoto** di
// lingkungan tanpa emulator, kanal tiruan ini menyalurkan pesan ke jalur
// penanganan yang sama persis dengan `FirebasePushService`:
//
//   emit(foreground) -> PushEvent(foreground) -> NotificationPresenter.show()
//   emit(opened)     -> PushEvent(opened)     -> router.go(data.route)
//   emit(initial)    -> PushEvent(initial)    -> router.go(data.route)
//
// Yang berbeda hanya sumber pesannya, bukan logika penanganannya.

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'push_message.dart';
import 'push_service.dart';

class SimulatedPushService implements PushService, PushSimulator {
  SimulatedPushService({Random? random}) : _random = random ?? Random();

  final Random _random;

  final StreamController<PushEvent> _events =
      StreamController<PushEvent>.broadcast();

  final ValueNotifier<String?> _token = ValueNotifier<String?>(null);
  final ValueNotifier<bool> _topic = ValueNotifier<bool>(false);

  Future<void> Function(String token)? _onToken;

  @override
  String get label => 'Simulasi (kanal tiruan)';

  @override
  bool get isReal => false;

  @override
  Stream<PushEvent> get events => _events.stream;

  @override
  ValueListenable<String?> get token => _token;

  @override
  ValueListenable<bool> get topicSubscribed => _topic;

  @override
  PushSimulator get simulator => this;

  @override
  Future<PushBootstrap> start({
    required Future<void> Function(String token) onToken,
  }) async {
    _onToken = onToken;

    // "Izin" pada kanal tiruan selalu diberikan agar demo deterministik.
    final generated = _generateToken();
    _token.value = generated;
    await onToken(generated);

    await subscribe(PushService.campusTopic);

    return PushBootstrap(
      permissionGranted: true,
      token: generated,
      topicSubscribed: _topic.value,
    );
  }

  @override
  Future<void> subscribe(String topic) async {
    if (topic == PushService.campusTopic) _topic.value = true;
  }

  @override
  Future<void> unsubscribe(String topic) async {
    if (topic == PushService.campusTopic) _topic.value = false;
  }

  @override
  Future<void> emit({
    required PushEventKind kind,
    PushMessage? message,
  }) async {
    final payload =
        message ??
        PushMessage(
          title: 'Jadwal kuliah berubah',
          body: 'Kelas Mobile pindah ke Ruang A2 jam 13.00',
          data: PushMessage.samplePayload,
        );
    // Beri jeda kecil agar UI sempat berpindah sebelum event masuk —
    // meniru latensi jaringan FCM.
    await Future<void>.delayed(const Duration(milliseconds: 120));
    _events.add(PushEvent(kind: kind, message: payload));
  }

  @override
  Future<void> rotateToken() async {
    final rotated = _generateToken();
    _token.value = rotated;
    // Persis seperti onTokenRefresh: token baru WAJIB dikirim ke backend.
    await _onToken?.call(rotated);
  }

  @override
  Future<void> dispose() async {
    await _events.close();
  }

  /// Membuat string sepanjang & berpola seperti registration token FCM asli
  /// (`<22 karakter>:APA91b<134 karakter>`) supaya tampilan terpotong di
  /// halaman Push & Token terlihat realistis.
  String _generateToken() {
    const alphabet =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-';
    String chunk(int length) => List.generate(
      length,
      (_) => alphabet[_random.nextInt(alphabet.length)],
    ).join();
    return '${chunk(22)}:APA91b${chunk(134)}';
  }
}
