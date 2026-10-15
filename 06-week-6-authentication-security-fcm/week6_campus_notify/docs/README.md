# docs/ — Campus Notify (Minggu 6)

Folder ini memuat bukti dan catatan yang dituntut modul Minggu 6. Modul
menyatakan nilai minggu ini ada pada **pembuktian perilaku nyata** (screenshot +
log), bukan pada kode yang dihasilkan AI — karena itu setiap berkas di sini
menyimpan jejaknya.

| Berkas | Isi |
|---|---|
| [`testing.md`](testing.md) | Daftar 35 test, apa yang dibuktikan masing-masing, dan cara menjalankannya |
| [`three_app_states.md`](three_app_states.md) | Matriks pengujian foreground / background / terminated + cara mengujinya dengan Firebase Console sungguhan |
| [`refactoring.md`](refactoring.md) | Tiga Refactoring Challenge modul beserta alasannya |
| [`firebase_setup.md`](firebase_setup.md) | Konfigurasi native FCM yang sudah dipasang, dan **langkah yang harus Anda lakukan di Firebase Console** |
| [`screenshots.md`](screenshots.md) | Cara screenshot diambil (viewport, urutan langkah, alat) |
| [`AI_challenge/`](AI_challenge/README.md) | Prompt, keluaran awal AI, tabel usulan-vs-keputusan, checklist verifikasi |
| [`verification/`](verification/) | Keluaran mentah `flutter analyze`, `flutter test`, dan pemeriksaan kontrak mock API |

## Ringkasan status

| Ketentuan modul | Status | Bukti |
|---|---|---|
| Login + guard route | ✅ | `screenshots/01_login.png`, `lib/app_router.dart` |
| Token di secure storage | ✅ | `screenshots/04_sesi_token.png`, `lib/data/token_store.dart` |
| Refresh sekali saat 401, logout bila refresh mati | ✅ | `screenshots/05_api_401_refresh.png`, `test/api_refresh_interceptor_test.dart` |
| Permission + `getToken` + `onTokenRefresh` → backend | ✅ | `screenshots/06_push_token.png`, `screenshots/10_rotate_token.png` |
| Topik `pengumuman-kampus` | ✅ | `screenshots/06_push_token.png`, `screenshots/10_rotate_token.png` |
| Klik notifikasi → `/pengumuman/:id` di tiga state | ✅ | `screenshots/07`–`09`, `docs/three_app_states.md` |
| Minimal 2 test lulus | ✅ (35 test) | `docs/verification/flutter_test.txt` |
| AI Challenge terdokumentasi | ✅ | `docs/AI_challenge/` |
| Screenshot `fcm-console-test.png` | ⏳ butuh Firebase + perangkat | `docs/firebase_setup.md` §5 |
