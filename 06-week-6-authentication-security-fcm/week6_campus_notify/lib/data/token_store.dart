import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Abstraksi penyimpanan rahasia.
///
/// Sengaja dipisah dari `flutter_secure_storage` supaya `TokenStore` bisa
/// diuji tanpa platform channel — unit test tidak punya Keystore Android,
/// Keychain iOS, maupun WebCrypto. Di produksi implementasi di bawah ini
/// yang dipakai; di test cukup penyimpanan dalam memori.
abstract interface class SecureKeyValueStore {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> deleteAll();
}

/// Implementasi produksi: Keystore (Android), Keychain (iOS),
/// WebCrypto + localStorage (web).
class FlutterSecureKeyValueStore implements SecureKeyValueStore {
  const FlutterSecureKeyValueStore([
    this._storage = const FlutterSecureStorage(),
  ]);

  final FlutterSecureStorage _storage;

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> deleteAll() => _storage.deleteAll();
}

/// Satu-satunya pintu keluar-masuk token.
///
/// **Kenapa bukan SharedPreferences?**
/// SharedPreferences menyimpan data sebagai berkas/plist **tanpa enkripsi**.
/// Siapa pun yang bisa membaca sandbox aplikasi — perangkat root/jailbreak,
/// backup tidak terenkripsi, atau ADB di perangkat debug — bisa menyalin
/// refresh token dan memakai ulang sesi pengguna dari mana saja.
/// `flutter_secure_storage` memakai Keychain (iOS) dan Keystore/EncryptedShared
/// Preferences (Android) yang kuncinya dipegang sistem operasi.
///
/// Refresh token **tidak pernah** ditulis ke log, tidak ditampilkan penuh di
/// UI, dan tidak pernah dikirim lewat query string URL.
class TokenStore {
  TokenStore({SecureKeyValueStore? storage})
    : _storage = storage ?? const FlutterSecureKeyValueStore();

  final SecureKeyValueStore _storage;

  static const String accessKey = 'access_token';
  static const String refreshKey = 'refresh_token';

  Future<void> save({required String access, required String refresh}) async {
    await _storage.write(accessKey, access);
    await _storage.write(refreshKey, refresh);
  }

  /// Dipakai interceptor Dio: menukar access token saja tanpa menyentuh
  /// refresh token, supaya refresh token tetap satu-satunya kunci panjang.
  Future<void> saveAccess(String access) => _storage.write(accessKey, access);

  Future<String?> readAccess() => _storage.read(accessKey);

  Future<String?> readRefresh() => _storage.read(refreshKey);

  Future<void> clear() => _storage.deleteAll();

  /// Utilitas tampilan: token boleh DILIHAT terpotong agar bisa diverifikasi
  /// saat demo, tetapi tidak pernah utuh di layar atau di screenshot.
  static String mask(String? token, {int keep = 12}) {
    if (token == null || token.isEmpty) return '(belum ada)';
    if (token.length <= keep) return '${token.substring(0, keep)}…';
    return '${token.substring(0, keep)}… (${token.length} karakter)';
  }
}
