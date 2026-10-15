// Bootstrap aplikasi Campus Notify.
//
// Urutan yang penting dan tidak boleh ditukar:
//   1. Firebase (hanya mobile) — gagal pun aplikasi tetap jalan dengan kanal
//      push tiruan.
//   2. Sesi dibaca dari secure storage SEBELUM router dibuat, supaya guard
//      punya jawaban sejak frame pertama dan deep link tidak "ditelan".
//   3. Router dibuat, lalu push di-bootstrap (izin -> token -> onTokenRefresh
//      -> topik) dan peristiwanya disalurkan ke router/penyaji notifikasi.

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_router.dart';
import 'messaging/firebase_push_service.dart';
import 'messaging/push_service.dart';
import 'providers/auth_provider.dart';
import 'providers/providers.dart';
import 'widgets/push_banner_host.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- 1. Firebase ---------------------------------------------------------
  // Di web, FCM tidak dipakai (butuh konfigurasi Firebase penuh), sehingga
  // kanal tiruan yang aktif. Di Android/iOS, FCM dipakai bila konfigurasi
  // Firebase tersedia; kalau tidak, aplikasi TIDAK crash — hanya turun kanal.
  var firebaseReady = false;
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      firebaseReady = true;
      // Handler background wajib top-level dan harus didaftarkan paling awal.
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (error) {
      debugPrint('[firebase] belum siap, memakai kanal tiruan: $error');
    }
  }

  final container = ProviderContainer(
    overrides: [useRealPushProvider.overrideWithValue(firebaseReady)],
  );

  // --- 2. Sesi ------------------------------------------------------------
  await container.read(authStateProvider.future);

  // --- 3. Router + push ---------------------------------------------------
  final router = createRouter(container);
  final presenter = container.read(notificationPresenterProvider);
  final push = container.read(pushServiceProvider);
  final pushState = container.read(pushStateProvider.notifier);
  final deviceRegistry = container.read(deviceRegistryProvider);
  final platform = container.read(platformNameProvider);

  await presenter.init();

  pushState.setService(label: push.label, isReal: push.isReal);
  pushState.log('bootstrap kanal: ${push.label}');

  // `POST /devices` butuh Bearer token. Kalau pengguna belum masuk, token
  // DITAHAN dulu lalu dikirim begitu sesi tersedia — kalau tidak, server
  // menjawab 401 dan token tidak pernah tercatat.
  Future<void> registerDeviceToken(String token) async {
    if (container.read(authStateProvider).value != true) {
      pushState.log('token ditahan — menunggu pengguna masuk');
      return;
    }
    try {
      await deviceRegistry.register(token: token, platform: platform);
      pushState.log('token tercatat di backend (platform $platform)');
    } catch (error) {
      pushState.log('backend tidak terjangkau — token belum tercatat');
    }
  }

  final bootstrap = await push.start(
    onToken: (token) async {
      pushState.setToken(token);
      pushState.log('token FCM diterima (${token.length} karakter)');
      await registerDeviceToken(token);
    },
  );
  pushState.setBootstrap(bootstrap);

  // Kirim token yang tertunda begitu login berhasil.
  container.listen<AsyncValue<bool>>(authStateProvider, (previous, next) {
    if (next.value == true && previous?.value != true) {
      final pending = container.read(pushStateProvider).token;
      if (pending != null) unawaited(registerDeviceToken(pending));
    }
  }, fireImmediately: false);

  // Penyaluran tiga app state ke jalur yang benar.
  push.events.listen((event) async {
    switch (event.kind) {
      case PushEventKind.foreground:
        // Sistem tidak menampilkan banner otomatis -> kita tampilkan sendiri.
        await presenter.show(
          title: event.message.safeTitle,
          body: event.message.safeBody,
          route: event.message.route,
        );
        pushState.log('foreground → banner lokal ${event.message.route}');

      case PushEventKind.opened:
        pushState.log('background → klik banner ${event.message.route}');
        router.go(event.message.route, extra: event.label);

      case PushEventKind.initial:
        pushState.log('terminated → getInitialMessage ${event.message.route}');
        router.go(event.message.route, extra: event.label);
    }
  });

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: CampusNotifyApp(router: router),
    ),
  );
}

class CampusNotifyApp extends StatelessWidget {
  const CampusNotifyApp({super.key, required this.router});

  final RouterConfig<Object> router;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF1B4B8F);

    return MaterialApp.router(
      title: 'Campus Notify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      routerConfig: router,
      // Banner notifikasi foreground dipasang di atas seluruh halaman.
      builder: (context, child) =>
          PushBannerHost(child: child ?? const SizedBox.shrink()),
    );
  }
}
