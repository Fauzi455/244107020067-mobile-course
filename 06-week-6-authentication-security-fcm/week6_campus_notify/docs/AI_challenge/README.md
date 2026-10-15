# AI Challenge — Minggu 6

Modul Minggu 6 menegaskan: AI boleh membuat draf awal service FCM dan
boilerplate auth, tetapi **mahasiswa yang membuktikan perilakunya**. Bug FCM
yang paling mahal — token basi, klik nyasar, banner ganda — tidak terlihat dari
membaca kode saja.

Folder ini menyimpan jejaknya.

| Berkas | Isi |
|---|---|
| [`prompt.md`](prompt.md) | prompt yang dikirim ke AI coding assistant |
| [`output_ai_initial.md`](output_ai_initial.md) | keluaran awal AI (apa adanya, sebelum dinilai) |
| [`usulan_vs_keputusan.md`](usulan_vs_keputusan.md) | tabel usulan AI vs keputusan final + alasan teknis |
| [`verification_checklist.md`](verification_checklist.md) | checklist verifikasi modul + temuan, termasuk hasil uji tiga app state |

## Ringkasan

**Diterima dari AI (dengan perbaikan):**

1. Struktur `PushService` sebagai abstraksi dengan `requestPermission` →
   `getToken` → `onTokenRefresh` → `subscribeToTopic` → tiga handler.
2. Background handler sebagai fungsi **top-level** dengan
   `@pragma('vm:entry-point')` — AI benar di sini, dan alasannya (isolate
   terpisah, tanpa `BuildContext`) ikut ditulis di komentar kode.
3. Pemisahan `notification` (teks) dan `data.route` (tujuan deep link), dengan
   aturan "selalu kirim gabungan keduanya".
4. Pola interceptor Dio: 401 → refresh → retry sekali.

**Ditolak / diperbaiki (enam hal, dua di antaranya bug nyata):**

1. **Anti-loop pada interceptor.** Draf AI memakai
   `dio.fetch(e.requestOptions)` tanpa penanda apa pun. 401 kedua akan memicu
   refresh **lagi**, dan seterusnya — loop tak berujung yang hanya berhenti saat
   refresh token ikut mati. Ditambahkan `extra['campus_notify_retried']`, dan
   perilakunya diuji (`test/api_refresh_interceptor_test.dart`).
2. **`nextInt(1 << 32)`.** Draf AI memakai `1 << 32` sebagai batas acak untuk
   nonce token. Di VM Dart itu sah, tetapi di web (`dart2js`) `1 << 32`
   dievaluasi menjadi `0`, sehingga `nextInt(0)` melempar `RangeError` — tepat
   pada jalur refresh. Gejalanya: pengguna tiba-tiba dilempar ke `/login`
   **hanya di web**. Diganti literal `2147483647` (2³¹−1) dan ditambahkan test
   regresi.
   **Ini ditemukan lewat pengujian, bukan lewat membaca kode.**
3. **`store.save(access:, refresh:)` di jalur refresh.** AI menulis ulang kedua
   token. Kalau nilai refresh yang dipegang sudah basi, penulisan itu **menimpa
   refresh token yang masih sah**. Diganti `store.saveAccess()`.
4. **Refresh token di `SharedPreferences` "agar lebih mudah".** Ditolak atas
   dasar keamanan: SharedPreferences tidak terenkripsi. Tetap
   `flutter_secure_storage` (Keystore/Keychain).
5. **Token penuh ditampilkan di halaman debug.** AI mengusulkan menampilkan
   token utuh agar "mudah diverifikasi". Modul melarang token utuh di
   screenshot. Diganti `TokenStore.mask()` (12 karakter pertama + jumlah
   karakter).
6. **Firebase dianggap wajib ada.** Draf AI memanggil
   `await Firebase.initializeApp()` tanpa penanganan gagal. Karena modul sendiri
   mengakui FCM paling mudah diuji di perangkat fisik — sementara lingkungan
   tugas ini tidak punya emulator dengan Play Services — jalur tanpa Firebase
   dibuat eksplisit: `try/catch` + kanal push tiruan yang menyalurkan pesan ke
   **jalur penanganan yang sama**.

**Tambahan yang tidak diusulkan AI tetapi dibutuhkan (dan ditemukan saat uji):**

- `onSessionExpired` pada `buildApiClient`. Tanpa ini, setelah interceptor
  membersihkan token karena refresh ikut mati, state autentikasi Riverpod tidak
  tahu apa-apa: token sudah hilang tetapi UI masih diam di beranda. Kini guard
  GoRouter yang memindahkan pengguna ke `/login`.

**Tanggung jawab teknis yang dipenuhi:** prompt, keluaran awal AI, tabel
usulan-vs-keputusan, daftar perbaikan manual, dan tabel hasil uji tiga app state
tersimpan di folder `docs/` ini.
