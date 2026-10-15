// Test jalur refresh otomatis pada interceptor Dio.
//
// Ini perilaku paling penting di Minggu 6 dan paling mudah salah: "401 memicu
// refresh SEKALI lalu mengulang request; kalau refresh ikut mati, paksa login
// ulang". Mengandalkan server sungguhan membuat test lambat dan rapuh, jadi
// adapter Dio diganti dengan skenario naskah — tanpa jaringan sama sekali.
//
// Tiga skenario yang diuji:
//   1. 401 -> refresh -> ulang -> 200 (dan token baru tersimpan),
//   2. 401 -> refresh -> ulang -> 401 lagi: BERHENTI, tidak ada loop,
//   3. refresh gagal -> sesi dibersihkan -> error diteruskan.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week6_campus_notify/data/api_client.dart';
import 'package:week6_campus_notify/data/api_log.dart';
import 'package:week6_campus_notify/data/auth_repository.dart';
import 'package:week6_campus_notify/data/token_store.dart';

/// Penyimpanan rahasia dalam memori — hanya untuk test.
class InMemorySecureKeyValueStore implements SecureKeyValueStore {
  final Map<String, String> _data = {};

  @override
  Future<void> write(String key, String value) async => _data[key] = value;

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> deleteAll() async => _data.clear();
}

/// Satu permintaan yang tercatat, dalam bentuk SNAPSHOT.
///
/// Penting: `dio.fetch(requestOptions)` memakai objek `RequestOptions` yang
/// SAMA untuk permintaan ulangan, sehingga header yang diubah interceptor ikut
/// terlihat pada catatan permintaan pertama. Karena itu yang disimpan adalah
/// nilai header saat itu, bukan referensi objeknya.
class RecordedRequest {
  const RecordedRequest({required this.path, required this.authorization});

  final String path;
  final String? authorization;
}

/// Adapter Dio yang menjawab menurut urutan pemanggilan.
class ScriptedAdapter implements HttpClientAdapter {
  ScriptedAdapter(this.responder);

  final ResponseBody Function(RequestOptions options, int callIndex) responder;
  final List<RecordedRequest> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(
      RecordedRequest(
        path: options.path,
        authorization: options.headers['Authorization']?.toString(),
      ),
    );
    return responder(options, requests.length - 1);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonBody(int statusCode, Map<String, dynamic> body) =>
    ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

const String _validRefresh = 'mock-refresh-for-a@b.c';
const String _validAccess = 'mock-access-for-a@b.c';

Future<TokenStore> seedStore({String refresh = _validRefresh}) async {
  final store = TokenStore(storage: InMemorySecureKeyValueStore());
  await store.save(access: _validAccess, refresh: refresh);
  return store;
}

String logText(List<ApiLogEntry> log) =>
    log.map((entry) => entry.message).join(' | ');

void main() {
  group('interceptor 401', () {
    test('401 -> refresh -> ulang request -> 200, token baru tersimpan', () async {
      final store = await seedStore();
      final log = <ApiLogEntry>[];
      final dio = buildApiClient(
        store: store,
        auth: AuthRepository(),
        log: log.add,
      );

      final adapter = ScriptedAdapter(
        (options, index) => index == 0
            ? jsonBody(401, {'error': 'unauthorized'})
            : jsonBody(200, {'email': 'a@b.c'}),
      );
      dio.httpClientAdapter = adapter;

      final response = await dio.get<Map<String, dynamic>>('/me');

      expect(response.statusCode, 200);
      expect(response.data?['email'], 'a@b.c');

      // Tepat DUA permintaan: asli + satu ulangan.
      expect(adapter.requests, hasLength(2));
      expect(
        adapter.requests.first.authorization,
        'Bearer $_validAccess',
      );
      expect(
        adapter.requests.last.authorization,
        startsWith('Bearer mock-access-renewed-'),
      );

      // Access token baru benar-benar dipersist, refresh token tidak berubah.
      expect(await store.readAccess(), startsWith('mock-access-renewed-'));
      expect(await store.readRefresh(), _validRefresh);

      expect(logText(log), contains('401 kedaluwarsa'));
      expect(logText(log), contains('→ 200'));
    });

    test('401 lagi setelah retry -> berhenti, tidak ada loop', () async {
      final store = await seedStore();
      final log = <ApiLogEntry>[];
      final dio = buildApiClient(
        store: store,
        auth: AuthRepository(),
        log: log.add,
      );

      final adapter = ScriptedAdapter((options, index) => jsonBody(401, {}));
      dio.httpClientAdapter = adapter;

      await expectLater(
        dio.get<dynamic>('/me'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'statusCode',
            401,
          ),
        ),
      );

      // Kalau retry tidak dijaga, jumlah permintaan akan tak terhingga.
      expect(adapter.requests, hasLength(2));
    });

    test('refresh ikut gagal -> sesi dibersihkan, error diteruskan', () async {
      // Refresh token tidak dikenal AuthRepository -> refresh melempar.
      final store = await seedStore(refresh: 'refresh-palsu');
      final log = <ApiLogEntry>[];
      final dio = buildApiClient(
        store: store,
        auth: AuthRepository(),
        log: log.add,
      );

      final adapter = ScriptedAdapter((options, index) => jsonBody(401, {}));
      dio.httpClientAdapter = adapter;

      await expectLater(
        dio.get<dynamic>('/me'),
        throwsA(isA<DioException>()),
      );

      // Sesi tidak bisa diselamatkan -> token dibuang, pengguna dipaksa login.
      expect(await store.readAccess(), isNull);
      expect(await store.readRefresh(), isNull);
      expect(logText(log), contains('refresh ikut kedaluwarsa'));
    });

    test('401 tanpa refresh token -> tidak mencoba refresh sama sekali', () async {
      final store = TokenStore(storage: InMemorySecureKeyValueStore());
      await store.saveAccess(_validAccess);
      final log = <ApiLogEntry>[];
      final dio = buildApiClient(
        store: store,
        auth: AuthRepository(),
        log: log.add,
      );

      final adapter = ScriptedAdapter((options, index) => jsonBody(401, {}));
      dio.httpClientAdapter = adapter;

      await expectLater(dio.get<dynamic>('/me'), throwsA(isA<DioException>()));

      expect(adapter.requests, hasLength(1));
      expect(logText(log), contains('tanpa refresh token'));
    });

    test('respons 200 langsung tidak menyentuh jalur refresh', () async {
      final store = await seedStore();
      final log = <ApiLogEntry>[];
      final dio = buildApiClient(
        store: store,
        auth: AuthRepository(),
        log: log.add,
      );

      final adapter = ScriptedAdapter(
        (options, index) => jsonBody(200, {'ok': true}),
      );
      dio.httpClientAdapter = adapter;

      final response = await dio.get<Map<String, dynamic>>('/me');

      expect(response.statusCode, 200);
      expect(adapter.requests, hasLength(1));
      expect(logText(log), isNot(contains('refresh')));
    });
  });
}
