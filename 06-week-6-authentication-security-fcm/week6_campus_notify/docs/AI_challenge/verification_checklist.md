# Checklist verifikasi — AI Challenge Minggu 6

Checklist ini diambil dari modul ("AI Verification Checklist") dan dijawab
dengan **bukti**, bukan dengan klaim. Baris terakhir ditutup dengan tabel hasil
uji tiga app state yang dituntut modul.

---

## A. Checklist modul

### A.1 Apakah background handler berupa fungsi top-level dengan `@pragma('vm:entry-point')`?

**Ya.** Fungsi `firebaseMessagingBackgroundHandler` di
`lib/messaging/firebase_push_service.dart` berada di level atas berkas (bukan
method kelas), dan diberi anotasi `@pragma('vm:entry-point')`.

Draf awal AI sudah membuatnya top-level, tetapi **tanpa `@pragma`**. Ditambahkan
karena tanpa anotasi itu fungsi yang hanya dipanggil dari native bisa dianggap
tidak terpakai dan dibuang saat tree-shaking pada build rilis — gejalanya
"handler tidak pernah jalan" dan hanya muncul di rilis, bukan di debug.

Isi handler sengaja minimal (hanya mencatat) karena berjalan di isolate
terpisah: **tidak** menyentuh `BuildContext`, **tidak** menyentuh Riverpod,
**tidak** melakukan navigasi. Navigasi terjadi saat pengguna mengklik notifikasi.

- ✅ top-level
- ✅ `@pragma('vm:entry-point')`
- ✅ tanpa `BuildContext` / Riverpod / navigasi

### A.2 Apakah `onTokenRefresh` benar-benar mengirim token baru ke backend, bukan hanya dicetak ke log?

**Ya — dan ini yang paling penting.** Draf AI menulis
`onTokenRefresh.listen(print)`, yang **ditolak**.

Implementasi final:

```dart
_subs.add(
  messaging.onTokenRefresh.listen((newToken) async {
    _token.value = newToken;
    await onToken(newToken);   // -> POST /devices { fcm_token, platform }
  }),
);
```

Bukti berlapis:

| Lapis | Bukti |
|---|---|
| Kode | `lib/messaging/firebase_push_service.dart` |
| Test | `test/simulated_push_service_test.dart` → `rotateToken meniru onTokenRefresh dan mengirim token BARU` (memverifikasi `onToken` dipanggil **dua kali** dengan nilai berbeda) |
| Server | `tool/mock_api_server.js` mencatat `POST /devices` dan **mengganti** token lama, bukan menumpuknya |
| Layar | `screenshots/10_rotate_token.png` — token di perangkat **dan** baris "Token tercatat di backend" berubah bersama |
| Konsol | Jejak lifecycle: `token FCM diterima (163 karakter)` → `token tercatat di backend (platform web)` |

### A.3 Apakah foreground memakai local notification manual?

**Ya.** Saat foreground, Android/iOS **tidak** menampilkan apa pun secara
otomatis untuk pesan berisi `notification` — banner harus dibuat sendiri.

`NotificationPresenter.show()` melakukan dua hal sekaligus:

1. menembakkan notifikasi **sistem** lewat `flutter_local_notifications`
   (aktif hanya bila kanal sistem tersedia — Android/iOS);
2. menampilkan **banner dalam aplikasi** (`InAppBanner`) sebagai jaring pengaman
   dan sebagai bukti visual di lingkungan tanpa perangkat.

Bukti: `screenshots/07_push_foreground.png` (banner dengan judul, isi, dan label
`ketuk → /pengumuman/3`), serta baris log
`foreground → banner lokal /pengumuman/3`.

### A.4 Apakah klik dari ketiga state masuk ke rute yang benar?

**Ya.** Lihat tabel di bagian B. Semuanya mendarat di `/pengumuman/3`, dan
halaman tujuan menampilkan state asalnya.

### A.5 Apakah token/secret tidak di-hardcode dan tidak di-log penuh?

**Ya.**

| Aturan | Cara dipenuhi |
|---|---|
| Tidak di-hardcode | Tidak ada literal token di `lib/`. Hanya **pola** `mock-access-for-*` pada repository mock (jelas bukan secret) |
| Tidak di-log penuh | Log interceptor hanya menyebut **panjang** token: `→ GET /me (Bearer …40)`. `TokenStore.mask()` memotong pada 12 karakter |
| Tidak di UI penuh | Semua tempat menampilkan token memakai `TokenStore.mask()` |
| Tidak di repo | `google-services.json` dan `GoogleService-Info.plist` masuk `.gitignore` |
| Tidak lewat URL | Refresh token hanya di **body** `POST /auth/refresh`; mock server hanya menerimanya dari body |

### A.6 Keputusan final dan alasan teknis

Tabel lengkap sepuluh keputusan (sembilan di antaranya menyimpang dari AI) ada di
[`usulan_vs_keputusan.md`](usulan_vs_keputusan.md). Dua yang berasal dari bug
nyata — dan keduanya **hanya** ditemukan lewat menjalankan aplikasi:

1. `nextInt(1 << 32)` → `RangeError` di web pada jalur refresh.
2. `dio.fetch()` tanpa penanda → refresh berulang pada 401 kedua.

---

## B. Hasil uji tiga app state (wajib modul)

Payload identik untuk ketiga baris:
`notification {title: "Jadwal kuliah berubah", body: "Kelas Mobile pindah ke Ruang A2 jam 13.00"}`
+ `data {route: "/pengumuman/3", id: "3"}`.

| State | Handler | Hasil | Bukti |
|---|---|---|---|
| **Foreground** | `onMessage` → `NotificationPresenter.show()` | Banner lokal muncul (sistem tidak menampilkan apa pun). Jejak: `foreground → banner lokal /pengumuman/3` | `screenshots/07_push_foreground.png` |
| **Background** | banner sistem + `onMessageOpenedApp` | Masuk `/pengumuman/3`, halaman menandai `Dibuka dari state: background`. Jejak: `background → klik banner /pengumuman/3` | `screenshots/08_push_background_deeplink.png` |
| **Terminated** | `getInitialMessage()` | Masuk `/pengumuman/3`, halaman menandai `Dibuka dari state: terminated`. Jejak: `terminated → getInitialMessage /pengumuman/3` | `screenshots/09_push_terminated_deeplink.png` |

Rute tujuan **sama** pada ketiganya — inilah yang membedakan "tiga handler
terpasang" dari "tiga handler benar".

Cara mengulang dengan Firebase Console sungguhan (dan berkas bukti
`screenshots/fcm-console-test.png` yang masih pending):
[`../three_app_states.md`](../three_app_states.md), [`../firebase_setup.md`](../firebase_setup.md) §5.

---

## C. Checklist verifikasi mandiri modul

| Butir | Status | Bukti |
|---|---|---|
| Token hanya di `flutter_secure_storage`, tidak di SharedPreferences/log/screenshot penuh | ✅ | `04_sesi_token.png`, `06_push_token.png`, `token_store.dart` |
| 401 memicu refresh sekali lalu retry; refresh mati memaksa login ulang | ✅ | `05_api_401_refresh.png`, `test/api_refresh_interceptor_test.dart` |
| Ketiga app state teruji dengan tabel bukti; klik masuk rute yang benar | ✅ | bagian B di atas |
| Topik untuk broadcast, token untuk pesan personal | ✅ | `06_push_token.png`, `DeviceRegistry` (`POST /devices`), `../three_app_states.md` |
| `flutter analyze` bersih dan semua test lulus | ✅ | `../verification/flutter_analyze.txt` (*No issues found!*), `../verification/flutter_test.txt` (*+35: All tests passed!*) |
| Prompt, keluaran awal AI, perbaikan manual, dan tabel uji tersimpan di `docs/` | ✅ | folder ini + `../three_app_states.md` |
| Screenshot bukti (token terpotong, banner tiap state, halaman tujuan deep link) | ✅ | `screenshots/01`–`12` |
| `screenshots/fcm-console-test.png` | ⏳ | butuh project Firebase + perangkat dengan Google Play Services |
