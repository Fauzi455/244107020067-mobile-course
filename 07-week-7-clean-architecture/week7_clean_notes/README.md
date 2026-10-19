# Week 7 — Clean Architecture (Clean Notes)

## 1. Tujuan pembelajaran

- Menjelaskan prinsip **SOLID** dan *separation of concerns* lewat kode Flutter.
- Membedakan **feature-first** vs **layer-first** beserta trade-off-nya.
- Menjelaskan tiga layer (**presentation, domain, data**) dan **dependency rule**.
- Membedakan **entity vs model** serta peran **repository, use case, dan DI**.
- Merefactor project Minggu 5 menjadi struktur feature-first yang terpisah layer-nya.
- Menguji use case dengan **repository palsu** tanpa database atau jaringan sungguhan.


## 2. Hasil / Screenshot

Screenshot diambil satu per satu pada **layout mobile** (viewport 390×780,
DPR 2) dari aplikasi yang benar-benar berjalan.

| # | Layar | Berkas |
|---|---|---|
| 1 | Empty state | [`screenshots/01_empty.png`](screenshots/01_empty.png) |
| 2 | Dialog catatan baru | [`screenshots/02_add_dialog.png`](screenshots/02_add_dialog.png) |
| 3 | Daftar catatan — 3 catatan `dirty` | [`screenshots/03_list_dirty.png`](screenshots/03_list_dirty.png) |
| 4 | Detail `/note/:id` | [`screenshots/04_detail.png`](screenshots/04_detail.png) |
| 5 | Setelah sync — badge hilang | [`screenshots/05_after_sync.png`](screenshots/05_after_sync.png) |
| 6 | Pengaturan | [`screenshots/06_settings.png`](screenshots/06_settings.png) |
| 7 | Tema gelap (persist) | [`screenshots/07_settings_dark.png`](screenshots/07_settings_dark.png) |
| 8 | Posts — cache-first read | [`screenshots/08_posts_cached.png`](screenshots/08_posts_cached.png) |
| 9 | Mode offline aktif | [`screenshots/09_offline.png`](screenshots/09_offline.png) |
| 10 | Sync ditolak saat offline (`OfflineFailure`) | [`screenshots/10_offline_sync.png`](screenshots/10_offline_sync.png) |

### 1. Empty state
![Empty](screenshots/01_empty.png)

### 2. Dialog catatan baru
![Add dialog](screenshots/02_add_dialog.png)

### 3. Daftar catatan — tiga catatan belum tersinkron
![List dirty](screenshots/03_list_dirty.png)

### 4. Detail catatan
![Detail](screenshots/04_detail.png)

### 5. Setelah sinkronisasi — badge hilang, antrean nol
![After sync](screenshots/05_after_sync.png)

### 6. Pengaturan
![Settings](screenshots/06_settings.png)

### 7. Tema gelap — preferensi persist di SharedPreferences
![Settings dark](screenshots/07_settings_dark.png)

### 8. Posts — cache-first read
![Posts cached](screenshots/08_posts_cached.png)

### 9. Simulasi offline aktif — catatan tetap terbaca
![Offline](screenshots/09_offline.png)

### 10. Sinkronisasi ditolak saat offline
![Offline sync](screenshots/10_offline_sync.png)

### Before / After (UI sama, struktur beda)

Screenshot "before" diambil dari project Minggu 5 yang tidak diubah
(`week5_offline_notes/screenshots/`), sehingga perbandingan dilakukan pada
aplikasi yang benar-benar berjalan, bukan mockup.

| Fitur | Before — Minggu 5 | After — Minggu 7 |
|---|---|---|
| Empty state | ![before empty](../../05-week-5-local-storage-offline-first/week5_offline_notes/screenshots/01_empty.png) | ![after empty](screenshots/01_empty.png) |
| Daftar dirty | ![before list](../../05-week-5-local-storage-offline-first/week5_offline_notes/screenshots/03_list_dirty.png) | ![after list](screenshots/03_list_dirty.png) |
| Detail catatan | ![before detail](../../05-week-5-local-storage-offline-first/week5_offline_notes/screenshots/04_detail.png) | ![after detail](screenshots/04_detail.png) |
| Setelah sync | ![before sync](../../05-week-5-local-storage-offline-first/week5_offline_notes/screenshots/05_after_sync.png) | ![after sync](screenshots/05_after_sync.png) |
| Pengaturan | ![before settings](../../05-week-5-local-storage-offline-first/week5_offline_notes/screenshots/06_settings.png) | ![after settings](screenshots/06_settings.png) |
| Posts cache | ![before posts](../../05-week-5-local-storage-offline-first/week5_offline_notes/screenshots/08_posts_cached.png) | ![after posts](screenshots/08_posts_cached.png) |


## 3. AI Challenge

Prompt, keluaran awal AI, tabel usulan-vs-keputusan-final, dan checklist
verifikasi ada di [`docs/AI_challenge/`](docs/AI_challenge/README.md).

Ringkasan keputusan yang **menyimpang** dari usulan AI:

| Usulan AI | Keputusan final | Alasan |
|---|---|---|
| Use case untuk setiap CRUD (`AddNote`, `DeleteNote`, `UpdateNote`) | Cukup repository langsung ke notifier; use case hanya `GetNotes` dan `SyncNotes` | Use case per operasi satu baris = over-engineering; lapisan tambahan tanpa aturan bisnis |
| `fpdart`/`dartz` (`Either<Failure, T>`) | *record* Dart `({hasil, Failure? failure})` | Mengikuti contoh modul, tanpa dependensi tambahan, tetap eksplisit sukses/gagal |
| `get_it` untuk DI | Riverpod provider saja | Riverpod sudah ada; dua sistem DI = dua sumber kebenaran |
| Entity `Note` tetap membawa `toMap/fromMap` | Mapping dipindah ke `NoteModel` | Entity di domain harus bebas detail penyimpanan |
| `core/api_client.dart` (Dio di `core/`) | `shared/data/network/api_client.dart` | `lib/core` wajib steril (grep no. 2) |
| Folder `domain/repositories` + `data/repositories` digabung | Dipisah | Interface di domain, implementasi di data — inti dependency rule |

---

## 4. Refactoring Challenge

Detail: [`docs/refactoring.md`](docs/refactoring.md).

1. **Fitur kedua (`posts`) dan ketiga (`settings`) ikut dibersihkan** — bukan
   hanya `notes`. Ketiganya punya entity + repository interface + impl +
   provider wiring sendiri.
2. **Formatting & parsing rute diekstrak** ke `lib/core/format.dart`
   (`formatDateTime`, `formatRelative`, `parseNoteId`, `parseIsoDate`) sehingga
   bisa diuji tanpa widget.
3. **Semua exception mentah menjadi `Failure`** di batas layer data
   (`LocalFailure`, `NetworkFailure`, `OfflineFailure`); UI hanya menerima
   `message` lewat `FailureException`.

---

## Refleksi

1. **Mengapa interface repository harus tinggal di domain, bukan di data?**
   Karena `domain` yang membutuhkan operasi itu; `data` hanya menyediakan cara
   memenuhinya. Bila interface ditaruh di `data`, `domain` harus mengimpor `data`
   → panah dependensi terbalik, `domain` jadi tahu SQLite/Dio, dan use case tidak
   lagi bisa diuji tanpa database. Saat itu terjadi, "Clean Architecture" hanya
   jadi tata letak folder.

2. **Kapan use case benar-benar dibutuhkan?**
   Saat operasi menggabungkan lebih dari satu repository, atau memuat aturan
   bisnis/urutan langkah. `SyncNotes` adalah contohnya: hitung → tolak bila
   offline → upload → tandai bersih **hanya setelah sukses**. Untuk CRUD
   satu-baris, repository langsung ke notifier sudah cukup dan lebih jujur.

3. **Apa biaya over-engineering bagi tim kecil?**
   Setiap use case tambahan berarti satu file, satu test, dan satu titik yang
   harus diubah setiap kali kontrak berubah — tanpa nilai bisnis. Biaya itu
   sepadan ketika logika tumbuh (multi-sumber data, aturan konflik, audit), dan
   tidak sepadan untuk CRUD sederhana.

4. **Bagian usulan AI yang ditolak?**
   Use case per CRUD, `fpdart`, dan `get_it` (lihat tabel di atas). Yang
   diterima: pemisahan interface/implementasi dan penyatuan wiring DI di
   provider.
