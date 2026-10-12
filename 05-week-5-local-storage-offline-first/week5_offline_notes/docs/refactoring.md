# Refactoring Challenge — Dokumentasi

Tiga refactoring wajib dari modul Minggu 5 beserta bukti penerapannya.

## 1. Ekstrak `NoteTile` dengan badge "belum tersinkron"

- **Sebelum:** `ListTile` catatan ditulis langsung di `notes_page.dart`.
- **Sesudah:** `lib/widgets/note_tile.dart`. Menampilkan judul, cuplikan isi,
  waktu update, dan **badge "Belum tersinkron"** bila `note.dirty == true`
  (ikon cloud berubah merah/teal + badge).
- **Manfaat:** `itemBuilder` pendek, presentasi terpisah dari logika, dan mudah
  diuji (`test/note_tile_test.dart`).

## 2. Pindahkan cache posts & `syncNotes` ke `lib/data/sync.dart`

- **Sebelum:** logika cache dan sinkronisasi berpotensi menumpuk di repository.
- **Sesudah:** `lib/data/sync.dart` berisi `fetchPostsFromNetwork`,
  `readCachedPosts`, `writeCachedPosts`, `syncNotes`, dan `SyncOfflineException`.
- **Manfaat:** `NoteRepository` tetap fokus pada CRUD database; strategi
  offline-first hidup di satu tempat yang mudah diuji (`test/sync_test.dart`).

## 3. Halaman detail `/note/:id` dengan GoRouter

- **Routing:** `lib/app_router.dart` mendefinisikan `/` (kerangka tab) dan
  `/note/:id`. `main.dart` memakai `MaterialApp.router`.
- **Sumber data:** `noteDetailProvider` membaca **langsung dari repository
  lokal** (`fetchNoteById`), bukan dioper dari state halaman list.
- **Isi halaman:** judul, status sinkron, waktu update, isi lengkap, tombol
  edit & hapus.
- **Manfaat:** deep-linkable, tetap benar saat daftar berubah, dan tidak
  bergantung pada state halaman lain.

## Hasil

- `flutter analyze` → No issues found.
- `flutter test` → 11 test lulus (termasuk `note_tile_test.dart`).
