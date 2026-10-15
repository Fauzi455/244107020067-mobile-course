# Usulan AI vs keputusan final

Setiap baris disertai **bukti**: berkas kode, test, atau screenshot yang
membuktikan keputusan itu benar. Keputusan yang menyimpang dari AI boleh
berbeda, selama ada argumen teknisnya.

## 1. Diterima dari AI

| Usulan AI | Keputusan | Alasan | Bukti |
|---|---|---|---|
| `PushService` sebagai abstraksi dengan `requestPermission` → `getToken` → `onTokenRefresh` → `subscribeToTopic` → tiga handler | Diterima | Urutan ini memang urutan wajib FCM, dan abstraksinya membuat UI tidak pernah mengimpor `firebase_messaging` | `lib/messaging/push_service.dart`, `firebase_push_service.dart` |
| Background handler **top-level** | Diterima | Berjalan di isolate terpisah: tidak ada `BuildContext`, tidak ada `ProviderContainer` | `firebase_push_service.dart` |
| Selalu kirim `notification` **+** `data.route` | Diterima | `notification` untuk teks yang dibaca manusia, `data` untuk tujuan klik. Tanpa salah satunya, salah satu perilaku hilang | `docs/three_app_states.md`, `push_message.dart` |
| Pola 401 → refresh → retry sekali | Diterima **dengan perbaikan** (lihat §2.1) | Pola benar, penjagaannya yang kurang | `test/api_refresh_interceptor_test.dart` |
| `subscribeToTopic('pengumuman-kampus')` saat start | Diterima | Topik untuk broadcast; token untuk pesan personal | `firebase_push_service.dart`, `screenshots/06_push_token.png` |
| Tampilkan token di halaman debug | Diterima **dengan perbaikan** (lihat §2.5) | Modul memang mewajibkannya, tetapi harus terpotong | `screenshots/06_push_token.png` |

## 2. Ditolak atau diperbaiki

### 2.1 Anti-loop pada interceptor 401

| | |
|---|---|
| **Usulan AI** | `dio.fetch(e.requestOptions..headers[...] = ...)` tanpa penanda |
| **Keputusan** | Tambahkan `extra['campus_notify_retried'] = true` sebelum retry, dan batalkan jalur refresh bila penanda sudah ada |
| **Alasan** | Tanpa penanda, 401 pada permintaan **ulangan** memicu refresh lagi → retry lagi → 401 lagi. Loop ini hanya berhenti ketika refresh token ikut kedaluwarsa, yaitu justru setelah membebani server tanpa guna. AI tidak menyebut risiko ini sama sekali |
| **Bukti** | `lib/data/api_client.dart`; test `401 lagi setelah retry -> berhenti, tidak ada loop` memverifikasi jumlah permintaan tetap **2** |

### 2.2 `nextInt(1 << 32)` — bug nyata, hanya muncul di web

| | |
|---|---|
| **Usulan AI** | `'mock-access-renewed-${Random().nextInt(1 << 32)}'` |
| **Keputusan** | `Random().nextInt(2147483647)` — literal 2³¹−1, sengaja **bukan** `1 << 31` |
| **Alasan** | Di VM Dart, `1 << 32` = 4294967296 dan `nextInt` menerima hingga 2^32. Tetapi di **web (dart2js)** aritmetika integer dibatasi 32-bit sehingga `1 << 32` dievaluasi menjadi **0**; `nextInt(0)` melempar `RangeError: max must be in range 0 < max ≤ 2^32, was 0`. Efeknya: **jalur refresh selalu gagal di web**, interceptor menganggap sesi mati, dan pengguna terlempar ke `/login` tanpa alasan yang terlihat. Nilai ditulis sebagai **literal** 2³¹−1 supaya tidak bergantung pada perilaku pergeseran bit di tiap platform |
| **Bagaimana ditemukan** | Bukan dari membaca kode: saat uji `401 → refresh → retry` di web, aplikasi mendarat di `/login` padahal server mengembalikan 200. Log konsol memperlihatkan `RangeError` pada `auth.refresh()` |
| **Bukti** | `lib/data/auth_repository.dart`; test `nonce token baru aman di semua platform (32-bit)`; `screenshots/05_api_401_refresh.png` menunjukkan `token_type: "hasil refresh"` |

### 2.3 `store.save(access:, refresh:)` di jalur refresh

| | |
|---|---|
| **Usulan AI** | Menulis ulang kedua token saat refresh berhasil |
| **Keputusan** | `store.saveAccess(renewed)` — hanya access token |
| **Alasan** | Nilai `refresh` yang dipegang interceptor berasal dari pembacaan sebelumnya. Bila refresh token berubah di jalur lain sebelum penulisan selesai, penulisan ulang itu **menimpa token yang masih sah dengan nilai basi** — sesi mati pada request berikutnya. Refresh token adalah satu-satunya kunci panjang; ia hanya ditulis saat login |
| **Bukti** | `lib/data/token_store.dart` (`saveAccess`); test `401 -> refresh -> ulang request -> 200` memverifikasi `readRefresh()` **tidak berubah** |

### 2.4 Refresh token di `SharedPreferences`

| | |
|---|---|
| **Usulan AI** | Simpan di SharedPreferences agar mudah diakses dari isolate background handler |
| **Keputusan** | Tetap `flutter_secure_storage` |
| **Alasan** | SharedPreferences tidak terenkripsi: perangkat root/jailbreak, backup tidak terenkripsi, atau ADB di perangkat debug bisa menyalin refresh token, dan token itu berlaku panjang (simulasi 7 hari) — cukup untuk menerbitkan access token baru dari mana saja. Alasan "mudah diakses isolate" juga tidak berlaku: background handler **tidak perlu** token sama sekali; tugasnya pekerjaan ringan, sedangkan navigasi terjadi saat pengguna mengklik notifikasi di isolate utama |
| **Bukti** | `lib/data/token_store.dart`; `firebase_push_service.dart` (handler background hanya mencatat) |

### 2.5 Token utuh di halaman debug

| | |
|---|---|
| **Usulan AI** | `Text('FCM Token: $token')` dan `Text('Access: $accessToken')` |
| **Keputusan** | `TokenStore.mask(token)` → 12 karakter pertama + `…` + jumlah karakter |
| **Alasan** | Aturan modul: token tidak boleh tampil utuh, apalagi ikut terfoto di laporan. 12 karakter pertama cukup untuk membuktikan token **berubah** setelah rotasi, tanpa membocorkan nilai yang bisa dipakai |
| **Bukti** | `screenshots/06_push_token.png`, `10_rotate_token.png`, `04_sesi_token.png` |

### 2.6 Firebase dianggap wajib ada

| | |
|---|---|
| **Usulan AI** | `await Firebase.initializeApp()` langsung, tanpa penanganan gagal |
| **Keputusan** | `try/catch` → `firebaseReady` → bila gagal, `SimulatedPushService` dipakai; plugin Google Services hanya di-apply bila `google-services.json` ada |
| **Alasan** | Modul sendiri mengakui FCM paling mudah diuji di perangkat fisik, dan lingkungan tugas ini tidak punya emulator dengan Play Services. Tanpa jalur cadangan, aplikasi tidak bisa didemokan, diuji, atau difoto sama sekali sebelum Firebase didaftarkan. Lebih buruk: build **gagal total** karena plugin Google Services mengharuskan berkas konfigurasi ada |
| **Yang harus dijaga** | Kanal tiruan tidak boleh "memalsukan tampilan": ia menyuntikkan pesan ke `PushService.events`, jalur yang sama dengan FCM sungguhan, sehingga perilaku penanganan yang dibuktikan tetap nyata |
| **Bukti** | `lib/main.dart`, `lib/messaging/simulated_push_service.dart`, `android/app/build.gradle.kts` (pemasangan bersyarat), `test/simulated_push_service_test.dart` |

### 2.7 Channel id `'pengumuman'` vs `'pengumuman_kampus'`

| | |
|---|---|
| **Usulan AI** | `AndroidNotificationDetails('pengumuman', 'Pengumuman Kampus', ...)` untuk notifikasi lokal, tanpa menyebut meta-data manifest |
| **Keputusan** | `NotificationPresenter.channelId = 'pengumuman_kampus'`, **sama** dengan `com.google.firebase.messaging.default_notification_channel_id`, dan kanal dibuat saat start |
| **Alasan** | Notifikasi **otomatis** FCM (background/terminated) memakai kanal dari meta-data manifest, sedangkan notifikasi **lokal** (foreground) memakai kanal di kode. Kalau nilainya berbeda, pengguna melihat **dua kanal** di pengaturan sistem, dan pengaturan penting/prioritas yang kita buat diabaikan pada salah satunya. Kalau kanal belum dibuat aplikasi, Android membuat "Miscellaneous" sendiri |
| **Bukti** | `lib/messaging/notification_presenter.dart`, `android/app/src/main/AndroidManifest.xml`, `docs/firebase_setup.md` §1 |

### 2.8 `onTokenRefresh.listen(print)`

| | |
|---|---|
| **Usulan AI** | "Cukup untuk memantau rotasi token" |
| **Keputusan** | `onTokenRefresh.listen((t) { _token.value = t; await onToken(t); })` — token baru **dikirim ulang** ke `POST /devices` |
| **Alasan** | Ini kesalahan paling mahal di Minggu 6. Token berubah saat reinstall, hapus data, pemulihan backup, atau rotasi keamanan FCM. Kalau backend menyimpan token basi, FCM membalas `UNREGISTERED` dan **notifikasi berhenti terkirim tanpa error apa pun di aplikasi** — pengguna mengira aplikasi rusak, pengembang tidak melihat gejala |
| **Bukti** | `firebase_push_service.dart`; `screenshots/10_rotate_token.png` menunjukkan token di perangkat **dan** di backend berubah bersama |

### 2.9 `@pragma('vm:entry-point')` tidak ada

| | |
|---|---|
| **Usulan AI** | Background handler top-level, tanpa `@pragma` |
| **Keputusan** | Tambahkan `@pragma('vm:entry-point')` |
| **Alasan** | Top-level saja belum cukup: tanpa `@pragma`, fungsi yang hanya dipanggil dari native (bukan dari Dart) bisa dianggap tidak terpakai dan dibuang saat tree-shaking pada build rilis. Gejalanya persis seperti "handler tidak pernah jalan" dan tidak muncul di mode debug |
| **Bukti** | `firebase_push_service.dart` |

## 3. Tambahan yang tidak diusulkan AI

### 3.1 `onSessionExpired` pada `buildApiClient`

| | |
|---|---|
| **Masalah** | Setelah interceptor membersihkan token karena refresh ikut mati, state autentikasi Riverpod tidak tahu apa-apa: token sudah hilang, tetapi UI masih diam di beranda sampai pengguna memicu request berikutnya |
| **Keputusan** | `buildApiClient` menerima `onSessionExpired`; `providers.dart` menyambungkannya ke `AuthNotifier.forceLogout()`; guard GoRouter yang memindahkan pengguna ke `/login` |
| **Alasan** | Menghapus token adalah tindakan **lapisan data**; mengubah rute adalah tindakan **lapisan UI**. Tanpa jembatan eksplisit, keduanya berjalan sendiri-sendiri dan hasilnya layar yang menggantung di antara "sudah logout" dan "belum logout" |
| **Bukti** | `lib/data/api_client.dart`, `lib/providers/providers.dart`, `lib/providers/auth_provider.dart` (`forceLogout`) |

### 3.2 `TokenStore.mask()`

Utilitas kecil yang membuat aturan "jangan tampilkan token utuh" bisa dipatuhi
tanpa berpikir ulang di setiap halaman, dan bisa diuji (`TokenStore.mask`).

### 3.3 Log lalu lintas yang dirender di UI

Modul mewajibkan **pembuktian** bahwa 401 memicu refresh sekali lalu mengulang.
Klaim di README tidak cukup, jadi log interceptor dirender di halaman *Sesi &
API* dan ikut terfoto. Efek sampingnya: pesan error refresh kini ikut dicatat
(`refresh ikut kedaluwarsa (RangeError: ...)`), sehingga bug §2.2 akan langsung
terlihat di layar kalau terulang.

## 4. Ringkasan keputusan

| # | Usulan AI | Keputusan final | Jenis |
|---|---|---|---|
| 1 | Retry tanpa penanda | Tambah `extra['campus_notify_retried']` | Perbaikan bug (loop) |
| 2 | `nextInt(1 << 32)` | `nextInt(2147483647)` | Perbaikan bug (web) |
| 3 | `save(access, refresh)` saat refresh | `saveAccess(access)` | Perbaikan bug (token basi) |
| 4 | Refresh token di SharedPreferences | Tetap secure storage | Keamanan |
| 5 | Token utuh di halaman debug | `TokenStore.mask()` | Kepatuhan modul |
| 6 | Firebase wajib | Firebase opsional + kanal tiruan | Kelayakan demo |
| 7 | Channel id `pengumuman` | `pengumuman_kampus` (sama dengan manifest) | Perbaikan bug (kanal ganda) |
| 8 | `onTokenRefresh.listen(print)` | Kirim ulang ke `POST /devices` | Perbaikan bug (token basi) |
| 9 | Tanpa `@pragma` | `@pragma('vm:entry-point')` | Perbaikan bug (tree-shaking) |
| 10 | — | `onSessionExpired` → `forceLogout()` | Tambahan |
