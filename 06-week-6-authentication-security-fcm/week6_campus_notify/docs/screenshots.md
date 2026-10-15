# Pengambilan screenshot (layout mobile)

Semua berkas di `screenshots/` diambil dari **aplikasi yang benar-benar
berjalan**, bukan mockup, dengan viewport layout mobile:

| Parameter | Nilai |
|---|---|
| Viewport | 390 × 780 (rasio ponsel) |
| Device scale factor | 2 → berkas 780 × 1560 px |
| Mode | mobile + touch |
| Output | PNG |

## Mengapa browser?

Lingkungan pengembangan tugas ini tidak punya emulator Android dengan Google
Play Services (`flutter doctor` → *Android toolchain: cmdline-tools component is
missing*, dan tidak ada AVD), sementara FCM di web tidak berjalan tanpa
konfigurasi Firebase penuh. Karena itu aplikasi dijalankan di Chrome dengan
viewport ponsel, dan **kanal push tiruan** (`SimulatedPushService`) yang
menyalurkan ketiga app state.

Yang penting: kanal tiruan tidak "memalsukan tampilan". Ia menyuntikkan pesan ke
`PushService.events`, yaitu **jalur penanganan yang sama** dengan
`FirebasePushService` — `main.dart` → `NotificationPresenter.show()` untuk
foreground, dan `router.go(data.route)` untuk background/terminated. Yang berbeda
hanya sumber pesannya, bukan logika penanganannya. Jadi screenshot ketiga state
tetap sah sebagai bukti perilaku penanganan.

Jalur Android (target utama codelab) memakai `FirebasePushService` sungguhan;
cara mengaktifkannya ada di [`firebase_setup.md`](firebase_setup.md).

## Cara menjalankan

```bash
# sekali saja
flutter pub get
npm install puppeteer-core --prefix tool

# backend tiruan (butuh 401 sungguhan untuk jalur refresh)
node tool/mock_api_server.js 8787

# aplikasi
flutter build web --release
node tool/serve_web.js build/web 8123
```

## Cara mengambil satu per satu

Sesuai ketentuan, screenshot diambil **satu langkah per proses**: aplikasi
dibuka, satu interaksi dilakukan, screenshot diambil, lalu browser **ditutup**
sebelum langkah berikutnya dibuka. `FRESH=1` menghapus profil Chrome lebih dulu
supaya setiap langkah dimulai dari keadaan "belum login" — deterministik dan
tidak bergantung pada langkah sebelumnya.

```bash
FRESH=1 node tool/screenshot_web.js screenshots/01_login.png login
FRESH=1 node tool/screenshot_web.js screenshots/02_login_error.png login_error
FRESH=1 node tool/screenshot_web.js screenshots/03_beranda.png beranda
FRESH=1 node tool/screenshot_web.js screenshots/04_sesi_token.png sesi
FRESH=1 node tool/screenshot_web.js screenshots/05_api_401_refresh.png api_401
FRESH=1 node tool/screenshot_web.js screenshots/06_push_token.png push
FRESH=1 node tool/screenshot_web.js screenshots/07_push_foreground.png foreground
FRESH=1 node tool/screenshot_web.js screenshots/08_push_background_deeplink.png background
FRESH=1 node tool/screenshot_web.js screenshots/09_push_terminated_deeplink.png terminated
FRESH=1 node tool/screenshot_web.js screenshots/10_rotate_token.png rotate
FRESH=1 node tool/screenshot_web.js screenshots/11_logout_dialog.png logout_dialog
FRESH=1 node tool/screenshot_web.js screenshots/12_deep_link_manual.png announcement
```

| # | Langkah | Hasil | Yang dibuktikan |
|---|---|---|---|
| 1 | buka aplikasi (belum login) | `01_login.png` | guard route mengarahkan ke `/login` |
| 2 | isi email & kata sandi tidak valid | `02_login_error.png` | validasi form sebelum menyentuh jaringan |
| 3 | masuk | `03_beranda.png` | sesi tersimpan, pengumuman diambil dari API dengan `Bearer` |
| 4 | tab **Sesi & API** | `04_sesi_token.png` | access & refresh token tampil **terpotong** |
| 5 | tekan **Uji 401 → refresh → retry** | `05_api_401_refresh.png` | `401 → refresh → retry` berakhir `HTTP 200` + log rantai |
| 6 | tab **Push & Token** | `06_push_token.png` | registration token terpotong, topik, jejak lifecycle |
| 7 | tekan **Foreground** | `07_push_foreground.png` | banner lokal muncul (sistem tidak menampilkannya sendiri) |
| 8 | tekan **Background** | `08_push_background_deeplink.png` | deep link `/pengumuman/3`, state `background` |
| 9 | tekan **Terminated** | `09_push_terminated_deeplink.png` | deep link `/pengumuman/3`, state `terminated` |
| 10 | tekan **Rotasi token** | `10_rotate_token.png` | token **baru** terkirim ulang ke backend |
| 11 | tekan ikon keluar | `11_logout_dialog.png` | konfirmasi bahwa seluruh token akan dihapus |
| 12 | ketuk baris pertama pengumuman | `12_deep_link_manual.png` | navigasi manual ke rute yang sama |

## Koordinat tidak ditebak

Flutter web merender ke `<canvas>`, jadi koordinat tombol tidak bisa dibaca dari
DOM biasa. Koordinat pada `tool/screenshot_web.js` diambil dari *accessibility
tree* Flutter lewat:

```bash
node tool/dump_semantics.js home      # atau: login, session, push, announcement, logout_dialog
```

Skrip itu mengklik placeholder "Enable accessibility" lebih dulu, lalu mencetak
setiap node beserta koordinat pusatnya.

## Catatan lingkungan

- Chrome yang dipakai: `C:\Program Files (x86)\Google\Chrome\Application\chrome.exe`
  (bisa diganti lewat variabel `CHROME_EXECUTABLE`).
- Variabel lain: `APP_URL`, `PROFILE_DIR`.
- Sebelum mengambil ulang, pastikan tidak ada proses Chrome yang masih memegang
  `tool/.chrome-profile` — kalau ada, langkah pertama akan gagal dengan
  `EPERM` / *"browser is already running"*.
