# Pengujian — Week 7 Clean Architecture

```
flutter analyze
flutter test
```

Keluaran mentah tersimpan di [`verification/`](verification/).

## Prinsip

Domain diuji **murni**: use case selalu menerima *fake* yang
mengimplementasikan interface `NoteRepository` / `PostRepository`, sehingga
tidak ada SQLite, Dio, atau Firebase yang ikut berjalan. Ini hanya mungkin
karena interface berada di layer domain.

## Daftar test

### `test/get_notes_test.dart` — use case + repository palsu

| Test | Yang dibuktikan |
|---|---|
| `GetNotes meneruskan daftar dari repository` | jalur sukses; `failure == null`, daftar diteruskan apa adanya |
| `GetNotes meneruskan failure tanpa melempar` | kegagalan dikembalikan sebagai `LocalFailure`, bukan exception |
| `GetNotes tidak pernah menyentuh database sungguhan` | use case tidak diam-diam membuat koneksi SQLite |

### `test/sync_notes_test.dart` — aturan bisnis antrean sync

| Test | Yang dibuktikan |
|---|---|
| `tidak melakukan apa-apa bila tidak ada catatan kotor` | `uploadPending()` **tidak** dipanggil saat antrean kosong |
| `menandai bersih setelah upload sukses` | urutan benar: upload dulu, baru `markAllSynced()` |
| `mode offline menolak tanpa menyentuh server` | `OfflineFailure` dan tidak ada penulisan status |
| `upload gagal -> catatan tetap kotor` | kegagalan jaringan tidak menghilangkan pekerjaan dari antrean |

### `test/note_model_test.dart` — batas data → domain

| Test | Yang dibuktikan |
|---|---|
| `aman terhadap field yang hilang` | `fromMap` tidak crash pada baris tidak lengkap |
| `flag dirty bertahan pada serialisasi` | `dirty` 0/1 ↔ `bool` konsisten |
| `dirty=0 pada map dibaca sebagai false` | edge case tipe `num` |
| `toEntity() menghasilkan entity murni` | konversi di batas layer |
| `fromEntity() menyalin seluruh field` | arah sebaliknya juga benar |

### `test/format_test.dart` — fungsi murni `core/format.dart`

Menguji `formatDateTime`, `formatDate`, `formatDateTimeWithSeconds`,
`formatRelative` (deterministik karena `now` disuntik), `parseNoteId`, dan
`parseIsoDate`. Tidak butuh widget test sama sekali — inilah manfaat
memindahkan formatting keluar dari `build()`.

### `test/post_repository_impl_test.dart` — aturan cache-first

| Test | Yang dibuktikan |
|---|---|
| `cachedPosts mengembalikan isi cache sebagai entity` | cache dibaca tanpa jaringan |
| `refresh sukses -> hasil jaringan disimpan ke cache` | `replaceAll()` dipanggil sekali |
| `refresh gagal -> NetworkFailure, cache lama tidak dirusak` | offline tetap menyajikan data lama |

### `test/note_tile_test.dart` — widget presentasi murni

Badge "Belum tersinkron" muncul tepat saat `dirty == true`, dan `onTap`
dipanggil saat baris diketuk. Tidak perlu `ProviderScope` karena widget tidak
menyentuh provider.

## Hasil

```
00:02 +27: All tests passed!
```

`flutter analyze` → **No issues found!**

## Uji manual (definisi selesai modul)

1. Tambah 3 catatan → badge "Belum tersinkron" muncul, `Badge.count` = 3.
2. Buka detail `/note/:id` → data dibaca ulang dari repository.
3. Tekan sinkron → "3 catatan berhasil disinkronkan.", badge hilang.
4. Aktifkan **Simulasi offline** → catatan tetap terbaca; tekan sinkron →
   "Mode offline aktif: sinkronisasi dilewati."
5. Tab **Posts** → daftar tampil dari cache (cache-first).
6. Ubah tema → persist setelah reload.

Hasil tiap langkah direkam pada `screenshots/`.
