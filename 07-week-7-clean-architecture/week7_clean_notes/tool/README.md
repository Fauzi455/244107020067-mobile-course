# tool/ — verifikasi & dokumentasi

Skrip di folder ini **tidak** bagian dari aplikasi; hanya alat bantu untuk
memenuhi ketentuan modul Minggu 7 (bukti verifikasi dan screenshot).

| Berkas | Kegunaan |
|---|---|
| `check_dependency_rule.ps1` | Menjalankan tiga grep sterilitas modul (padanan `rg`) dan melaporkan hasilnya |
| `serve_web.js` | Static file server untuk menjalankan hasil `flutter build web` |
| `screenshot_web.js` | Mengambil screenshot satu langkah per proses pada viewport layout mobile |

## 1. Verifikasi dependency rule

```powershell
powershell -ExecutionPolicy Bypass -File tool/check_dependency_rule.ps1
```

Keluaran terakhir disimpan di
[`../docs/verification/grep_sterilitas.txt`](../docs/verification/grep_sterilitas.txt).

Catatan: ripgrep (`rg`) tidak tersedia di lingkungan ini, jadi pola yang sama
dijalankan dengan `Select-String`. Cakupan GREP 3 diarahkan ke `pages/` dan
`widgets/` — alasannya ada di
[`../docs/AI_challenge/usulan_vs_keputusan.md`](../docs/AI_challenge/usulan_vs_keputusan.md).

## 2. Screenshot (layout mobile)

```bash
dart run sqflite_common_ffi_web:setup     # sekali saja -> web/sqlite3.wasm
flutter build web --release

# terminal 1
node tool/serve_web.js build/web 8123

# terminal 2 — satu langkah per perintah, Chrome ditutup tiap selesai
npm install puppeteer-core
FRESH=1 node tool/screenshot_web.js screenshots/01_empty.png empty
FRESH=1 node tool/screenshot_web.js screenshots/02_add_dialog.png add_dialog
FRESH=1 node tool/screenshot_web.js screenshots/03_list_dirty.png list_dirty
FRESH=1 node tool/screenshot_web.js screenshots/04_detail.png detail
FRESH=1 node tool/screenshot_web.js screenshots/05_after_sync.png after_sync
FRESH=1 node tool/screenshot_web.js screenshots/06_settings.png settings
FRESH=1 node tool/screenshot_web.js screenshots/07_settings_dark.png settings_dark
FRESH=1 node tool/screenshot_web.js screenshots/08_posts_cached.png posts
FRESH=1 node tool/screenshot_web.js screenshots/09_offline.png offline
FRESH=1 node tool/screenshot_web.js screenshots/10_offline_sync.png offline_sync
```

`FRESH=1` menghapus profil browser lebih dulu sehingga tiap langkah mulai dari
database kosong — hasilnya deterministik dan tidak menumpuk catatan.

Variabel lingkungan yang bisa disetel: `CHROME_EXECUTABLE`, `APP_URL`,
`PROFILE_DIR`.

Keterangan lebih lengkap: [`../docs/screenshots.md`](../docs/screenshots.md).
