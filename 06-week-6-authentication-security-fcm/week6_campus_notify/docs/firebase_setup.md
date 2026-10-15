# Setup Firebase (FCM) — Campus Notify

Berkas ini memisahkan dua hal dengan tegas:

- **§1–§3: yang sudah dipasang di repositori ini** (konfigurasi native Android &
  iOS). Anda tidak perlu mengubahnya lagi.
- **§4–§6: yang hanya bisa Anda lakukan** di Firebase Console, karena butuh akun
  dan menghasilkan berkas rahasia yang tidak boleh masuk repositori publik.

Aplikasi **dirancang tetap berjalan tanpa Firebase**: `Firebase.initializeApp()`
dibungkus `try/catch` di `lib/main.dart`, dan bila gagal, kanal push tiruan
(`SimulatedPushService`) yang dipakai. Jadi urutan kerjanya bebas — Anda bisa
mendemokan aplikasi dulu, baru mendaftarkan Firebase.

---

## 1. Yang sudah dipasang — Android

### `android/settings.gradle.kts`

```kotlin
id("com.google.gms.google-services") version "4.4.4" apply false
```

Plugin **didaftarkan** di sini tetapi **belum di-apply** — supaya project tetap
bisa di-build sebelum Firebase didaftarkan.

### `android/app/build.gradle.kts`

| Perubahan | Alasan |
|---|---|
| `isCoreLibraryDesugaringEnabled = true` + `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")` | `flutter_local_notifications` 22.x memakai API `java.time` yang hanya ada di Android 8+; desugaring menurunkannya ke perangkat lama tanpa menaikkan `minSdk` |
| `minSdk = flutter.minSdkVersion` (default Flutter saat ini **24**) | `firebase_messaging` butuh API 21+, `flutter_secure_storage` butuh API 23+ (Keystore/EncryptedSharedPreferences). Default Flutter (24) sudah memenuhi keduanya, jadi nilainya dibiarkan mengikuti SDK — **jangan diturunkan di bawah 23** |
| `apply(plugin = "com.google.gms.google-services")` **hanya bila `google-services.json` ada** | Plugin ini **gagal total** kalau berkasnya tidak ada. Dengan pemasangan bersyarat: belum ada berkas → build normal (kanal tiruan); sudah ada berkas → FCM langsung aktif tanpa mengubah kode lagi |

```kotlin
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
} else {
    // build tetap jalan, push memakai SimulatedPushService
}
```

### `android/app/src/main/AndroidManifest.xml`

| Tambahan | Alasan |
|---|---|
| `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>` | Android 13+ (API 33) mewajibkan izin **runtime** untuk menampilkan notifikasi. Izin ini diminta dari kode lewat `FirebaseMessaging.instance.requestPermission()` |
| `com.google.firebase.messaging.default_notification_channel_id` = `pengumuman_kampus` | Pesan berisi `notification` ditampilkan Android **otomatis** saat background/terminated. Tanpa meta-data ini, Android membuat kanal "Miscellaneous" sendiri sehingga prioritas tinggi dan pengaturan penting diabaikan, dan notifikasi bisa tidak muncul saat perangkat idle. Nilainya **harus sama** dengan `NotificationPresenter.channelId` |
| `com.google.firebase.messaging.default_notification_icon` | Ikon kecil notifikasi. Template ini memakai `@mipmap/ic_launcher`; ganti ke drawable monokrom putih sendiri bila sudah tersedia |
| `com.google.firebase.messaging.default_notification_color` | Warna aksen ikon, dari `res/values/colors.xml` (`#1B4B8F`, sama dengan seed theme aplikasi) |

> **Kenapa kanal dibuat di kode juga?** `NotificationPresenter.init()` memanggil
> `createNotificationChannel('pengumuman_kampus', ...)` dengan
> `Importance.high`. Kanal yang dibuat aplikasi dan kanal yang dipakai notifikasi
> otomatis FCM jadi kanal yang **sama**, sehingga pengaturan penting/prioritas
> benar-benar berlaku dan tidak ada dua kanal berbeda di pengaturan sistem.

---

## 2. Yang sudah dipasang — iOS

`ios/Runner/Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

Diperlukan agar perangkat tetap menerima push saat aplikasi di background.
Untuk notifikasi iOS benar-benar muncul, masih ada langkah yang **hanya bisa
dilakukan di Xcode dan Firebase Console** (§4.3) — dan itu butuh macOS.

---

## 3. Yang sudah dipasang — keamanan repositori

`.gitignore` menambahkan:

```
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
```

Kedua berkas berisi API key dan sender ID project Anda. Untuk repositori
portfolio yang publik, keduanya **tidak** di-commit — setiap pengembang menaruh
berkasnya sendiri dari Firebase Console.

Selain itu, aplikasi tidak pernah mencetak token penuh: `TokenStore.mask()`
memotong pada 12 karakter, dan log interceptor Dio hanya menyebut **panjang**
token (`(Bearer …40)`).

---

## 4. Langkah yang harus Anda lakukan di Firebase Console

### 4.1 Buat project

1. Buka <https://console.firebase.google.com/> → **Add project**.
2. Nama bebas, mis. `campus-notify`.
3. Google Analytics boleh **dimatikan** (tidak dibutuhkan minggu ini).
4. Paket **Spark (gratis)** sudah cukup — **tidak perlu kartu kredit**.

### 4.2 Daftarkan aplikasi Android (wajib untuk FCM di Android)

1. Di halaman project → ikon **Android** → *Add app*.
2. **Android package name** harus **persis** sama dengan `applicationId` di
   `android/app/build.gradle.kts`:

   ```
   com.polinema.jti.week6_campus_notify
   ```

   Nama paket yang salah adalah penyebab paling umum "token `null`" — aplikasi
   berjalan, tetapi FCM tidak mengenalinya sama sekali.
3. *Register app* → **Download `google-services.json`**.
4. Taruh berkas itu di:

   ```
   android/app/google-services.json
   ```

5. Selesai. **Jangan** menambahkan baris plugin apa pun secara manual — sudah
   dipasang bersyarat di §1.
6. Hentikan aplikasi lalu `flutter run` **ulang** (bukan hot reload), karena
   plugin native baru ikut dikompilasi.

### 4.3 Daftarkan aplikasi iOS (opsional, butuh macOS)

1. *Add app* → **iOS**, bundle ID:

   ```
   com.polinema.jti.week6CampusNotify
   ```

   (sesuai `PRODUCT_BUNDLE_IDENTIFIER` di `ios/Runner.xcodeproj/project.pbxproj`).
2. Unduh `GoogleService-Info.plist` → taruh di `ios/Runner/`, lalu **tambahkan
   ke target Runner** di Xcode (drag ke project navigator, centang target
   `Runner`). Berkas yang hanya ada di folder tetapi tidak terdaftar di Xcode
   tidak akan terbaca.
3. Di Xcode → target **Runner** → *Signing & Capabilities*:
   - tambahkan **Push Notifications**;
   - tambahkan **Background Modes** → centang *Remote notifications*.
4. Firebase Console → ⚙️ *Project settings* → tab **Cloud Messaging** → bagian
   **APNs authentication key** → *Upload* kunci `.p8` dari Apple Developer
   (Key ID + Team ID). Tanpa ini notifikasi iOS tidak akan pernah muncul.

### 4.4 Pastikan Cloud Messaging API aktif

Firebase Console → ⚙️ *Project settings* → **Cloud Messaging**. Untuk mengirim
dari **Console** tidak ada yang perlu disiapkan lagi.

Kalau kelak backend kampus Anda yang mengirim, backend memakai
**FCM HTTP v1** dengan *service account*: ⚙️ *Project settings* →
**Service accounts** → *Generate new private key*. Simpan JSON itu **di server**,
jangan pernah di aplikasi Flutter.

### 4.5 Ringkasan berkas yang Anda taruh

| Berkas | Lokasi | Untuk |
|---|---|---|
| `google-services.json` | `android/app/` | Android: project ID, sender ID, API key |
| `GoogleService-Info.plist` | `ios/Runner/` (terdaftar di Xcode) | iOS |

Tidak ada berkas Dart yang perlu ditambahkan: `firebase_core` membaca kedua
berkas native itu secara otomatis, sehingga `Firebase.initializeApp()` di
`lib/main.dart` cukup dipanggil tanpa argumen.

---

## 5. Uji kirim pertama dari Firebase Console

Butuh **perangkat fisik atau emulator dengan Google Play Services** (emulator
tanpa ikon Play Store tidak bisa menerima FCM — token akan `null`).

1. Jalankan aplikasi: `flutter run`.
2. Tab **Push & Token** → pastikan:
   - **Kanal** = `FirebaseMessaging` (bukan lagi "Simulasi (kanal tiruan)");
   - **Izin notifikasi** = *Diberikan* (setujui dialog izin saat aplikasi start);
   - **Registration token** terisi (terpotong, mis. `dGhpcy1p… (163 karakter)`);
   - **Token tercatat di backend** terisi — ini bukti `POST /devices` berhasil
     (jalankan `node tool/mock_api_server.js 8787` lebih dulu).
3. Firebase Console → **Messaging** → *Create campaign* →
   *Firebase Notification messages*.
4. Isi **title** dan **text**, mis.:
   - Title: `Jadwal kuliah berubah`
   - Text: `Kelas Mobile pindah ke Ruang A2 jam 13.00`
5. Buka *Additional options* → **Custom data**, tambahkan dua pasangan:

   | Key | Value |
   |---|---|
   | `route` | `/pengumuman/3` |
   | `id` | `3` |

   Tanpa `route`, klik notifikasi akan mendarat di beranda — bukan di halaman
   pengumuman.
6. Target: aplikasi Android Anda → *Send*.
7. Uji ketiga state sesuai tabel di
   [`three_app_states.md`](three_app_states.md):
   - **Foreground** (aplikasi terbuka) → banner lokal muncul;
   - **Background** (tekan Home) → banner sistem muncul, klik masuk
     `/pengumuman/3`;
   - **Terminated** (swipe-close) → klik banner membuka aplikasi langsung di
     `/pengumuman/3`.
8. Simpan tangkapan layar notifikasi background sebagai
   **`screenshots/fcm-console-test.png`** — inilah satu-satunya berkas bukti yang
   belum ada di repositori, karena butuh perangkat dan project Firebase.

### Uji topik broadcast

Untuk mengirim ke topik `pengumuman-kampus`, di langkah 6 pilih **Topic** dan
tulis `pengumuman-kampus` (aplikasi sudah berlangganan otomatis saat start).
Jangan pakai topik untuk pesan personal — gunakan token perangkat
(`POST /devices`).

---

## 6. Kalau ada yang tidak jalan

| Gejala | Penyebab paling mungkin | Perbaikan |
|---|---|---|
| Token `null`, kanal tetap "Simulasi" | `google-services.json` belum ada / salah lokasi / package name tidak sama | Berkas harus di `android/app/`, dan package name di Firebase harus sama persis dengan `applicationId` |
| Build gagal: *"File google-services.json is missing"* | Plugin Google Services di-apply padahal berkas belum ada | Pemasangan sudah bersyarat di repositori ini; pastikan `android/app/build.gradle.kts` tidak diubah kembali menjadi `plugins { id("com.google.gms.google-services") }` tanpa syarat |
| Build gagal di `flutter_local_notifications` | Core library desugaring dimatikan | Pastikan `isCoreLibraryDesugaringEnabled = true` **dan** baris `coreLibraryDesugaring(...)` ada |
| Notifikasi tidak muncul padahal token ada | Izin `POST_NOTIFICATIONS` ditolak (Android 13+) | Pengaturan → Aplikasi → Campus Notify → Notifikasi → izinkan; atau hapus data aplikasi lalu jalankan ulang |
| Notifikasi muncul di kanal "Miscellaneous" | Meta-data `default_notification_channel_id` hilang / beda nilai | Nilainya harus `pengumuman_kampus`, sama dengan `NotificationPresenter.channelId` |
| Notifikasi iOS tidak muncul | APNs key belum diunggah / capability Push belum aktif | §4.3 langkah 3–4 |
| Klik notifikasi mendarat di beranda | `data.route` tidak dikirim, atau tanpa garis miring di depan | Isi custom data `route` = `/pengumuman/3`; `routeFromMessage()` menambah garis miring sendiri, tetapi tidak bisa menebak rute yang tidak dikirim |
| Token berubah tetapi backend masih menyimpan yang lama | Listener `onTokenRefresh` tidak terpasang | Sudah dipasang di `FirebasePushService.start()`; buktinya halaman *Push & Token* → tekan **Rotasi token** dan lihat baris *Token tercatat di backend* ikut berubah |

---

## 7. Di mana FCM dipasang di kode

| Bagian | Berkas |
|---|---|
| Bootstrap Firebase + pemilihan kanal | `lib/main.dart` (`firebaseReady`) |
| Permission, `getToken`, `onTokenRefresh`, topik, tiga handler | `lib/messaging/firebase_push_service.dart` |
| Background handler top-level + `@pragma('vm:entry-point')` | `lib/messaging/firebase_push_service.dart` |
| Banner foreground (sistem + dalam aplikasi) | `lib/messaging/notification_presenter.dart`, `lib/widgets/push_banner_host.dart` |
| `POST /devices` + daftar token tercatat | `lib/data/announcements.dart` (`DeviceRegistry`) |
| Parsing payload → rute | `lib/messaging/push_message.dart` |
| Kanal tiruan untuk demo tanpa perangkat | `lib/messaging/simulated_push_service.dart` |
