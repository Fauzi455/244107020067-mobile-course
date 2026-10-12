# Refactoring Challenge — Dokumentasi

Tiga refactoring wajib dari modul Minggu 4 beserta bukti penerapannya.

## 1. Ekstrak widget baris post menjadi `PostTile`

- **Sebelum:** `ListTile` ditulis dua kali (di `post_list_page.dart` dan
  `paged_post_page.dart`).
- **Sesudah:** satu widget `PostTile` di `lib/widgets/post_tile.dart`
  menerima `Post` dan callback `onTap`. `ListView.builder` kini ringkas:
  `itemBuilder: (context, index) => PostTile(post: posts[index], onTap: ...)`.
- **Manfaat:** menghilangkan duplikasi, `itemBuilder` pendek, dan mudah diuji
  (`test/post_tile_test.dart` menguji tampilan + `onTap`).

## 2. Pindahkan `friendlyErrorMessage` ke file sendiri

- **Sebelum:** fungsi berada di `lib/data/providers.dart`.
- **Sesudah:** `lib/data/network_errors.dart`. Agar import lama tetap bekerja,
  `providers.dart` melakukan `export 'network_errors.dart';`.
- **Manfaat:** dipakai ulang oleh halaman daftar, halaman paged, dan halaman
  detail tanpa duplikasi atau ketergantungan pada `providers.dart`.

## 3. Halaman detail `/post/:id` dengan GoRouter

- **Routing:** `lib/app_router.dart` mendefinisikan `GoRoute` untuk `/`,
  `/posts`, `/paged`, dan `/post/:id`. `main.dart` memakai
  `MaterialApp.router`.
- **Sumber data detail:** `postDetailProvider` (`lib/data/post_detail.dart`)
  menerapkan strategi *list-first, network-fallback*:
  1. Cari post di cache `pagedPostsProvider` (instan, tanpa request).
  2. Bila tidak ada (deep link), ambil via `PostRepository.fetchPostById`.
- **Isi halaman:** judul, penulis, isi lengkap, dan daftar komentar
  (`commentsProvider`).
- **Manfaat:** navigasi terpusat, deep-linkable, dan hemat request.

## Hasil

- `flutter analyze` → No issues found.
- `flutter test` → 15 test lulus (termasuk `post_tile_test.dart`).
