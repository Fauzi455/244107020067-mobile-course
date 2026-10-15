# Tiga app state — matriks pengujian Minggu 6

Modul mewajibkan ketiga app state diuji **dengan payload yang sama** dan
hasilnya dituliskan sebagai tabel bukti. Berkas ini memuat tabel itu beserta
cara mengulangnya, baik lewat panel simulator (tanpa perangkat) maupun lewat
Firebase Console (perangkat sungguhan).

## Payload yang dipakai

Identik untuk ketiga state — gabungan `notification` + `data`:

```json
{
  "message": {
    "topic": "pengumuman-kampus",
    "notification": {
      "title": "Jadwal kuliah berubah",
      "body": "Kelas Mobile pindah ke Ruang A2 jam 13.00"
    },
    "data": { "route": "/pengumuman/3", "id": "3" }
  }
}
```

Padanan JSON mentah untuk uji cepat dari Firebase Console / `curl` (payload
`data`-nya harus berupa string):

```json
{
  "to": "/topics/pengumuman-kampus",
  "notification": {
    "title": "Jadwal kuliah berubah",
    "body": "Kelas Mobile pindah ke Ruang A2 jam 13.00"
  },
  "data": { "route": "/pengumuman/3", "id": "3" }
}
```

## Tabel hasil

| State | Arti | Handler yang bekerja | Yang diharapkan | Hasil pengujian | Bukti |
|---|---|---|---|---|---|
| **Foreground** | Aplikasi terbuka | `FirebaseMessaging.onMessage` → `NotificationPresenter.show()` | Sistem **tidak** menampilkan apa pun; banner lokal muncul (judul, isi, tujuan). Ketuk banner → `/pengumuman/3` | Banner lokal muncul dengan judul "Jadwal kuliah berubah", isi kelas pindah ke Ruang A2, dan label `ketuk → /pengumuman/3`. Jejak log: `foreground → banner lokal /pengumuman/3` | [`../screenshots/07_push_foreground.png`](../screenshots/07_push_foreground.png) |
| **Background** | Aplikasi diminimize | Banner sistem otomatis + `onMessageOpenedApp` saat diklik | Banner sistem muncul; klik membuka `/pengumuman/3` | Halaman pengumuman terbuka dengan penanda `Deep link /pengumuman/3` dan `Dibuka dari state: background`. Jejak log: `background → klik banner /pengumuman/3` | [`../screenshots/08_push_background_deeplink.png`](../screenshots/08_push_background_deeplink.png) |
| **Terminated** | Aplikasi dimatikan | `getInitialMessage()` saat dibuka dari notifikasi | Aplikasi terbuka langsung ke `/pengumuman/3` | Halaman pengumuman terbuka dengan penanda `Deep link /pengumuman/3` dan `Dibuka dari state: terminated`. Jejak log: `terminated → getInitialMessage /pengumuman/3` | [`../screenshots/09_push_terminated_deeplink.png`](../screenshots/09_push_terminated_deeplink.png) |

Yang harus sama pada ketiga baris: **rute tujuan**. Kalau `data.route` hilang
atau salah normalisasi, ketiganya mendarat di beranda — bug klasik "klik
notifikasi nyasar" yang tidak terlihat dari membaca kode. Karena itu
`routeFromMessage()` diuji terpisah 10 kali di
[`../test/push_routing_test.dart`](../test/push_routing_test.dart).

## Cara mengulang — A. Panel Simulator FCM (tanpa perangkat)

Panel ini menyuntikkan pesan ke **jalur penanganan yang sama** dengan FCM
sungguhan (`PushService.events` → `main.dart` → presenter/router). Yang berbeda
hanya sumber pesannya, bukan logikanya — itulah sebabnya hasilnya sah sebagai
bukti perilaku penanganan.

1. Jalankan aplikasi (`flutter run`, atau web: `flutter build web --release`
   lalu `node tool/serve_web.js build/web 8123`).
2. Masuk dengan kredensial yang terisi otomatis.
3. Tab **Beranda** → panel **Simulator FCM**:
   - **Foreground (banner lokal)** → banner lokal muncul di atas halaman.
   - **Background (klik banner)** → masuk `/pengumuman/3`, penanda `background`.
   - **Terminated (getInitialMessage)** → masuk `/pengumuman/3`, penanda
     `terminated`.
4. Tab **Push & Token** → bagian **Jejak lifecycle** menampilkan ketiga baris
   di atas sebagai bukti tekstual.

## Cara mengulang — B. Firebase Console (perangkat sungguhan)

Butuh perangkat/emulator dengan Google Play Services dan project Firebase yang
sudah didaftarkan (lihat [`firebase_setup.md`](firebase_setup.md)).

1. **Foreground** — buka aplikasi, lalu Firebase Console → *Messaging* →
   *Create campaign* → *Firebase Notification messages* → isi title & body →
   *Additional options* → **Custom data**: `route` = `/pengumuman/3`,
   `id` = `3` → *Send*. Banner lokal harus muncul.
2. **Background** — tekan Home (jangan tutup aplikasi), kirim pesan lagi.
   Banner **sistem** muncul; ketuk → aplikasi terbuka di `/pengumuman/3`.
3. **Terminated** — swipe-close aplikasi (dari daftar aplikasi terakhir), kirim
   pesan lagi, lalu ketuk banner → aplikasi terbuka langsung di
   `/pengumuman/3` lewat `getInitialMessage()`.
4. Simpan tangkapan layar notifikasi background sebagai
   `screenshots/fcm-console-test.png`.

> Catatan Android 13+: tanpa izin `POST_NOTIFICATIONS` yang diberikan,
> notifikasi background/terminated tidak muncul sama sekali. Izin diminta saat
> aplikasi start lewat `FirebaseMessaging.instance.requestPermission()`.

## Kapan memakai topik, kapan memakai token perangkat

| Kebutuhan | Saluran | Contoh kampus |
|---|---|---|
| Broadcast ke banyak pengguna, isi sama | **Topik** (`pengumuman-kampus`) | Pengumuman jadwal UAS, pemeliharaan portal akademik, info beasiswa |
| Pesan personal, tidak boleh dibaca orang lain | **Token perangkat** (`POST /devices`) | Nilai ujian, tagihan UKT, peringatan akademik per mahasiswa |

Aplikasi ini memakai keduanya: topik untuk broadcast, dan registration token
perangkat yang dicatat backend lewat `POST /devices` (halaman *Push & Token*
menampilkan daftar token yang tercatat sebagai buktinya).
