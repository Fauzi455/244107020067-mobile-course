# AI Prompt Challenge — Dokumentasi

Minggu 4 adalah materi lanjutan. AI **boleh** membantu merancang repository
layer, tetapi kode yang dihasilkan **wajib diverifikasi**, diuji, dan setiap
keputusan teknisnya harus bisa dijelaskan. Halaman ini menyimpan prompt, output
awal AI, perbaikan yang dilakukan, dan hasil testing.

## 1. Prompt yang Digunakan

```text
Buatkan repository layer Flutter untuk endpoint GET /comments?postId={id}
dari JSONPlaceholder menggunakan Dio + flutter_riverpod.
Requirements:
- Model Comment dengan fromJson aman null (postId, id, name, email, body).
- CommentRepository dengan method fetchComments(postId) + timeout 10 detik.
- AsyncNotifierProvider dengan penanganan error otomatis (AsyncError)
  dan fungsi pesan error ramah pengguna untuk timeout, connection error,
  404, dan 500.
- Satu unit test untuk fromJson dengan field yang hilang.
Jelaskan setiap bagian kode dalam komentar.
```

## 2. Output Awal AI

Disimpan lengkap di [`output_ai_initial.dart`](output_ai_initial.dart).
Ringkasannya, AI menghasilkan 5 masalah:

| # | Masalah pada output awal | Dampak |
|---|--------------------------|--------|
| 1 | `fromJson` memakai cast langsung `json['id'] as int` | Crash `type 'Null' is not a subtype` bila field hilang |
| 2 | `receiveTimeout` ditulis per-method, `Dio()` dibuat langsung | Timeout tersebar, tidak konsisten dengan `createDio()` |
| 3 | Memakai `FutureProvider` | Tidak bisa memuat ulang / side-effect (tombol "Coba lagi" & refresh) |
| 4 | `friendlyErrorMessage` hanya menangani `connectionError` | Timeout, 404, dan 500 tidak dipetakan; pesan teknis bocor ke UI |
| 5 | Test hanya happy path | Requirement "field hilang" tidak diuji |

## 3. Perbaikan yang Dilakukan

1. **`fromJson` dibuat aman null.** Semua cast memakai pola defensif:
   `(json['postId'] as num?)?.toInt() ?? 0` dan `json['name'] as String? ?? ''`.
   Angka juga dinormalkan lewat `num?` agar `3.0` tetap terbaca sebagai `3`.

2. **Timeout dipusatkan.** `CommentRepository` cukup memakai `Dio` yang
   di-*inject*; konfigurasi `baseUrl` + `connectTimeout`/`receiveTimeout`
   10 detik hidup di `createDio()` (`lib/data/api_client.dart`) dan dibagikan
   lewat `dioProvider`. Tidak ada lagi `Options(receiveTimeout: ...)` di method.

3. **Ganti ke `AsyncNotifierProvider.family`.** `CommentListNotifier` menerima
   `postId` lewat konstruktor, `build()` mengembalikan `Future`, dan tersedia
   method `refresh()` untuk tombol "Coba lagi". Provider diberi
   `retry: (count, error) => null` agar error langsung final dan test tidak
   menggantung menunggu retry Riverpod 3.

4. **`friendlyErrorMessage` dilengkapi dan dipindah.** Fungsi ini sekarang
   menangani timeout, `connectionError`, `badResponse` (404, 401/403, >=500),
   dan fallback; diletakkan di `lib/data/network_errors.dart` agar dipakai
   ulang oleh semua halaman (Refactoring Challenge no. 2).

5. **Test ditambah edge case.** Selain happy path, ditambahkan test field
   hilang, round-trip `toJson`/`fromJson`, dan test provider sukses + error
   memakai repository palsu (tanpa HTTP sungguhan).

## 4. Hasil Verifikasi

- `flutter analyze` → **No issues found!**
- `flutter test` → **15 test lulus** (lihat `test/post_test.dart`,
  `test/comment_test.dart`, `test/post_tile_test.dart`).
- Checklist verifikasi AI: lihat [`verification_checklist.md`](verification_checklist.md).

## 5. Tanggung Jawab Teknis

Seluruh berkas pada folder ini (`README.md`, `output_ai_initial.dart`,
`verification_checklist.md`) menyimpan jejak prompt, output awal AI, perbaikan,
dan hasil testing. Saat demo, setiap baris kode hasil AI dapat dijelaskan:
mengapa memakai `num?`, mengapa `AsyncNotifierProvider.family`, dan mengapa
timeout dipusatkan pada satu client.
