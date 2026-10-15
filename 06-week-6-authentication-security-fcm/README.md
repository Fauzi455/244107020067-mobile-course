# Week 6: Authentication, Security & FCM

Membangun **Campus Notification App** untuk modul Minggu 6 codelab Flutter JTI
Polinema. Fokus minggu ini bukan tata letak layar, melainkan **jalur yang tidak
terlihat**: bagaimana token disimpan dan diperbarui saat 401, bagaimana FCM
mendaftarkan perangkat, dan apa yang terjadi saat notifikasi diklik pada tiga
keadaan aplikasi (foreground, background, terminated).

## Struktur

```
06-week-6-authentication-security-fcm/
├── week6_campus_notify/            # project Flutter (Campus Notify)
│   ├── lib/
│   │   ├── main.dart               # bootstrap: Firebase → sesi → router → push
│   │   ├── app_router.dart         # GoRouter + guard route
│   │   ├── routes.dart             # Refactoring 1: satu sumber kebenaran rute
│   │   ├── data/                   # token_store, auth_repository, api_client,
│   │   │                           # api_log, api_errors, announcements
│   │   ├── messaging/              # kontrak PushService + FCM + kanal tiruan,
│   │   │                           # push_message (routeFromMessage), presenter
│   │   ├── providers/              # wiring DI + AuthNotifier
│   │   ├── pages/                  # login, shell 3 tab, beranda, sesi, push, detail
│   │   └── widgets/                # banner notifikasi foreground
│   ├── test/                       # 35 test (rute, sesi, interceptor 401, kanal push)
│   ├── docs/                       # AI challenge, refactoring, pengujian, bukti
│   ├── screenshots/                # 12 screenshot aplikasi yang berjalan
│   └── tool/                       # mock Campus API, verifikasi, pengambil screenshot
└── README.md                       # berkas ini
```

## Ringkasan hasil

| Item | Hasil |
|---|---|
| `flutter analyze` | No issues found! |
| `flutter test` | 35 test lulus (tanpa Firebase, tanpa jaringan) |
| `node tool/check_api_flow.js` | SEMUA PEMERIKSAAN LULUS (login → 200 → expire → 401 → refresh → 200) |
| Jalur 401 | Refresh **sekali** lalu retry → HTTP 200; refresh mati → sesi dibersihkan |
| Tiga app state | Foreground (banner lokal), background, terminated → semuanya masuk `/pengumuman/3` |
| Token | Hanya di `flutter_secure_storage`; tampil **terpotong** di UI dan tidak pernah utuh di log |
| Screenshot | 12 berkas, viewport ponsel 390 × 780 (DPR 2), diambil satu langkah per proses |

## Mulai dari sini

- [`week6_campus_notify/README.md`](week6_campus_notify/README.md) — tujuan,
  diagram alur sesi & FCM, daftar fitur, struktur folder, stack, cara menjalankan,
  tabel tiga app state, dan refleksi.
- [`week6_campus_notify/docs/AI_challenge/`](week6_campus_notify/docs/AI_challenge/README.md)
  — prompt, keluaran awal AI, tabel usulan-vs-keputusan, dan checklist verifikasi.
- [`week6_campus_notify/docs/three_app_states.md`](week6_campus_notify/docs/three_app_states.md)
  — matriks pengujian foreground / background / terminated beserta cara
  mengulangnya lewat simulator maupun Firebase Console.
- [`week6_campus_notify/docs/refactoring.md`](week6_campus_notify/docs/refactoring.md)
  — tiga Refactoring Challenge modul.
- [`week6_campus_notify/docs/testing.md`](week6_campus_notify/docs/testing.md) —
  daftar test dan uji manual.
- [`week6_campus_notify/docs/firebase_setup.md`](week6_campus_notify/docs/firebase_setup.md)
  — konfigurasi native FCM yang sudah dipasang dan langkah lanjutan di Firebase
  Console.
- [`week6_campus_notify/docs/verification/`](week6_campus_notify/docs/verification/)
  — keluaran mentah `flutter analyze`, `flutter test`, dan pemeriksaan kontrak
  mock API.

## Cara menjalankan

```bash
cd week6_campus_notify
flutter pub get

# backend tiruan (menerbitkan 401 sungguhan untuk jalur refresh)
node tool/mock_api_server.js 8787          # terminal terpisah

flutter run                                # target Android
flutter analyze && flutter test
```

Tanpa `google-services.json`, aplikasi **tetap berjalan**: Firebase dilewati dan
kanal push tiruan dipakai, sehingga tiga app state masih bisa diperagakan.
Aplikasi juga bisa dijalankan di browser untuk dokumentasi:

```bash
flutter build web --release
node tool/serve_web.js build/web 8123      # terminal terpisah
```

## Catatan

- **Firebase tidak diuji langsung di unit test.** `FirebaseMessaging` dan
  `flutter_local_notifications` butuh platform channel; yang diuji adalah logika
  di sekitarnya (parsing payload → rute, aturan sesi/refresh, jalur tiga app
  state lewat abstraksi `PushService`).
- **Kanal push tiruan bukan "memalsukan tampilan".** Ia menyuntikkan pesan ke
  `PushService.events`, yaitu jalur penanganan yang sama dengan
  `FirebasePushService`; yang berbeda hanya sumber pesannya.
- **`screenshots/fcm-console-test.png` belum ada** karena langkah itu butuh
  project Firebase dan perangkat/emulator dengan Google Play Services. Prosedurnya
  sudah disiapkan di `docs/firebase_setup.md`.
- Folder `docs/` wajib memuat prompt, keluaran awal AI, tabel
  usulan-vs-keputusan-final, dan bukti verifikasi (tanggung jawab teknis modul
  Minggu 6).
