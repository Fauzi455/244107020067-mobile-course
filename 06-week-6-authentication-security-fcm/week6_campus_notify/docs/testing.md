# Pengujian — Campus Notify (Minggu 6)

```bash
flutter analyze      # No issues found!
flutter test         # 35 test, semua lulus
```

Keluaran mentah tersimpan di [`verification/`](verification/).

## Prinsip: apa yang boleh dan tidak boleh diuji

Modul Minggu 6 menegaskan bahwa **Firebase tidak bisa diuji langsung** di unit
test biasa: `FirebaseMessaging` dan `flutter_local_notifications` butuh platform
channel, dan `Firebase.initializeApp()` butuh berkas konfigurasi. Karena itu
yang diuji adalah **logika di sekitarnya** — bagian yang justru paling sering
salah dan paling mahal saat produksi:

| Tidak diuji di sini | Diuji di sini |
|---|---|
| `FirebaseMessaging.instance.getToken()` | parsing `data` payload → rute (fungsi murni) |
| Banner sistem `flutter_local_notifications` | urutan penanganan tiga app state lewat abstraksi `PushService` |
| Keystore/Keychain sungguhan | perilaku interceptor 401 memakai adapter Dio naskah |
| Firebase Console | aturan validasi sesi & pemetaan error |

Konsekuensinya: tidak ada `TestWidgetsFlutterBinding` yang perlu di-*mock*, tidak
ada jaringan, dan test berjalan dalam ~2 detik.

## Daftar test

### `test/push_routing_test.dart` — Refactoring Challenge 2 (fungsi murni)

Parsing `RemoteMessage → route` diekstrak ke `routeFromMessage()` supaya bisa
diuji tanpa Firebase. Justru inilah bagian yang paling penting untuk diuji,
karena kesalahan di sini berarti **klik notifikasi nyasar** — gejala yang tidak
terlihat dari membaca kode.

| Test | Yang dibuktikan |
|---|---|
| `payload tanpa route kembali ke beranda` | `{}`, `{route: null}`, `{route: ''}`, `{route: '   '}`, `{route: '/'}` semuanya → `/` |
| `menambahkan garis miring di depan bila backend lupa` | `pengumuman/3` → `/pengumuman/3` |
| `membiarkan rute yang sudah absolut` | `/pengumuman/3` tidak diubah |
| `tahan terhadap nilai non-string` | `{route: 3}` → `/3` (tidak melempar) |
| `announcementIdFromMessage` | memprioritaskan field `id`, menurunkan id dari `route`, dan `null` untuk rute non-pengumuman |
| `PushMessage.safeTitle/safeBody` | judul default saat `notification` tidak dikirim |
| `payload contoh modul menghasilkan rute yang benar` | payload gabungan `notification + data` milik modul |
| `AppRoutes` | konstanta rute konsisten dengan pola GoRouter |

### `test/auth_session_test.dart` — logika sesi & refresh

| Test | Yang dibuktikan |
|---|---|
| `menolak email tanpa @` / `menolak kata sandi < 6` | validasi terjadi di repository, bukan hanya di form |
| `mengembalikan pasangan access + refresh token` | bentuk token sesuai kontrak mock |
| `menolak refresh token kosong` / `tidak dikenal` | refresh hanya berhasil untuk token yang sah |
| `menghasilkan access token baru dari refresh yang sah` | jalur sukses refresh |
| `nonce token baru aman di semua platform (32-bit)` | **regresi nyata**: `nextInt(1 << 32)` menjadi `0` di web (dart2js) → `RangeError` tepat pada jalur refresh |
| `refresh gagal -> sesi harus dianggap mati` | aturan "tidak ada cara memulihkan → paksa login ulang" |
| `TokenStore.mask` | token terpotong + jumlah karakter; `(belum ada)` untuk kosong |
| `friendlyApiMessage` (401/404/5xx/timeout/non-Dio) | UI hanya menerima pesan siap tampil, bukan exception mentah |

### `test/api_refresh_interceptor_test.dart` — inti Minggu 6

Ini perilaku paling penting minggu ini dan paling mudah salah: **"401 memicu
refresh SEKALI lalu mengulang request; kalau refresh ikut mati, paksa login
ulang"**. Adapter Dio diganti skenario naskah, jadi tidak ada jaringan sama
sekali, tetapi jalur `onError` interceptor tetap berjalan utuh.

| Test | Yang dibuktikan |
|---|---|
| `401 -> refresh -> ulang request -> 200, token baru tersimpan` | tepat **dua** permintaan (asli + satu ulangan); ulangan memakai `Bearer` **baru**; access token baru benar-benar dipersist; refresh token tidak berubah |
| `401 lagi setelah retry -> berhenti, tidak ada loop` | tanpa penanda `extra['campus_notify_retried']`, jumlah permintaan akan tak terhingga — di sini dibuktikan tetap **dua** |
| `refresh ikut gagal -> sesi dibersihkan, error diteruskan` | access **dan** refresh token dibuang; log menyebut `refresh ikut kedaluwarsa` |
| `401 tanpa refresh token -> tidak mencoba refresh sama sekali` | hanya **satu** permintaan; tidak ada panggilan refresh yang sia-sia |
| `respons 200 langsung tidak menyentuh jalur refresh` | jalur bahagia tidak menambah beban |

Catatan implementasi test: `dio.fetch(requestOptions)` memakai objek
`RequestOptions` yang **sama**, sehingga header hasil mutasi interceptor ikut
terlihat pada catatan permintaan pertama. Karena itu adapter menyimpan
**snapshot** nilai header, bukan referensi objeknya.

### `test/simulated_push_service_test.dart` — kanal tiruan

Kanal tiruan ada supaya tiga app state bisa diperagakan **tanpa perangkat
fisik**. Test ini memastikan kanal tiruan menepati janji yang sama dengan FCM
sungguhan:

| Test | Yang dibuktikan |
|---|---|
| `bootstrap mengirim token ke backend dan langganan topik` | `onToken` dipanggil untuk token awal; panjang & pola token menyerupai token FCM asli |
| `rotateToken meniru onTokenRefresh dan mengirim token BARU` | token berubah **dan** dikirim ulang — inilah yang membedakan `onTokenRefresh` dari sekadar `print` |
| `unsubscribe dan subscribe mengubah status topik` | status langganan `pengumuman-kampus` konsisten |
| `emit menyalurkan tiga app state ke rute yang sama` | `foreground/opened/initial` → label `foreground/background/terminated`, semuanya rute `/pengumuman/3` |
| `kanal tiruan tidak menyediakan simulator kedua` | `simulator` mengembalikan dirinya sendiri (panel simulator tidak perlu tahu tipe konkretnya) |

## Pemeriksaan kontrak backend (di luar Flutter)

Jalur refresh hanya bisa dibuktikan kalau ada pihak yang benar-benar
mengembalikan 401. `tool/mock_api_server.js` melakukannya, dan kontraknya
diperiksa tanpa aplikasi Flutter:

```bash
node tool/mock_api_server.js 8787     # terminal 1
node tool/check_api_flow.js           # terminal 2
```

Urutan yang diperiksa persis seperti tuntutan modul:

```
health → login → /me 200 → /me tanpa token 401 → announcements →
POST /devices → /debug/expire → /me 401 → refresh → /me 200 → refresh palsu 401
```

Keluaran terakhir: [`verification/mock_api_flow.txt`](verification/mock_api_flow.txt).

## Hasil

```
00:03 +35: All tests passed!
flutter analyze → No issues found!
```

## Uji manual (definisi selesai modul)

1. Masuk dengan kredensial yang terisi otomatis → mendarat di beranda.
2. Tab **Sesi & API** → access & refresh token tampil **terpotong**.
3. Tekan **Uji 401 → refresh → retry** → respons `HTTP 200` dan log
   memperlihatkan rantai `401 kedaluwarsa → menukar refresh token (sekali saja)
   → ulang GET /me → 200`.
4. Tab **Push & Token** → registration token terpotong, topik berlangganan,
   jejak lifecycle terisi.
5. Tekan **Rotasi token** → token berubah **dan** baris "Token tercatat di
   backend" ikut berubah (bukti `onTokenRefresh` benar-benar mengirim ulang).
6. Tab **Beranda** → tekan **Foreground** → banner lokal muncul; tekan
   **Background** dan **Terminated** → masuk `/pengumuman/3` dengan penanda
   state yang sesuai.
7. Tekan ikon keluar → konfirmasi → kembali ke `/login`; token terhapus.

Hasil tiap langkah direkam pada `screenshots/`.
