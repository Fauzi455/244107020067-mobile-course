# Week 5 — Local Storage & Offline-First (Offline Notes)

## Tujuan

- Menjelaskan perbedaan penyimpanan key-value, relasional, dan NoSQL.
- Menyimpan preferensi (tema, terakhir dibuka) dengan **SharedPreferences**.
- Menerapkan **CRUD catatan** dengan **SQLite (sqflite)** lewat repository lokal.
- Menerapkan pola **offline-first**: cache-first read, dirty flag, dan antrean sinkronisasi.
- Menampilkan state **loading, error, empty, success** untuk data lokal dengan Riverpod.
- Menguji repository lokal dengan **repository palsu** (tanpa database sungguhan).

## Fitur Utama

1. **Preferensi (SharedPreferences)** — tema gelap/terang dan waktu terakhir
   dibuka, terpusat di `PrefsRepository`.
2. **CRUD catatan (SQLite/sqflite)** — tambah, baca, ubah, hapus; daftar urut
   `updated_at DESC`; lewat `NoteRepository`.
3. **Dirty flag + antrean sync** — setiap perubahan lokal menandai `dirty = 1`;
   `syncNotes` menandai bersih hanya setelah "server" sukses.
4. **Cache-first read** — tabel `cached_posts` menampilkan data seketika, lalu
   refresh dari jaringan di background.
5. **Empat state UI** — loading, error (+ retry), empty, dan success.
6. **Simulasi offline deterministik** — toggle `forceOffline` agar demo tidak
   bergantung Wi-Fi.
7. **Halaman detail `/note/:id`** (GoRouter) — membaca dari repository lokal.
8. **11 test lulus** — model, provider palsu, logika sync, dan widget.


## Hasil / Screenshot


### Layar kosong (empty state)
![Empty](screenshots/01_empty.png)

### Dialog tambah catatan
![Add dialog](screenshots/02_add_dialog.png)

### Daftar catatan — badge "Belum tersinkron" & antrean sync (3)
![List dirty](screenshots/03_list_dirty.png)

### Detail catatan `/note/:id`
![Detail](screenshots/04_detail.png)

### Setelah sinkronisasi — badge hilang
![After sync](screenshots/05_after_sync.png)

### Pengaturan — tema, terakhir dibuka, simulasi offline
![Settings](screenshots/06_settings.png)

### Tema gelap (persist di SharedPreferences)
![Settings dark](screenshots/07_settings_dark.png)

### Posts — cache-first read
![Posts cached](screenshots/08_posts_cached.png)

### Mode offline — catatan tetap terbaca, badge dirty tetap akurat
![Offline](screenshots/09_offline.png)

## Uji Mode Pesawat (Offline-First)

1. Tambah 2 catatan → muncul badge **"Belum tersinkron"** dan `Badge.count`.
2. Aktifkan mode pesawat (atau toggle **Simulasi offline**) → catatan tetap
   tampil, bisa dibuka/diedit/dihapus.
3. Tekan ikon sinkron → SnackBar "Mode offline aktif..." (catatan tetap dirty).
4. Nyalakan koneksi → tekan sinkron → "2 catatan berhasil disinkronkan.",
   badge kembali ke 0.
5. Tab **Posts** saat offline → daftar dari cache tetap tampil.

Detail langkah + aturan konflik (**last-write-wins** berdasarkan `updated_at`):
[`docs/offline_first.md`](docs/offline_first.md).


## AI Prompt Challenge & Refactoring Challenge

- Perbandingan storage, keputusan final, dan checklist verifikasi ada di
  [`docs/AI_challenge/`](docs/AI_challenge/README.md).
- Tiga refactoring wajib (ekstrak `NoteTile`, pindahkan cache/sync ke
  `sync.dart`, halaman detail `/note/:id`) ada di
  [`docs/refactoring.md`](docs/refactoring.md).

## Refleksi

1. Mengapa catatan tidak boleh di SharedPreferences?
  
     Jawab : SharedPreferences hanya cocok untuk nilai primitif kecil. Menyimpan koleksi sebagai satu string JSON
      membuat query, update parsial, dan sinkronisasi rapuh serta lambat saat data bertambah. Koleksi selalu masuk database
   
2. Kapan cache-first cukup, kapan butuh strategi lain?
  
     Jawab : Cache-first cocok untuk data yang jarang berubah (daftar post, katalog). Untuk data real-time (harga, chat)
      gunakan network-first, agar pengguna tidak melihat nilai basi

3. Bagaimana dirty flag menjadi antrean sync tanpa memblokir UI?

      Jawab : Perubahan lokal ditulis ke SQLite dan langsung tampil (UI tidak menunggu jaringan); `dirty = 1` menandai pekerjaan
         tertunda yang diproses `syncNotes` di latar. Tabel **outbox** terpisah menjadi perlu saat ada operasi hapus, urutan
         operasi, atau banyak entitas.
   
4. Bagian rekomendasi AI yang ditolak?

      Jawab : AI mengusulkan catatan di SharedPreferences dan preferensi di Hive — keduanya ditolak karena tidak
         sesuai kebutuhan


## Error Umum & Solusi

| Gejala | Penyebab | Solusi |
|---|---|---|
| `MissingPluginException` (shared_preferences/sqflite) | Hot restart setelah tambah plugin | Hentikan aplikasi, `flutter run` ulang (bukan hot reload) |
| `table notes already exists` | `onCreate` jalan dua kali / versi tidak naik | Naikkan `version` + `onUpgrade`, atau uninstall saat dev |
| Badge dirty tidak pernah nol | `markAllSynced` tidak dipanggil | Panggil hanya setelah server sukses; cek `countDirty` |
| UI tidak refresh setelah mutasi | Lupa `ref.invalidate(notesProvider)` | Invalidasi di caller (notifier), bukan di widget acak |
| Test menyentuh database sungguhan | Repository asli dipakai | Gunakan `FakeNoteRepository` via `overrideWithValue` |


