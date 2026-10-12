# AI Prompt Challenge — Perbandingan Storage & Keputusan Final

AI boleh mengusulkan pilihan storage, tetapi **saya yang memutuskan**. Nilai
ada pada kualitas perbandingan, verifikasi, dan dokumentasi.

## 1. Prompt yang Digunakan

```text
Aplikasi Flutter Offline Notes: CRUD catatan + preferensi tema.
Bandingkan SharedPreferences, Hive, sqflite (SQLite), dan Drift
untuk dua kebutuhan ini. Requirements:
- Kriteria: kompleksitas query, kebutuhan relasi, reaktivitas (stream),
  type-safety, ukuran boilerplate, dan kemudahan testing.
- Beri rekomendasi final: mana untuk preferensi, mana untuk catatan,
  beserta alasannya dalam 1 tabel.
- Tunjukkan skema tabel/kotak untuk 1000+ catatan.
Jelaskan trade-off setiap pilihan.
```

## 2. Output Awal AI

Disimpan lengkap di [`output_ai_initial.md`](output_ai_initial.md). AI sempat
merekomendasikan **menyimpan catatan di SharedPreferences** dan **preferensi di
Hive** — keduanya ditolak setelah diverifikasi.

## 3. Tabel Perbandingan Final (hasil verifikasi sendiri)

| Kriteria | SharedPreferences | Hive | sqflite (SQLite) | Drift |
|---|---|---|---|---|
| Kompleksitas query | Tidak ada (key-value) | Rendah (box + index) | Sedang–tinggi (SQL manual) | Rendah (DSL + generated) |
| Kebutuhan relasi | Tidak | Tidak | **Ya** (JOIN, FK) | **Ya** |
| Reaktivitas (stream) | Tidak | `box.watch()` | Tidak (harus invalidate) | **Ya** (`watch()` bawaan) |
| Type-safety | Tidak (dinamis) | Sedang (adapter) | Rendah (map mentah) | **Tinggi** (generated) |
| Ukuran boilerplate | Sangat kecil | Kecil | Sedang | **Besar** (build_runner) |
| Kemudahan testing | Sulit (plugin native) | Sedang | Sedang (bisa in-memory/inject) | Mudah (in-memory bawaan) |
| Ukuran data 1000+ | Buruk (satu blob) | Baik | **Baik** | **Baik** |

## 4. Keputusan Final

| Kebutuhan | Pilihan | Alasan |
|---|---|---|
| **Preferensi** (tema, waktu terakhir dibuka) | **SharedPreferences** | Hanya butuh key-value primitif; tanpa inisialisasi/adapter tambahan; API sederhana dan stabil. |
| **Catatan** (CRUD + antrean sync) | **SQLite via sqflite** | Butuh query terurut (`updated_at DESC`), filter `dirty`, update parsial, dan `COUNT` — semua natural di SQL. Skema + `dirty`/`updated_at` mendukung offline-first. |
| Cache posts (data bacaan API) | **Tabel `cached_posts` di SQLite** | Satu database untuk data lokal + cache; payload JSON per baris. |

**Mengapa bukan Hive untuk catatan?** Hive cepat dan sederhana, tetapi relasi
dan query agregat (mis. hitung `dirty`) kurang nyaman, dan kebutuhan offline-first
di modul ini menuntut struktur kolom eksplisit (`dirty`, `updated_at`).

**Mengapa bukan Drift?** Drift unggul untuk aplikasi besar (type-safe, stream,
migrasi), tetapi untuk codelab ini boilerplate `build_runner` berlebihan.
Drift dicatat sebagai pilihan tepat bila nanti butuh reaktivitas stream dan
query kompleks (lihat Minggu 7+).

## 5. Skema untuk 1000+ Catatan

```sql
CREATE TABLE notes(
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  title      TEXT    NOT NULL,
  body       TEXT    NOT NULL DEFAULT '',
  updated_at TEXT    NOT NULL,          -- ISO-8601, untuk urutan & last-write-wins
  dirty      INTEGER NOT NULL DEFAULT 0 -- 1 = belum tersinkron (antrean sync)
);
CREATE INDEX idx_notes_updated_at ON notes(updated_at DESC); -- 1000+ baris
CREATE INDEX idx_notes_dirty      ON notes(dirty);           -- antrean sync cepat
```

- 1000+ baris aman: SQLite menangani jutaan baris; yang penting **index** pada
  kolom yang dipakai untuk urut/filter.
- Alternatif Hive: satu box `notes` + `notesIndex` (butuh index manual untuk urut).

## 6. Verifikasi Checklist

Lihat [`verification_checklist.md`](verification_checklist.md). Ringkasan:
AI sempat menaruh catatan di SharedPreferences (ditolak), skema awal tanpa
`dirty` (ditambah), klaim real-time tanpa stream (dikoreksi), dan estimasi
boilerplate Drift dibuktikan dengan mencoba `flutter pub add drift` + generator.
