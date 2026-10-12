# Output Awal AI — Perbandingan Storage

> **Status: BELUM DIVERIFIKASI.** Dokumen ini adalah jawaban awal AI coding
> assistant atas prompt pada `README.md`. Beberapa klaimnya **keliru** dan
> sengaja disimpan apa adanya sebagai bukti proses verifikasi. Hasil akhir dan
> koreksinya ada di [`README.md`](README.md) dan
> [`verification_checklist.md`](verification_checklist.md).

## Prompt

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

## Jawaban AI (awal)

### Tabel perbandingan (klaim AI)

| Kriteria | SharedPreferences | Hive | sqflite (SQLite) | Drift |
|---|---|---|---|---|
| Kompleksitas query | Tidak ada | Rendah | **Tinggi** (SQL manual) | Rendah (DSL) |
| Kebutuhan relasi | Tidak | Tidak | Ya | Ya |
| Reaktivitas (stream) | Tidak | `watch()` | Tidak | `watch()` (stream) |
| Type-safety | Tidak | Sedang | Rendah | **Tinggi** |
| Boilerplate | Sangat kecil | Kecil | Sedang | **Besar** |
| Kemudahan testing | Sulit (plugin) | Sedang | Sedang | Mudah |

### Rekomendasi AI (awal)

- **Preferensi (tema):** Hive — "paling ringan dan bisa menyimpan bool tanpa plugin native".
- **Catatan:** **SharedPreferences** — "cukup simpan daftar sebagai satu string
  JSON, lebih sederhana daripada SQLite".
- Alternatif: Drift untuk "real-time" karena "pasti lebih cepat".
- Skema catatan yang diusulkan:

```json
// Disimpan di SharedPreferences sebagai satu string
{"notes":[{"title":"...","body":"..."}]}
```

### Contoh kode AI (awal)

```dart
// Menyimpan seluruh catatan sebagai JSON di SharedPreferences.
Future<void> saveNotes(List<Note> notes) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setString('notes', jsonEncode(notes.map((n) => n.toMap()).toList()));
}
```

## Masalah pada Jawaban Awal (yang ditemukan saat verifikasi)

1. **Catatan diletakkan di SharedPreferences** — ditolak. Koleksi data di satu
   string JSON rapuh: tiap update menulis ulang seluruh daftar, tidak ada query
   parsial/urut, dan tidak mendukung antrean sync.
2. **Preferensi diusulkan ke Hive** — ditolak. Untuk satu boolean + satu
   timestamp, Hive berlebihan (menambah inisialisasi `Hive.initFlutter` +
   adapter) sedangkan SharedPreferences sudah bawaan dan cukup.
3. **Skema tanpa `dirty`/`updated_at`** — hanya CRUD polos, tidak mendukung
   antrean sinkronisasi yang diwajibkan modul.
4. **Klaim "real-time" tanpa stream** — Drift disebut real-time tetapi tidak
   ada `watch()`/stream yang ditunjukkan.
5. **Estimasi boilerplate** tidak dibuktikan; setelah `flutter pub add` dan
   mencoba, Drift memang butuh build_runner (boilerplate lebih besar).

Lihat koreksi lengkap pada [`README.md`](README.md).
