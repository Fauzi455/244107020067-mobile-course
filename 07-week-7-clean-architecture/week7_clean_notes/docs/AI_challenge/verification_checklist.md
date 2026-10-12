# AI Verification Checklist (modul Minggu 7)

Setiap butir diverifikasi dengan **perintah**, bukan dengan membaca sekilas.

| # | Pertanyaan verifikasi | Cara memeriksa | Hasil | Bukti |
|---|---|---|---|---|
| 1 | Apakah interface repository tinggal di `domain` dan implementasi di `data`? | `ls lib/features/*/domain/repositories lib/features/*/data/repositories` | **Lolos** — 3 interface di `domain/repositories`, 3 implementasi di `data/repositories` | `docs/layer_mapping.md` |
| 2 | Apakah `domain` bebas import Flutter/Dio/SQLite/Firebase? | `rg "import 'package:(flutter\|dio\|sqflite\|firebase)" lib/features/*/domain lib/core` | **Lolos** — NOL HASIL | `verification/grep_sterilitas.txt` |
| 3 | Apakah AI membuat use case untuk tiap CRUD satu-baris? | periksa `lib/features/notes/domain/usecases/` | **Lolos** — hanya `get_notes.dart` dan `sync_notes.dart`; CRUD lewat repository dengan alasan tertulis | `docs/AI_challenge/usulan_vs_keputusan.md` baris 3 |
| 4 | Apakah entity bebas mapping (`toMap/fromMap/toJson` hanya di model)? | `rg "toMap\|fromMap\|toJson\|fromJson" lib/features/*/domain` | **Lolos** — NOL HASIL di `domain` | lihat di bawah |
| 5 | Apakah wiring DI terpusat di provider dan widget tidak `new Repository()` sendiri? | `rg "RepositoryImpl\(\|Dio\(BaseOptions" lib/features/*/presentation/pages lib/features/*/presentation/widgets` | **Lolos** — NOL HASIL | `verification/grep_sterilitas.txt` |
| 6 | Apakah presentation steril dari akses data mentah? | `rg "Dio\(\|openDatabase\|SharedPreferences\.getInstance\|jsonDecode" lib/features/*/presentation` | **Lolos** — NOL HASIL | `verification/grep_sterilitas.txt` |
| 7 | Apakah aplikasi masih berjalan identik? | uji manual 6 langkah + screenshot | **Lolos** — UI sama, struktur beda | `docs/testing.md`, `screenshots/` |
| 8 | Apakah `flutter analyze` bersih dan test hijau? | `flutter analyze && flutter test` | **Lolos** — No issues found, 27 test lulus | `verification/flutter_analyze.txt`, `verification/flutter_test.txt` |

## Verifikasi tambahan butir 4

```
> rg "toMap|fromMap|toJson|fromJson" lib/features/notes/domain lib/features/posts/domain lib/features/settings/domain lib/core
(NOL HASIL)

> rg "toMap|fromMap|toJson|fromJson" lib/features/*/data
lib/features/notes/data/models/note_model.dart        : toMap / fromMap
lib/features/posts/data/models/post_model.dart        : toJson / fromJson
(nilai yang diharapkan: mapping hanya di layer data)
```

## Butir yang sengaja diperiksa dengan cara berbeda

Modul menulis grep no. 3 sebagai
`rg "Repository\(|Dio\(BaseOptions" lib/pages lib/providers`. Pada struktur
feature-first, `lib/pages` dan `lib/providers` tidak lagi ada. Pemeriksaan
diarahkan ke `presentation/pages` dan `presentation/widgets`, karena:

- `presentation/providers` **memang** tempat wiring DI (contoh resmi modul:
  `NoteRepositoryImpl(openDb: openNotesDb)` di `notes_providers.dart`);
- yang dilarang adalah **widget/notifier** membuat dependensinya sendiri.

Keputusan ini dicatat agar tidak terlihat seperti melonggarkan aturan.

## Temuan yang perlu diperbaiki saat verifikasi

| Temuan | Penyebab | Tindakan |
|---|---|---|
| GREP 1 sempat 1 hasil | komentar di `cached_posts_page.dart` yang **menyebut** `Dio`/`jsonDecode` sebagai kata | komentar ditulis ulang agar tidak memicu pola; kode tidak berubah |
| GREP 3 sempat 4 hasil | pola mengenai `RepositoryImpl(...)` di `presentation/providers` (wiring DI yang sah) | cakupan grep diarahkan ke `pages`/`widgets` + catatan alasan |

Kedua temuan di atas dicatat apa adanya karena modul menuntut verifikasi
berbasis perintah, bukan berbasis pembacaan sekilas.
