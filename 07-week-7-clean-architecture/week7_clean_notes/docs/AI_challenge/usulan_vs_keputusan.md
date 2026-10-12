# Tabel usulan AI vs keputusan final

Keputusan final **milik mahasiswa**; AI hanya memberi bahan. Kolom terakhir
menjelaskan alasan teknis yang bisa dipertanggungjawabkan saat demo.

| # | Usulan AI | Keputusan final | Alasan teknis |
|---|---|---|---|
| 1 | Ganti Riverpod → BLoC (`NotesBloc`/`Event`/`State`) | **Tolak.** Tetap Riverpod | Minggu 3–6 sudah memakai Riverpod dan provider sudah memenuhi peran DI. Mengganti state management bukan bagian dari "memindahkan dan memisahkan kode yang sudah jalan"; risikonya besar tanpa nilai tambah untuk modul ini |
| 2 | `fpdart`/`dartz` → `Either<Failure, T>` | **Tolak.** *Record* Dart `({hasil, Failure? failure})` | Modul secara eksplisit menawarkan record sebagai contoh kontrak; hasilnya sama eksplisit tanpa dependensi tambahan. `fpdart` boleh dipakai, tapi menambah satu konsep (monad) yang harus dipelajari seluruh tim |
| 3 | Base class `UseCase<Type, Params>` + use case untuk **setiap** operasi (`AddNote`, `UpdateNote`, `DeleteNote`, `GetNotes`, `SyncNotes`) | **Sebagian.** Hanya `GetNotes` dan `SyncNotes` | Use case untuk CRUD satu baris = over-engineering: satu file + satu test tambahan tanpa aturan bisnis. `SyncNotes` dipertahankan karena menggabungkan beberapa operasi + aturan urutan. Keputusan ini dicatat agar konsisten |
| 4 | `get_it` + `injectable` untuk DI | **Tolak.** Riverpod provider | Riverpod sudah menjadi container DI. Dua sistem DI = dua sumber kebenaran; mengganti fake saat test jadi tidak konsisten |
| 5 | Entity `Note` tetap membawa `toMap/fromMap` | **Tolak.** Mapping hanya di `NoteModel` | Modul mendefinisikan entity sebagai objek bisnis murni tanpa mapping. Kalau entity tahu kolom database, `domain` ikut berubah setiap skema berubah |
| 6 | `api_client.dart` (Dio) di `lib/core/network/` | **Tolak.** `lib/shared/data/network/api_client.dart` | Grep sterilitas no. 2 modul memeriksa `lib/core` — Dio di sana otomatis melanggar. `shared/data` adalah tempat infrastruktur berframework |
| 7 | Satu `AppRepository` besar untuk auth + notes + posts | **Tolak.** Satu kontrak per fitur | Melanggar *Interface Segregation*: klien dipaksa bergantung pada method yang tidak dipakai, dan satu perubahan kontrak berdampak ke semua fitur |
| 8 | `SharedPreferences` langsung di dalam entity settings | **Tolak.** Datasource di `data` | Entity di domain harus murni Dart. Akses plugin adalah detail data |
| 9 | Interface repository di `domain`, implementasi di `data` | **Terima** | Inti dependency rule; memungkinkan `domain` diuji tanpa SQLite |
| 10 | Pecah `lib/data/providers.dart` per fitur | **Terima** | Satu file untuk semua fitur membuat perubahan pada satu fitur berisiko menyentuh fitur lain |
| 11 | Pindahkan formatting tanggal keluar dari widget | **Terima**, ditambah `parseNoteId` | Refactoring Challenge modul; membuat formatting bisa diuji tanpa widget |
| 12 | Ganti exception mentah dengan `Failure` | **Terima**, ditambah `OfflineFailure` | UI tidak boleh menerima `DatabaseException`; mode offline perlu pesan domain sendiri |

## Keputusan yang tidak diusulkan AI tetapi diambil sendiri

| Keputusan | Alasan |
|---|---|
| `settings` dijadikan **fitur ketiga** yang direfactor penuh | Modul melarang "satu fitur bersih dan sisanya kotor". `settings` sebelumnya hanya menumpang provider notes |
| `lib/core/format.dart` diberi `parseNoteId` dan `parseIsoDate` | Parsing rute dan parsing ISO adalah logika murni; menaruhnya di `core` menghilangkannya dari `routes.dart` dan dari widget |
| `syncNotes` diubah dari fungsi bebas menjadi use case `SyncNotes` | Aturan "tandai bersih hanya setelah upload sukses" adalah aturan bisnis, bukan detail data |
| `home_shell_page.dart` diletakkan di `features/home/presentation/pages/` | Shell navigasi bukan domain fitur, tetapi tetap perlu tempat yang jelas agar tidak kembali ke `lib/pages/` |
| Grep no. 3 diarahkan ke `presentation/pages` + `presentation/widgets` | Modul menulis `lib/providers`, folder yang tidak ada lagi di struktur feature-first. Wiring DI **memang** ada di `presentation/providers` (contoh resmi modul juga begitu), jadi yang diperiksa adalah `pages/` dan `widgets/` |

## Pertanyaan reflektif (dijawab di README bagian Refleksi)

1. Mengapa interface repository harus tinggal di domain?
2. Kapan use case benar-benar dibutuhkan?
3. Apa biaya over-engineering bagi tim kecil?
4. Bagian mana dari usulan AI yang ditolak dan mengapa?
