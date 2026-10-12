# Offline-First — Strategi & Aturan Konflik

Dokumen ini menjelaskan mekanisme offline-first yang diterapkan, langkah
simulasi offline, serta aturan penyelesaian konflik.

## Tiga Mekanisme Inti

### 1. Cache-first read (data bacaan — Posts)

`lib/data/sync.dart` + `cachedPostsProvider`:

```
build() -> baca tabel cached_posts -> kembalikan SEGERA (UI tidak blank saat offline)
        -> Future.microtask(refreshFromNetwork)  // background
refreshFromNetwork() -> GET /posts -> simpan ke cached_posts -> state = AsyncData(posts)
```

- Saat offline / `forceOffline` aktif: langkah background dilewati / gagal
  diam-diam, dan **cache tetap ditampilkan**.
- Bila cache kosong **dan** jaringan gagal → baru `AsyncError` (dengan tombol
  "Coba lagi").

### 2. Dirty flag (data tulis — Catatan)

- Setiap `addNote`/`updateNote` menulis `dirty = 1`.
- `deleteNote` langsung menghapus baris (belum ada outbox; lihat catatan di bawah).
- Badge di AppBar (`Badge.count`) dan badge per-baris (`NoteTile`) membaca
  `countDirty()` / `note.dirty`.

### 3. Antrean sinkronisasi

`syncNotes(repo, {forceOffline})` di `lib/data/sync.dart`:

1. Hitung catatan `dirty` (`countDirty`). Bila 0 → selesai tanpa aksi.
2. "Upload" (di codelab: `Future.delayed(1s)`; di produksi: kirim ke REST API).
3. `markAllSynced()` — **hanya** setelah server sukses.

`SyncController.sync()` memanggilnya, lalu `ref.invalidate(notesProvider)` agar
UI (termasuk badge) langsung refresh.

## Aturan Konflik: Last-Write-Wins berdasarkan `updated_at`

- Setiap perubahan menyimpan `updated_at` (ISO-8601).
- Saat sinkronisasi dua arah di project nyata: bandingkan `updated_at` lokal vs
  server; yang **lebih baru menang**.
- Alasan memilih aturan ini: sederhana, deterministik, dan cukup untuk catatan
  pribadi satu pengguna. Tanpa aturan eksplisit, sinkronisasi bisa menimpa data
  secara diam-diam.

## Simulasi Offline yang Deterministik

Selain mode pesawat sungguhan, tersedia toggle **"Simulasi offline"**
(`forceOfflineProvider`) di tab Pengaturan agar demo tidak bergantung Wi-Fi:

| Langkah | Hasil observasi |
|---|---|
| 1. Tambah 2 catatan | Muncul badge **"Belum tersinkron"** + `Badge.count = 2` |
| 2. Aktifkan "Simulasi offline" | Chip **Offline** muncul; catatan tetap tampil & bisa dibuka |
| 3. Tekan ikon sinkron saat offline | SnackBar "Mode offline aktif..." — catatan **tetap dirty** |
| 4. Matikan "Simulasi offline" | Tersedia untuk sync kembali |
| 5. Tekan ikon sinkron | SnackBar "2 catatan berhasil disinkronkan."; badge hilang |
| 6. Buka tab Posts saat offline | Daftar dari cache `cached_posts` tetap tampil |

Bukti screenshot: `screenshots/03_list_dirty.png` (sebelum) →
`screenshots/05_after_sync.png` (sesudah), dan `screenshots/09_offline.png`.

## Kapan Butuh Tabel Outbox Terpisah?

Saat ini `dirty` pada tabel `notes` sudah cukup karena hanya ada satu jenis
operasi tulis (create/update). **Tabel outbox** terpisah menjadi perlu bila:

- ada operasi **hapus** yang harus dikirim ke server (perlu `pending_delete`),
- urutan operasi penting (buat lalu ubah sebelum sempat sync),
- banyak entitas/endpoint dalam satu antrean.

Untuk Minggu 5 (satu entitas, satu aturan konflik) `dirty` sudah memadai.
