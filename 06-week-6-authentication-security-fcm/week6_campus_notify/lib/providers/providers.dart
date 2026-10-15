// WIRING DI untuk lapisan data + messaging.
//
// Halaman TIDAK PERNAH menginstansiasi `Dio`, `TokenStore`, atau layanan push
// sendiri. Semuanya lewat provider, sehingga test cukup `overrideWithValue`.

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/announcements.dart';
import '../data/api_client.dart';
import '../data/api_log.dart';
import '../data/auth_repository.dart';
import '../data/token_store.dart';
import '../messaging/firebase_push_service.dart';
import '../messaging/notification_presenter.dart';
import '../messaging/push_service.dart';
import '../messaging/simulated_push_service.dart';
import 'auth_provider.dart';

// --- Data layer ------------------------------------------------------------

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);

/// Riwayat lalu lintas HTTP. Newest first.
class ApiLogNotifier extends Notifier<List<ApiLogEntry>> {
  @override
  List<ApiLogEntry> build() => const [];

  void add(ApiLogEntry entry) {
    // Dicerminkan ke konsol debug agar jejaknya juga bisa dibaca dari luar
    // aplikasi (mis. saat pengambilan screenshot lewat Chrome headless).
    debugPrint('[api] ${entry.ok ? 'ok ' : 'ERR'} ${entry.message}');
    state = [entry, ...state].take(40).toList();
  }

  void clear() => state = const [];
}

final apiLogProvider = NotifierProvider<ApiLogNotifier, List<ApiLogEntry>>(
  ApiLogNotifier.new,
);

final apiClientProvider = Provider<Dio>((ref) {
  return buildApiClient(
    store: ref.watch(tokenStoreProvider),
    auth: ref.watch(authRepositoryProvider),
    log: ref.read(apiLogProvider.notifier).add,
    // Refresh token hilang / ikut kedaluwarsa: batalkan state autentikasi
    // supaya guard GoRouter memindahkan pengguna kembali ke `/login`.
    onSessionExpired: () {
      ref
          .read(pushStateProvider.notifier)
          .log('sesi tidak dapat dipulihkan → login ulang');
      ref.read(authStateProvider.notifier).forceLogout();
    },
  );
});

final deviceRegistryProvider = Provider<DeviceRegistry>(
  (ref) => DeviceRegistry(ref.watch(apiClientProvider)),
);

final announcementRepositoryProvider = Provider<AnnouncementRepository>(
  (ref) => AnnouncementRepository(ref.watch(apiClientProvider)),
);

/// Nama platform yang dikirim ke `POST /devices`.
final platformNameProvider = Provider<String>((ref) {
  if (kIsWeb) return 'web';
  return defaultTargetPlatform.name;
});

// --- Messaging layer -------------------------------------------------------

/// Memilih implementasi push.
///
/// Di web/desktop, FCM tidak tersedia tanpa konfigurasi Firebase sehingga
/// kanal tiruan yang dipakai. Di Android/iOS, FCM sungguhan dipakai bila
/// `Firebase.initializeApp()` berhasil (dicek di `main.dart`).
final useRealPushProvider = Provider<bool>((ref) => false);

final pushServiceProvider = Provider<PushService>((ref) {
  final useReal = ref.watch(useRealPushProvider);
  final service = useReal ? FirebasePushService() : SimulatedPushService();
  ref.onDispose(service.dispose);
  return service;
});

final notificationPresenterProvider = Provider<NotificationPresenter>((ref) {
  final presenter = NotificationPresenter(
    // Kanal sistem hanya di perangkat mobile.
    enableSystemChannel: !kIsWeb && ref.watch(useRealPushProvider),
  );
  ref.onDispose(presenter.dispose);
  return presenter;
});

/// Status push yang bisa ditonton halaman (izin, token, topik, log lifecycle).
class PushState {
  const PushState({
    this.serviceLabel = '-',
    this.isReal = false,
    this.permissionGranted = false,
    this.token,
    this.topicSubscribed = false,
    this.backendTokens = const [],
    this.log = const [],
  });

  final String serviceLabel;
  final bool isReal;
  final bool permissionGranted;
  final String? token;
  final bool topicSubscribed;

  /// Token yang tercatat di backend — bukti `onTokenRefresh` benar-benar
  /// mengirim ulang, bukan hanya mencetak ke log.
  final List<String> backendTokens;

  final List<String> log;

  PushState copyWith({
    String? serviceLabel,
    bool? isReal,
    bool? permissionGranted,
    String? token,
    bool? topicSubscribed,
    List<String>? backendTokens,
    List<String>? log,
  }) => PushState(
    serviceLabel: serviceLabel ?? this.serviceLabel,
    isReal: isReal ?? this.isReal,
    permissionGranted: permissionGranted ?? this.permissionGranted,
    token: token ?? this.token,
    topicSubscribed: topicSubscribed ?? this.topicSubscribed,
    backendTokens: backendTokens ?? this.backendTokens,
    log: log ?? this.log,
  );
}

class PushStateNotifier extends Notifier<PushState> {
  @override
  PushState build() => const PushState();

  void setService({required String label, required bool isReal}) {
    state = state.copyWith(serviceLabel: label, isReal: isReal);
  }

  void setBootstrap(PushBootstrap bootstrap) {
    state = state.copyWith(
      permissionGranted: bootstrap.permissionGranted,
      token: bootstrap.token,
      topicSubscribed: bootstrap.topicSubscribed,
    );
  }

  void setToken(String token) => state = state.copyWith(token: token);

  void setTopic(bool subscribed) =>
      state = state.copyWith(topicSubscribed: subscribed);

  void setBackendTokens(List<String> tokens) =>
      state = state.copyWith(backendTokens: tokens);

  void log(String message) {
    debugPrint('[push] $message');
    state = state.copyWith(log: [...state.log, message].take(30).toList());
  }
}

final pushStateProvider = NotifierProvider<PushStateNotifier, PushState>(
  PushStateNotifier.new,
);
