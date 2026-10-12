# Keluaran awal AI (sebelum dinilai)

Disimpan **apa adanya** sebagai bahan perbandingan. Bagian yang ditolak tidak
dihapus — justru itu yang dinilai pada minggu ini.

---

## Usulan struktur

```
lib/
├── core/
│   ├── failures.dart
│   ├── usecases/usecase.dart            # base class UseCase<Type, Params>
│   ├── network/api_client.dart          # Dio
│   └── di/injection.dart                # get_it
├── features/
│   ├── notes/
│   │   ├── domain/
│   │   │   ├── entities/note.dart
│   │   │   ├── repositories/note_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_notes.dart
│   │   │       ├── add_note.dart
│   │   │       ├── update_note.dart
│   │   │       ├── delete_note.dart
│   │   │       └── sync_notes.dart
│   │   ├── data/
│   │   │   ├── models/note_model.dart
│   │   │   ├── datasources/note_local_datasource.dart
│   │   │   └── repositories/note_repository_impl.dart
│   │   └── presentation/
│   │       ├── blocs/notes_bloc.dart
│   │       └── pages/notes_page.dart
│   ├── posts/...
│   └── settings/...
└── main.dart
```

## Ringkasan saran

1. **Ganti Riverpod dengan BLoC** agar state management lebih terstruktur dan
   mudah diuji (`NotesBloc`, `NotesEvent`, `NotesState`).
2. **Gunakan `fpdart`** dan kembalikan `Either<Failure, T>` dari setiap
   repository, agar kegagalan bersifat eksplisit dan fungsional.
3. **Buat base class `UseCase<Type, Params>`** dan buat use case untuk **setiap**
   operasi: `AddNote`, `UpdateNote`, `DeleteNote`, `GetNotes`, `SyncNotes`.
   Konsistensi lebih penting daripada jumlah file.
4. **Gunakan `get_it` + `injectable`** untuk dependency injection, karena
   Riverpod "mencampur" DI dengan state.
5. **Pertahankan `toMap/fromMap` di entity `Note`** supaya tidak perlu kelas
   `NoteModel` terpisah — entity langsung bisa disimpan.
6. **Taruh `api_client.dart` (Dio) di `lib/core/network/`** karena Dio adalah
   infrastruktur yang dipakai semua fitur.
7. Buat satu `AppRepository` besar yang menangani auth + notes + posts + push
   agar hanya ada satu titik akses data.
8. `prefs.dart` dipindah ke `features/settings/domain` dan langsung memakai
   `SharedPreferences` di dalam entity.

## Trade-off yang disebutkan AI

- "BLoC lebih banyak boilerplate tetapi lebih eksplisit."
- "`fpdart` menambah dependensi tetapi membuat error handling konsisten."
- "Use case untuk semua operasi konsisten, meskipun file bertambah."
- "`get_it` memisahkan DI dari state management."
- "Satu `AppRepository` menyederhanakan pencarian kode."

---

## Penilaian singkat (dibahas lengkap di `usulan_vs_keputusan.md`)

| Usulan | Status |
|---|---|
| 1. Ganti Riverpod → BLoC | **Ditolak** — mengganti seluruh state management bukan tujuan refactor arsitektur; risiko besar tanpa nilai untuk modul ini |
| 2. `fpdart` / `Either` | **Ditolak** — modul menawarkan *record* Dart; tidak perlu dependensi baru |
| 3. Use case untuk setiap CRUD | **Sebagian ditolak** — over-engineering untuk operasi satu baris |
| 4. `get_it` + `injectable` | **Ditolak** — dua sistem DI |
| 5. Entity tetap punya `toMap/fromMap` | **Ditolak** — melanggar definisi entity pada modul |
| 6. Dio di `lib/core/network/` | **Ditolak** — `lib/core` harus steril dari framework |
| 7. Satu `AppRepository` besar | **Ditolak** — melanggar Interface Segregation |
| 8. Entity settings memakai `SharedPreferences` langsung | **Ditolak** — entity di domain harus murni |
| Interface di domain, impl di data | **Diterima** |
| Pecah provider per fitur | **Diterima** |
| Pindahkan formatting keluar dari widget | **Diterima** |
