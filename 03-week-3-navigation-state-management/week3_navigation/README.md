# week3_navigation

Aplikasi demo navigasi multi-page di Flutter menggunakan **GoRouter**. Ini adalah praktikum 1 dari modul Minggu 3 (*Navigation & State Management*).

## Tujuan

Membedah konsep dasar navigasi di Flutter:
- `GoRoute` sebagai definisi path → widget
- `context.go()` vs `context.push()`
- Passing argument lewat `state.pathParameters`
- Deep link (buka path detail langsung dari URL)

## Fitur

- **Home** (`/`) : daftar 10 item. Mengetuk item memanggil `context.go('/detail/{id}')`.
- **Detail** (`/detail/:id`) : menampilkan ID item yang diterima dari path parameter.
- **Deep link** : buka `http://localhost:PORT/detail/7` langsung, tanpa lewat Home.
- **Back** : tombol back sistem mengembalikan ke Home karena path berubah mengikuti layar aktif.

## Struktur

```
lib/
├── main.dart                 # GoRouter + MaterialApp.router
├── pages/
│   ├── home_page.dart       # daftar 10 item
│   └── detail_page.dart     # tampilkan id
screenshot/
└── test/widget_test.dart    # widget test untuk path & navigasi
```

## Cara Menjalankan

```bash
# 1. Ambil dependensi
flutter pub get

# 2. Lint
flutter analyze

# 3. Test
flutter test

# 4. Jalankan (pilih satu device)
flutter run -d chrome --web-port 8091
# atau
flutter run -d windows
```

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
| Home (10 item) | `screenshot/01_home_page.png` |
| Detail (id 5) | `screenshot/02_detail_page.png` |

> Screenshot diambil dengan viewport mobile 412×880 (pola smartphone) via headless Chrome + CDP.

## Catatan Teknis

- **`MaterialApp.router`** dipakai, bukan `MaterialApp`. Konfigurasi router masuk lewat parameter `routerConfig`.
- **`context.go`** (bukan `push`) dipakai untuk pindah antar halaman utama, karena perilaku stack-nya yang tidak menumpuk halaman.
- **Path parameter `:id`** dibaca lewat `state.pathParameters['id']`, kemudian dikirim ke `DetailPage` sebagai konstruktor argument.
