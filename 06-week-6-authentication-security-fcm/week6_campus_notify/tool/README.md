# tool/ — backend tiruan, verifikasi, dan dokumentasi

Skrip di folder ini **tidak** bagian dari aplikasi; hanya alat bantu untuk
memenuhi ketentuan modul Minggu 6 (bukti jalur refresh dan screenshot tiga app
state). Tidak ada dependensi Node eksternal kecuali `puppeteer-core` yang dipakai
pengambil screenshot.

| Berkas | Kegunaan | Dependensi |
|---|---|---|
| `mock_api_server.js` | Backend tiruan Campus API (termasuk `401` sungguhan lewat `POST /debug/expire`) | tidak ada (Node built-in) |
| `check_api_flow.js` | Memverifikasi kontrak mock API **tanpa** aplikasi Flutter | tidak ada |
| `verify_refresh_flow.js` | Memverifikasi rantai 401 → refresh → retry **di dalam aplikasi yang berjalan** (klien, bukan server) | `puppeteer-core` |
| `serve_web.js` | Static file server untuk hasil `flutter build web` (fallback `index.html` agar deep link bisa dibuka langsung) | tidak ada |
| `screenshot_web.js` | Mengambil screenshot satu langkah per proses pada viewport layout mobile | `puppeteer-core` |
| `dump_semantics.js` | Membuang *accessibility tree* Flutter web untuk mengkalibrasi koordinat tombol | `puppeteer-core` |

---

## 1. Mengapa perlu server sungguhan padahal auth-nya mock?

Karena jalur yang **wajib dibuktikan** modul — "401 memicu refresh sekali lalu
mengulang request" — tidak bisa dibuktikan tanpa ada pihak yang benar-benar
mengembalikan **401**. `mock_api_server.js` melakukannya secara deterministik:

```
POST /auth/login      -> { access_token, refresh_token }
POST /auth/refresh    -> { access_token }   (refresh token di BODY, bukan URL)
GET  /me              -> 401 bila access token dicabut/kedaluwarsa
GET  /announcements   -> daftar pengumuman kampus
GET  /announcements/:id
POST /devices         -> simpan registration token FCM per pengguna (ganti, bukan tumpuk)
GET  /devices         -> daftar token yang tercatat
POST /debug/expire    -> cabut SEMUA access token yang pernah dilihat selama 20 detik (untuk memicu 401)
GET  /health
```

```bash
node tool/mock_api_server.js 8787     # terminal 1
node tool/check_api_flow.js           # terminal 2
```

Keluaran terakhir disimpan di
[`../docs/verification/mock_api_flow.txt`](../docs/verification/mock_api_flow.txt).

> Skrip ini sengaja **tidak** memanggil `process.exit()`. Memutus koneksi
> keep-alive Node secara paksa memicu assertion libuv di Windows dan membuat
> keluaran kotor; `process.exitCode` sudah cukup.

---

## 2. Screenshot (layout mobile)

```bash
flutter build web --release

# terminal 1
node tool/serve_web.js build/web 8123

# terminal 2 — satu langkah per perintah, Chrome ditutup tiap selesai
npm install puppeteer-core --prefix tool
FRESH=1 node tool/screenshot_web.js screenshots/01_login.png login
FRESH=1 node tool/screenshot_web.js screenshots/02_login_error.png login_error
FRESH=1 node tool/screenshot_web.js screenshots/03_beranda.png beranda
FRESH=1 node tool/screenshot_web.js screenshots/04_sesi_token.png sesi
FRESH=1 node tool/screenshot_web.js screenshots/05_api_401_refresh.png api_401
FRESH=1 node tool/screenshot_web.js screenshots/06_push_token.png push
FRESH=1 node tool/screenshot_web.js screenshots/07_push_foreground.png foreground
FRESH=1 node tool/screenshot_web.js screenshots/08_push_background_deeplink.png background
FRESH=1 node tool/screenshot_web.js screenshots/09_push_terminated_deeplink.png terminated
FRESH=1 node tool/screenshot_web.js screenshots/10_rotate_token.png rotate
FRESH=1 node tool/screenshot_web.js screenshots/11_logout_dialog.png logout_dialog
FRESH=1 node tool/screenshot_web.js screenshots/12_deep_link_manual.png announcement
```

`FRESH=1` menghapus profil browser lebih dulu sehingga tiap langkah dimulai dari
keadaan "belum login" — hasilnya deterministik dan tidak bergantung langkah lain.

Variabel lingkungan: `CHROME_EXECUTABLE`, `APP_URL`, `PROFILE_DIR`.

Keterangan lebih lengkap: [`../docs/screenshots.md`](../docs/screenshots.md).

---

## 3. Kalibrasi koordinat

Flutter web merender ke `<canvas>`, jadi koordinat tombol tidak bisa dibaca dari
DOM biasa. Semua angka di `screenshot_web.js` berasal dari *accessibility tree*,
bukan tebakan:

```bash
node tool/dump_semantics.js home       # atau: login, session, push, announcement, logout_dialog
```

Skrip itu mengklik placeholder "Enable accessibility" lebih dulu, lalu mencetak
setiap node `flt-semantics` beserta koordinat pusatnya (dan `<input>` untuk field
teks, yang dirender sebagai elemen DOM asli).

---

## 4. Kalau langkah pertama gagal dengan `EPERM` / *browser is already running*

Chrome dari langkah sebelumnya masih memegang `tool/.chrome-profile`. Tutup dulu:

```powershell
Get-CimInstance Win32_Process -Filter "Name='chrome.exe'" |
  Where-Object { $_.CommandLine -like '*week6_campus_notify*' } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
```

`tool/node_modules/` dan `tool/.chrome-profile/` sudah di-`.gitignore`.
