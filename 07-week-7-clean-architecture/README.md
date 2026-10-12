# Week 7: Clean Architecture

Refactor project Minggu 5 (`week5_offline_notes`) menjadi **Clean Architecture
feature-first**: `presentation → domain ← data`, dengan `domain` yang steril dari
Flutter, Dio, SQLite, dan Firebase.

## Struktur

```
07-week-7-clean-architecture/
└── week7_clean_notes/          # project hasil refactor (Clean Notes)
    ├── lib/
    │   ├── core/               # failures.dart, format.dart (murni Dart)
    │   ├── shared/data/        # SQLite + Dio (infrastruktur lintas fitur)
    │   ├── features/
    │   │   ├── notes/          # domain + data + presentation
    │   │   ├── posts/          # domain + data + presentation
    │   │   ├── settings/       # domain + data + presentation
    │   │   └── home/           # shell navigasi
    │   ├── routes.dart         # GoRouter + konstanta rute
    │   └── main.dart           # bootstrap
    ├── test/                   # 27 test (use case, model, format, widget, repo)
    ├── docs/                   # layer mapping, AI challenge, testing, verifikasi
    ├── screenshots/            # dokumentasi tampilan (layout mobile)
    └── tool/                   # skrip verifikasi dependency rule
```

## Ringkasan hasil

| Item | Hasil |
|---|---|
| `flutter analyze` | No issues found! |
| `flutter test` | 27 test lulus |
| Grep sterilitas presentation | NOL HASIL |
| Grep sterilitas domain & core | NOL HASIL |
| Grep instansiasi manual di UI | NOL HASIL |
| Perilaku aplikasi | Identik dengan Minggu 5 (bukti screenshot before/after) |

## Mulai dari sini

- [`week7_clean_notes/README.md`](week7_clean_notes/README.md) — tujuan, diagram
  layer + arah dependensi, pemetaan file lama → layer baru, cara menjalankan,
  hasil, dan refleksi.
- [`week7_clean_notes/docs/layer_mapping.md`](week7_clean_notes/docs/layer_mapping.md)
  — Praktikum 1 & 2: peta file ke layer dan tiga pelanggaran klasik.
- [`week7_clean_notes/docs/AI_challenge/`](week7_clean_notes/docs/AI_challenge/README.md)
  — prompt, keluaran awal AI, tabel usulan-vs-keputusan, checklist verifikasi.
- [`week7_clean_notes/docs/testing.md`](week7_clean_notes/docs/testing.md) — daftar
  test dan uji manual.
- [`week7_clean_notes/docs/refactoring.md`](week7_clean_notes/docs/refactoring.md)
  — tiga Refactoring Challenge.
- [`week7_clean_notes/docs/verification/`](week7_clean_notes/docs/verification/)
  — keluaran mentah `flutter analyze`, `flutter test`, dan tiga grep.

## Cara menjalankan

```bash
cd week7_clean_notes
flutter pub get
flutter run                    # target Android
flutter analyze && flutter test

# verifikasi dependency rule
powershell -ExecutionPolicy Bypass -File tool/check_dependency_rule.ps1
```

## Catatan

- Project ini merefactor kode Minggu 5, bukan membuat fitur baru.
- Folder `docs/` wajib memuat prompt, keluaran awal AI, tabel
  usulan-vs-keputusan-final, dan hasil grep verifikasi (tanggung jawab teknis
  modul Minggu 7).
