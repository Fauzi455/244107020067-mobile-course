# Pengambilan screenshot (layout mobile)

Semua screenshot di `screenshots/` diambil dari **aplikasi yang berjalan**,
bukan mockup, dengan viewport layout mobile:

| Parameter | Nilai |
|---|---|
| Viewport | 390 × 780 (rasio ponsel) |
| Device scale factor | 2 → berkas 780 × 1560 px |
| Mode | mobile + touch |
| Output | PNG |

## Mengapa browser?

Lingkungan pengembangan tugas ini tidak punya emulator Android (`flutter
emulators` → "No emulators available") dan toolchain Visual Studio untuk build
Windows desktop juga tidak tersedia. Karena itu aplikasi dijalankan di Chrome
dengan viewport ponsel. Supaya SQLite tetap bekerja di web, ditambahkan
`sqflite_common_ffi_web` dan factory database web
(`lib/shared/data/local/db_factory_web.dart`) yang dipilih lewat *conditional
import* — pola yang sama seperti `db_factory_io.dart` pada Minggu 5.

Jalur Android (target utama codelab) tetap memakai `sqflite` native.

## Cara menjalankan

```bash
dart run sqflite_common_ffi_web:setup   # sekali saja -> web/sqlite3.wasm
flutter run -d chrome
```

## Cara mengambil satu per satu

Sesuai ketentuan, screenshot diambil **satu langkah per proses**: aplikasi
dibuka, satu interaksi dilakukan, screenshot diambil, lalu browser **ditutup**
sebelum langkah berikutnya dibuka. Database SQLite dan preferensi tetap
konsisten karena memakai profil browser yang sama.

Untuk langkah yang membutuhkan data (detail, sync, offline), data disiapkan
ulang di dalam langkah itu sehingga hasilnya deterministik dan tidak menumpuk
catatan dari langkah sebelumnya.

Urutan pengambilan:

| # | Langkah | Hasil |
|---|---|---|
| 1 | buka aplikasi (database kosong) | `01_empty.png` |
| 2 | tekan FAB "Catatan" | `02_add_dialog.png` |
| 3 | isi 3 catatan | `03_list_dirty.png` |
| 4 | ketuk baris pertama | `04_detail.png` |
| 5 | tekan ikon sinkron | `05_after_sync.png` |
| 6 | tab Pengaturan | `06_settings.png` |
| 7 | aktifkan Tema gelap | `07_settings_dark.png` |
| 8 | tab Posts | `08_posts_cached.png` |
| 9 | aktifkan Simulasi offline → tab Catatan | `09_offline.png` |
| 10 | tekan ikon sinkron saat offline | `10_offline_sync.png` |

Skrip otomasi pengambilan screenshot disertakan di
[`tool/screenshot_web.js`](../tool/screenshot_web.js) beserta
[`tool/serve_web.js`](../tool/serve_web.js) dan
[`tool/README.md`](../tool/README.md), sehingga proses ini bisa direproduksi.
Skrip tersebut berada di luar `lib/` agar tidak mengotori source aplikasi.
