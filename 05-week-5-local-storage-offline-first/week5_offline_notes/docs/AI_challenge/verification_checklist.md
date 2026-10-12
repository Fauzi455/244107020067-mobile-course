# AI Verification Checklist

Checklist ini diisi sebelum rekomendasi AI (output awal di
[`output_ai_initial.md`](output_ai_initial.md)) diterima.

## Checklist

- [x] **Apakah AI menempatkan daftar catatan di SharedPreferences?**
  **Ya, dan DITOLAK.** Koleksi data sebagai satu string JSON rapuh: setiap
  update menulis ulang seluruh daftar, tidak ada query parsial/urut, dan tidak
  mendukung antrean sync. Keputusan: catatan masuk **SQLite (sqflite)**.

- [x] **Apakah skema AI mendukung antrean sync (`dirty`/`updated_at`)?**
  **Tidak** pada output awal (hanya `title`/`body`). Sudah ditambahkan kolom
  `dirty INTEGER` dan `updated_at TEXT` + index. `syncNotes` memakai keduanya.

- [x] **Apakah klaim "real-time" AI didukung stream?**
  **Tidak.** AI menyebut Drift "real-time" tanpa menunjukkan `watch()`.
  Dikoreksi: reaktivitas Drift berasal dari `watch()` (stream), sedangkan
  sqflite tidak punya — karena itu UI di-refresh via `ref.invalidate` provider.

- [x] **Apakah estimasi boilerplate AI masuk akal?**
  Dicek dengan mencoba `flutter pub add drift drift_flutter dev:build_runner
  dev:drift_dev`. Benar bahwa Drift butuh kode generator (`build_runner`),
  sehingga boilerplate lebih besar daripada sqflite untuk codelab ini.

- [x] **Keputusan final boleh berbeda dari AI selama berargumen.**
  Keputusan saya: **SharedPreferences (preferensi) + SQLite/sqflite (catatan
  + cache)**. Ini berbeda dari rekomendasi awal AI (Hive + SharedPreferences)
  dan beralasan (lihat tabel di `README.md`).

## Catatan Temuan

1. **Pola "inject `openDb`" sangat membantu testing.** Repository menerima
   `Future<Database> Function()? openDb` sehingga test memakai
   `FakeNoteRepository` tanpa menyentuh SQLite. Ini menjawab kriteria
   "kemudahan testing" pada perbandingan.

2. **Dua penyesuaian di luar modul (didokumentasikan).**
   - Menambahkan `go_router` (dari Refactoring Challenge no. 3).
   - Menambahkan dukungan web/desktop untuk sqflite (`sqflite_common_ffi`,
     `sqflite_common_ffi_web`) **khusus** agar demo/screenshot bisa dijalankan
     di lingkungan ini. Pada target Android, jalur yang dipakai tetap
     `sqflite` native.

3. **Konsistensi SharedPreferences di web.** `shared_preferences` di web
   memakai localStorage, jadi tema & waktu terakhir dibuka tetap persist —
   perilaku setara dengan perangkat.
