# AI Verification Checklist

Checklist ini diisi sebelum kode AI (output awal di
[`output_ai_initial.dart`](output_ai_initial.dart)) diterima ke dalam project.

## Checklist

- [x] **UI memanggil Dio secara langsung?** Tidak. UI hanya `ref.watch`
  provider (`commentsProvider`, `postDetailProvider`, `postListProvider`).
  Semua akses jaringan lewat repository. ✔ Tidak ada `Dio()` di folder `pages/`.

- [x] **`fromJson` aman null?** Ya. Output awal memakai `json['id'] as int`
  (berpotensi crash) dan sudah diperbaiki menjadi
  `(json['id'] as num?)?.toInt() ?? 0` serta `as String? ?? ''`.

- [x] **Semua `DioExceptionType` dipetakan?** Ya. `friendlyErrorMessage`
  menangani `connectionTimeout`/`sendTimeout`/`receiveTimeout`,
  `connectionError`, `badResponse` (404, 401/403, >=500), dan `default`.

- [x] **`baseUrl`/timeout terpusat?** Ya, di `createDio()`
  (`lib/data/api_client.dart`) dan dibagikan lewat `dioProvider`. Output awal
  sempat menyebar `Options(receiveTimeout: ...)` di method — sudah dihapus.

- [x] **Test AI menguji field hilang?** Output awal hanya happy path.
  Sudah ditambahkan test field hilang + round-trip + test provider dengan
  repository palsu.

- [x] **`flutter analyze` & `flutter test` lolos?** Ya.
  `flutter analyze` → No issues found; `flutter test` → 15 test lulus.

## Catatan Temuan

1. **Bug `num` vs `String`.** Pola `(json['id'] as num?)?.toInt() ?? 0`
   aman terhadap field yang hilang maupun `double`, **tetapi** tetap
   melempar exception bila server mengirim angka sebagai `String`
   (mis. `"id": "12"`). Saya menuliskannya sebagai edge case yang
   didokumentasikan: JSONPlaceholder tidak melakukannya, tetapi API nyata
   bisa. Perbaikan penuh akan memerlukan helper `parseInt` yang menerima
   `String` juga — sengaja tidak ditambahkan agar tetap sesuai modul.

2. **Timeout tidak benar-benar diuji.** Timeout 10 detik sulit dipicu manual;
   pemetaan pesannya diuji lewat unit test (`DioExceptionType.receiveTimeout`).

3. **Retry Riverpod 3.** Tanpa `retry: (count, error) => null`, provider
   akan mengulang otomatis dan test berbasis future akan menggantung. Ini
   catatan penting untuk Minggu 12.

4. **Komentar & kredensial.** Karena endpoint komentar publik tanpa auth,
   tidak ada header rahasia yang perlu diamankan pada Minggu 4.
