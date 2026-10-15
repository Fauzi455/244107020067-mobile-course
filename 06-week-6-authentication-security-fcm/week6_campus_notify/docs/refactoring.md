# Refactoring Challenge — Minggu 6

Modul menuntut tiga refactoring. Ketiganya dikerjakan, dan alasannya bukan
"supaya rapi", melainkan karena masing-masing menutup satu jenis bug yang khas
pada minggu ini.

---

## 1. Semua string rute pindah ke `lib/routes.dart`

**Sebelum:** `/login`, `/`, dan `/pengumuman/:id` ditulis ulang di
`app_router.dart`, di `push_message.dart` (untuk menyusun rute dari payload), dan
di halaman yang menavigasi ke detail pengumuman.

**Sesudah:** satu kelas konstanta, satu fungsi pembentuk rute.

```dart
abstract final class AppRoutes {
  static const String login = '/login';
  static const String home = '/';
  static const String announcementPattern = '/pengumuman/:id';
  static const String announcementPrefix = '/pengumuman';

  static String announcement(Object? id) => '$announcementPrefix/$id';
}
```

**Alasan:** rute adalah kontrak bersama antara **deep link dari FCM** dan
**definisi GoRouter**. Kalau string-nya ditulis di dua tempat, cepat atau lambat
akan ada rute "nyasar" yang hanya berbeda satu garis miring
(`pengumuman/3` vs `/pengumuman/3`) — dan bug seperti itu hanya muncul saat
notifikasi diklik, yaitu momen yang paling jarang diuji manual.

Berkas ini **sengaja tidak mengimpor halaman apa pun** supaya bisa dipakai di
mana saja tanpa risiko impor melingkar. Konstruksi GoRouter-nya tetap di
`app_router.dart`.

Diuji lewat `test/push_routing_test.dart` (grup `AppRoutes`).

---

## 2. Parsing `RemoteMessage → route` menjadi fungsi murni

**Sebelum:** logika "ambil `data['route']`, pastikan ada garis miring di depan"
berada di dalam `onMessage`/`onMessageOpenedApp` — artinya hanya bisa dijalankan
di perangkat, dan tidak bisa diuji sama sekali.

**Sesudah:** fungsi murni di `lib/messaging/push_message.dart`:

```dart
String routeFromMessage(Map<String, dynamic> data) {
  final raw = data['route']?.toString().trim() ?? '';
  if (raw.isEmpty) return AppRoutes.home;
  if (raw == '/') return AppRoutes.home;
  return raw.startsWith('/') ? raw : '/$raw';
}
```

Plus helper turunannya:

```dart
String? announcementIdFromMessage(Map<String, dynamic> data);
```

**Alasan:** Firebase tidak bisa dijalankan di unit test biasa (butuh platform
channel), jadi kalau logika ini tinggal di dalam handler FCM, ia **tidak akan
pernah teruji otomatis**. Padahal justru inilah bagian yang paling sering salah:
backend lupa garis miring, mengirim `route` sebagai angka, atau tidak mengirim
`route` sama sekali.

Setelah diekstrak, 10 pengujian bisa dijalankan tanpa Firebase — termasuk kasus
`{}`, `{route: null}`, `{route: '   '}`, dan `{route: 3}`.

---

## 3. Pemetaan `DioException → pesan ramah` pindah ke `lib/data/api_errors.dart`

**Sebelum:** setiap halaman menulis terjemahannya sendiri-sendiri
(`if (e.response?.statusCode == 401) ...`), sehingga teksnya cepat tidak
konsisten dan widget ikut tahu detail HTTP.

**Sesudah:** dua fungsi murni yang menjadi satu-satunya penerjemah:

```dart
String friendlyApiMessage(Object error);   // 401, 403, 404, 5xx, timeout, offline
bool isUnauthorized(Object error);
```

**Alasan:** lapisan UI hanya boleh menerima **pesan siap tampil**. Kalau
`DioException` bocor sampai widget, satu perubahan bentuk error di layer data
memaksa perubahan di semua halaman. Fungsi ini juga tidak menyentuh runtime Dio,
jadi bisa diuji tanpa jaringan (`test/auth_session_test.dart`, grup
`friendlyApiMessage`).

Efek sampingnya yang berguna: `isUnauthorized()` memberi satu tempat untuk
memutuskan "apakah pengguna harus diarahkan ke login?" — keputusan yang di
Minggu 6 punya konsekuensi keamanan, bukan sekadar tampilan.

---

## Refactoring tambahan yang muncul dari pengujian

Bukan bagian dari tiga tantangan wajib, tetapi keduanya menutup bug yang hanya
terlihat saat aplikasi benar-benar dijalankan.

### 4. `onSessionExpired` pada `buildApiClient`

**Masalah:** setelah interceptor membersihkan token karena refresh ikut mati,
state autentikasi Riverpod **tidak tahu apa-apa**. Token sudah hilang, tetapi UI
masih diam di beranda sampai pengguna menyentuh sesuatu yang memicu request
berikutnya.

**Perbaikan:** `buildApiClient` menerima callback `onSessionExpired`, dan
`providers.dart` menyambungkannya ke `AuthNotifier.forceLogout()`. Guard GoRouter
yang memindahkan pengguna ke `/login`, sehingga tidak ada layar yang menggantung
di antara "sudah logout" dan "belum logout".

### 5. `TokenStore.saveAccess()` terpisah dari `save()`

**Masalah:** jalur refresh memanggil `save(access: baru, refresh: lama)`. Kalau
nilai `refresh` yang dipegang sudah basi (mis. token berubah di jalur lain),
penulisan ulang itu justru **menimpa refresh token yang masih sah**.

**Perbaikan:** interceptor hanya menulis access token:

```dart
Future<void> saveAccess(String access) => _storage.write(accessKey, access);
```

Aturan yang jadi lebih jelas: refresh token adalah satu-satunya kunci panjang,
dan ia hanya ditulis saat login.
