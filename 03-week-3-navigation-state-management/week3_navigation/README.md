# week3_navigation

Aplikasi demo navigasi multi-page di Flutter menggunakan **GoRouter**. Ini adalah praktikum 1 dari modul Minggu 3 (*Navigation & State Management*).

## Fitur

- **Home** (`/`) : daftar 10 item. Mengetuk item memanggil `context.go('/detail/{id}')`.
- **Detail** (`/detail/:id`) : menampilkan ID item yang diterima dari path parameter.
- **Deep link** : buka `http://localhost:PORT/detail/7` langsung, tanpa lewat Home.
- **Back** : tombol back sistem mengembalikan ke Home karena path berubah mengikuti layar aktif.

## Verifikasi

| Item | Hasil |
|---|---|
| `flutter analyze` | `No issues found!` |
| `flutter test` | `All tests passed!` (2 widget test) |
| Pindah halaman via klik | `Item 5` → `/detail/5` |
| Deep link langsung | `http://localhost:8091/detail/3` menampilkan `Detail 3` |
| Tombol back | kembali ke Home |

## Screenshot

| Layar | File |
|---|---|
| Home (10 item) | ![](https://github.com/Fauzi455/244107020067-mobile-course/blob/main/03-week-3-navigation-state-management/week3_navigation/screenshot/01_home_page.png) |
| Detail (id 5) | ![](https://github.com/Fauzi455/244107020067-mobile-course/blob/main/03-week-3-navigation-state-management/week3_navigation/screenshot/02_detail_page.png) |
