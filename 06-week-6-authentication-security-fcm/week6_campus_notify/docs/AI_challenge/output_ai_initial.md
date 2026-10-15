# Keluaran awal AI (apa adanya, sebelum dinilai)

Disalin apa adanya dari jawaban pertama AI coding assistant. **Bagian yang
bermasalah sengaja tidak dihapus** — justru inilah yang dinilai pada AI
Verification Checklist. Analisis ada di
[`usulan_vs_keputusan.md`](usulan_vs_keputusan.md).

---

## `lib/messaging/push_service.dart`

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final _local = FlutterLocalNotificationsPlugin();

String? pendingDeepLink;

Future<bool> requestNotificationPermission() async {
  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true, badge: true, sound: true,
    announcement: false, carPlay: false, criticalAlert: false,
  );
  return settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional;
}

Future<void> initLocalNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings();
  await _local.initialize(
    const InitializationSettings(android: android, iOS: ios),
    onDidReceiveNotificationResponse: (response) {
      pendingDeepLink = response.payload;
    },
  );
}

Future<void> initFcmToken({
  required Future<void> Function(String token) onToken,
}) async {
  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) await onToken(token);

  FirebaseMessaging.instance.onTokenRefresh.listen(onToken);

  await FirebaseMessaging.instance.subscribeToTopic('pengumuman-kampus');
}

void listenForeground(void Function(String route) go) {
  FirebaseMessaging.onMessage.listen((message) async {
    final route = message.data['route'] ?? '/';
    const androidDetails = AndroidNotificationDetails(
      'pengumuman', 'Pengumuman Kampus',
      importance: Importance.high, priority: Priority.high,
    );
    await _local.show(
      message.hashCode,
      message.notification?.title ?? 'Pengumuman',
      message.notification?.body ?? '',
      const NotificationDetails(android: androidDetails),
      payload: route,
    );
  });

  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    go(message.data['route'] ?? '/');
  });
}

Future<void> handleTerminated(void Function(String route) go) async {
  final initial = await FirebaseMessaging.instance.getInitialMessage();
  if (initial != null) go(initial.data['route'] ?? '/');
  if (pendingDeepLink != null) go(pendingDeepLink!);
}
```

## `lib/messaging/background.dart`

```dart
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message: ${message.data}');
}

void registerBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}
```

## `lib/data/api_client.dart` (interceptor)

```dart
Dio buildApiClient(TokenStore store, AuthRepository auth) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example-campus-api.test'));
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final access = await store.readAccess();
      if (access != null) {
        options.headers['Authorization'] = 'Bearer $access';
      }
      handler.next(options);
    },
    onError: (e, handler) async {
      if (e.response?.statusCode == 401) {
        final refresh = await store.readRefresh();
        if (refresh == null) return handler.next(e);
        try {
          final renewed = await auth.refresh(refresh);
          await store.save(access: renewed, refresh: refresh);
          final retry = await dio.fetch(
            e.requestOptions..headers['Authorization'] = 'Bearer $renewed',
          );
          return handler.resolve(retry);
        } catch (_) {
          await store.clear();
        }
      }
      handler.next(e);
    },
  ));
  return dio;
}
```

## `lib/data/auth_repository.dart` (bagian refresh)

```dart
Future<String> refresh(String refreshToken) async {
  await Future.delayed(const Duration(milliseconds: 300));
  if (refreshToken.isEmpty) throw Exception('Refresh token hilang');
  return 'mock-access-renewed-${Random().nextInt(1 << 32)}';
}
```

## Halaman debug token (usulan AI)

```dart
Text('FCM Token: $token'),          // token UTUH ditampilkan
Text('Access: $accessToken'),       // token UTUH ditampilkan
```

## Catatan AI pada keluaran pertama

> "Simpan refresh token di `SharedPreferences` agar lebih mudah diakses lintas
> isolate saat background handler berjalan."
>
> "`onTokenRefresh.listen(print)` cukup untuk memantau rotasi token."

---

## Apa yang terjadi saat keluaran ini dijalankan

| Bagian | Hasil pengujian |
|---|---|
| `nextInt(1 << 32)` | ✅ jalan di VM Dart, ❌ **`RangeError` di web** (`1 << 32` = `0` di dart2js) → jalur refresh selalu gagal → pengguna terlempar ke `/login` |
| `dio.fetch(e.requestOptions)` tanpa penanda | 401 kedua memicu refresh **lagi**; berhenti hanya ketika refresh token ikut mati |
| `store.save(access:, refresh:)` | refresh token ditulis ulang dari nilai yang dipegang; berpotensi menimpa token yang lebih baru |
| `onTokenRefresh.listen(print)` | token baru **tidak** sampai ke backend → notifikasi berhenti tanpa error |
| `firebaseMessagingBackgroundHandler` tanpa `@pragma` | fungsi masih top-level, tetapi tanpa `@pragma('vm:entry-point')` bisa di-tree-shake pada build rilis |
| `Text('FCM Token: $token')` | melanggar aturan modul: token utuh tidak boleh ada di screenshot |
| `await Firebase.initializeApp()` tanpa `try/catch` | aplikasi **crash** saat Firebase belum dikonfigurasi — padahal minggu ini justru diuji di lingkungan tanpa perangkat |
| `'pengumuman'` sebagai channel id | tidak sama dengan `default_notification_channel_id`, sehingga notifikasi otomatis FCM dan notifikasi lokal masuk ke **dua kanal berbeda** |
