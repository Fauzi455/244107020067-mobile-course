# Refactoring Challenge (modul Minggu 7)

## 1. Fitur kedua dan ketiga ikut dibersihkan

Modul memperingatkan: "Jangan biarkan satu fitur bersih dan sisanya kotor."
Karena itu ketiga fitur direfactor dengan pola yang sama, bukan hanya `notes`:

| Fitur | domain | data | presentation |
|---|---|---|---|
| `notes` | `entities/note.dart`, `repositories/note_repository.dart` (interface), `usecases/{get_notes,sync_notes}.dart` | `models/note_model.dart`, `datasources/notes_local_datasource.dart`, `repositories/note_repository_impl.dart` | `providers/notes_providers.dart`, `pages/*`, `widgets/*` |
| `posts` | `entities/post.dart`, `repositories/post_repository.dart` (interface) | `models/post_model.dart`, `datasources/{post_remote,post_cache}_datasource.dart`, `repositories/post_repository_impl.dart` | `providers/posts_providers.dart`, `pages/cached_posts_page.dart` |
| `settings` | `entities/app_settings.dart`, `repositories/settings_repository.dart` (interface) | `datasources/settings_local_datasource.dart`, `repositories/settings_repository_impl.dart` | `providers/settings_providers.dart`, `pages/settings_page.dart` |

`posts` dan `settings` sengaja **tidak** memakai use case: keduanya belum punya
aturan bisnis gabungan. Keputusan ini dicatat sebagai bagian dari AI Challenge
(menolak over-engineering).

## 2. Ekstraksi formatting dan parsing ke fungsi murni

Sebelumnya (Minggu 5) terdapat tiga salinan logika formatting:

- `lib/pages/note_detail_page.dart` → `_formatTime()`
- `lib/widgets/note_tile.dart` → `_formatTime()`
- `lib/pages/settings_page.dart` → `_prettyTime()`

Sekarang semuanya memanggil `lib/core/format.dart`:

| Fungsi | Kegunaan |
|---|---|
| `formatDate(DateTime)` | `13 Okt 2026` |
| `formatClock(DateTime)` | `14:05` |
| `formatDateTime(DateTime)` | `13 Okt 2026, 14:05` — daftar & detail |
| `formatDateTimeWithSeconds(DateTime)` | halaman Pengaturan |
| `formatRelative(DateTime, {now})` | `5 menit lalu` (deterministik saat diuji) |
| `parseNoteId(String?)` | parsing `/note/:id` — diuji tanpa GoRouter |
| `parseIsoDate(String?)` | parsing ISO-8601 dengan aman |

Manfaat konkret: ketiga salinan itu kini diuji di `test/format_test.dart` tanpa
mem-build widget apa pun, dan tidak bisa lagi berbeda perilaku antar halaman.

`routes.dart` juga berhenti menulis string rute secara literal:

```dart
abstract final class AppRoutes {
  static const String home = '/';
  static const String noteDetailPattern = '/note/:id';
  static String noteDetail(int id) => '/note/$id';
}
```

## 3. Exception mentah menjadi `Failure` ramah pengguna

Sebelumnya `NoteRepository.fetchNotes()` melempar `DatabaseException` mentah dan
`syncNotes()` melempar `SyncOfflineException` yang ditangkap di widget.
Sekarang:

```
exception platform (sqflite / Dio / SharedPreferences)
        │  ditangkap di layer data
        ▼
Failure  (core/failures.dart)
   ├── LocalFailure    "Gagal membaca catatan: ..."
   ├── NetworkFailure  "Gagal mengambil posts dari jaringan: ..."
   └── OfflineFailure  "Mode offline aktif: sinkronisasi dilewati."
        │  dibungkus FailureException saat masuk AsyncValue.error
        ▼
UI hanya menampilkan failure.message
```

Bukti: halaman `notes_page.dart` menangkap `FailureException` dan menampilkan
`e.failure.message`; tidak ada lagi `on SyncOfflineException`. Tangkapan layar
`screenshots/10_offline_sync.png` memperlihatkan pesan `OfflineFailure` yang
berasal dari layer domain.

## 4. Verifikasi setelah refactor

1. Tiga grep sterilitas nol hasil → `docs/verification/grep_sterilitas.txt`
2. `flutter analyze` bersih → `docs/verification/flutter_analyze.txt`
3. 27 test lulus → `docs/verification/flutter_test.txt`
4. Uji manual 6 langkah + screenshot before/after → `docs/testing.md`
