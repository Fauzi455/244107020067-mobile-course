# Praktikum 1 & 2 — Memetakan file ke layer dan menandai pelanggaran

Dokumen ini mencatat langkah **sebelum** refactor: membaca project Minggu 5
(`week5_offline_notes`), memetakan tiap file ke layer, dan menandai tiga
pelanggaran klasik. Snapshot kode lama tidak diubah sehingga bisa dibandingkan.

## 1. Peta file → layer (kondisi Minggu 5)

| File | Layer saat itu | Masalah |
|---|---|---|
| `lib/main.dart` | presentation (bootstrap) | memanggil `PrefsRepository()` langsung, bukan lewat provider |
| `lib/app_router.dart` | presentation | parsing `id` rute di dalam `builder` — logika parsing tidak bisa diuji terpisah |
| `lib/pages/home_page.dart` | presentation | mencampur shell navigasi; tidak masalah besar, tapi sebaiknya bukan bagian domain fitur |
| `lib/pages/notes_page.dart` | presentation | memanggil `ref.read(syncControllerProvider.notifier).sync()`; menangani `SyncOfflineException` yang dilempar dari layer data |
| `lib/pages/note_detail_page.dart` | presentation | `_formatTime()` (formatting) didefinisikan privat di file halaman |
| `lib/pages/cached_posts_page.dart` | presentation | bersih — hanya membaca provider |
| `lib/pages/settings_page.dart` | presentation | `_prettyTime()` (formatting) privat di file halaman |
| `lib/widgets/note_tile.dart` | presentation | `_formatTime()` privat; masih menerima entity yang **juga** model |
| `lib/widgets/note_editor_dialog.dart` | presentation | menerima `WidgetRef` sebagai parameter fungsi (kebocoran DI ke tanda tangan fungsi) |
| `lib/data/local/note.dart` | data (+ entity tercampur) | entity **dan** `toMap/fromMap/copyWith` dalam satu kelas → domain ikut tahu bentuk baris DB |
| `lib/data/repositories/note_repository.dart` | data (+ kontrak tercampur) | interface & implementasi satu kelas; melempar exception mentah, tidak ada `Failure` |
| `lib/data/providers.dart` | presentation (state) | satu file memuat **semua** fitur; `SyncController` memanggil fungsi bebas berisi aturan bisnis |
| `lib/data/sync.dart` | data | `syncNotes()` = aturan bisnis; `readCachedPosts()`/`writeCachedPosts()` dipanggil langsung dari provider |
| `lib/data/prefs.dart` | data | kelas konkret tanpa kontrak domain |
| `lib/data/api_client.dart` | data | OK bila hanya dipakai repository |
| `lib/data/local/db.dart` + `db_factory_*` | data | OK |
| `lib/data/models/post.dart` | data | model **sekaligus** entity (punya `fromJson/toJson`) |
| `lib/data/local/note.dart` (`copyWith`) | data | dipakai juga oleh presentation |

## 2. Tiga pelanggaran klasik (hasil grep manual)

```
# Widget yang menyentuh jaringan / database langsung
rg "Dio\(|http\.|openDatabase|SharedPreferences\.getInstance|FlutterSecureStorage" lib/pages lib/widgets
   -> lib/data/providers.dart memanggil readCachedPosts()/fetchPostsFromNetwork()
      (fungsi bebas yang di dalamnya membuka DB & Dio), lalu hasilnya
      "dilempar" ke widget lewat provider.

# Logika bisnis di dalam build()
rg "DateFormat|jsonDecode|\.toIso8601String" lib/pages lib/widgets
   -> lib/pages/note_detail_page.dart  : _formatTime()
   -> lib/pages/settings_page.dart     : _prettyTime()
   -> lib/widgets/note_tile.dart       : _formatTime()

# Instansiasi manual (DI bocor)
rg "Repository\(|Dio\(BaseOptions" lib/pages lib/providers
   -> lib/data/providers.dart : NoteRepository(), PrefsRepository(), createDio()
   -> lib/main.dart           : PrefsRepository()
```

Ketiga temuan di atas menjadi daftar item refactor. Setelah Praktikum 3,
targetnya nol hasil di folder presentation — lihat
[`verification/grep_sterilitas.txt`](verification/grep_sterilitas.txt).

## 3. Struktur target (gambar sebelum menulis kode)

Untuk fitur `notes`:

```
lib/
├── core/
│   ├── failures.dart        # Failure domain (murni Dart)
│   └── format.dart          # formatting + parsing rute (murni Dart)
├── shared/data/             # infrastruktur lintas fitur
├── features/
│   └── notes/
│       ├── domain/
│       │   ├── entities/note.dart
│       │   ├── repositories/note_repository.dart   # interface!
│       │   └── usecases/{get_notes,sync_notes}.dart
│       ├── data/
│       │   ├── models/note_model.dart
│       │   ├── datasources/notes_local_datasource.dart
│       │   └── repositories/note_repository_impl.dart
│       └── presentation/
│           ├── providers/notes_providers.dart      # notifier + DI
│           ├── pages/{notes_page,note_detail_page}.dart
│           └── widgets/{note_tile,note_editor_dialog}.dart
└── routes.dart
```

**Keputusan yang diambil sendiri (bukan menyalin usulan AI):**

1. `core/` dipertahankan murni Dart, sehingga Dio dipindah ke
   `shared/data/network/`. Modul menulis grep sterilitas untuk
   `lib/features/*/domain` **dan** `lib/core`, jadi menaruh Dio di `core/`
   otomatis melanggar.
2. Use case **tidak** dibuat untuk CRUD satu baris. Hanya `GetNotes` (jalur baca
   daftar, sesuai contoh modul) dan `SyncNotes` (punya aturan bisnis nyata).
3. `settings` dijadikan fitur tersendiri, bukan menumpang `notes`, agar tidak
   ada satu fitur bersih dan sisanya kotor.
