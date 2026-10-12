# AI Challenge — Week 7 Clean Architecture

Modul Minggu 7 menegaskan: AI boleh mengusulkan reorganisasi project, tetapi
**mahasiswa yang menilai trade-off-nya**. Folder ini menyimpan jejaknya.

| Berkas | Isi |
|---|---|
| [`prompt.md`](prompt.md) | prompt yang dikirim ke AI coding assistant |
| [`output_ai_initial.md`](output_ai_initial.md) | keluaran awal AI (apa adanya, sebelum dinilai) |
| [`usulan_vs_keputusan.md`](usulan_vs_keputusan.md) | tabel usulan AI vs keputusan final + alasan teknis |
| [`verification_checklist.md`](verification_checklist.md) | checklist verifikasi modul + temuan |

## Ringkasan

**Diterima dari AI:** pemisahan interface repository (`domain`) dari
implementasinya (`data`), pemecahan `data/providers.dart` per fitur, dan
pemindahan formatting keluar dari widget.

**Ditolak / disederhanakan:**

1. **Use case untuk setiap CRUD** (`AddNote`, `UpdateNote`, `DeleteNote`) —
   over-engineering untuk operasi satu baris. Hanya `GetNotes` dan `SyncNotes`
   yang dipertahankan; `SyncNotes` karena punya aturan bisnis nyata.
2. **`fpdart` / `dartz` (`Either<Failure, T>`)** — diganti *record* Dart
   `({hasil, Failure? failure})` sesuai contoh modul; tanpa dependensi tambahan.
3. **`get_it` sebagai container DI** — Riverpod provider sudah cukup. Dua sistem
   DI berarti dua sumber kebenaran dan dua cara mengganti fake saat test.
4. **`core/api_client.dart`** (Dio di dalam `core/`) — ditolak karena `lib/core`
   wajib steril dari framework (grep sterilitas no. 2). Dio dipindah ke
   `shared/data/network/`.
5. **Repository tunggal `AppRepository`** untuk semua fitur — melanggar
   *Interface Segregation*; tiap fitur punya kontrak sendiri.

**Yang diambil alih dari AI tapi diperbaiki:** AI mengusulkan entity `Note`
tetap membawa `toMap/fromMap`. Modul menyatakan entity harus bebas mapping, jadi
mapping dipindah seluruhnya ke `NoteModel`.

Tanggung jawab teknis yang dipenuhi: prompt, keluaran awal AI, tabel
usulan-vs-keputusan, dan hasil grep verifikasi tersimpan di folder `docs/` ini.
