# Prompt yang dikirim ke AI coding assistant

Diadaptasi dari *AI Prompt Challenge* pada modul Minggu 7, disesuaikan dengan
kondisi project yang sebenarnya direfactor (`week5_offline_notes`).

---

```
Project Flutter saya: week5_offline_notes (Minggu 5 — Local Storage & Offline-First).
Fitur: catatan CRUD dengan SQLite + dirty flag + antrean sync, posts cache-first
dari jsonplaceholder, dan preferensi tema di SharedPreferences.

Kondisi folder lib/ saat ini:
  lib/main.dart
  lib/app_router.dart
  lib/pages/{home_page,notes_page,note_detail_page,cached_posts_page,settings_page}.dart
  lib/widgets/{note_tile,note_editor_dialog}.dart
  lib/data/{api_client,prefs,providers,sync}.dart
  lib/data/local/{note,db,db_factory_io,db_factory_stub,db_factory_web}.dart
  lib/data/models/post.dart
  lib/data/repositories/note_repository.dart

Masalah yang saya sadari:
- `lib/data/local/note.dart` adalah entity SEKALIGUS model (ada toMap/fromMap).
- `lib/data/repositories/note_repository.dart` menggabungkan kontrak dan
  implementasi dalam satu kelas, dan melempar exception mentah.
- `lib/data/providers.dart` memuat provider SEMUA fitur dalam satu file.
- `lib/data/sync.dart` berisi aturan bisnis antrean sync sebagai fungsi bebas
  yang dipanggil langsung dari provider.
- `lib/pages/*` dan `lib/widgets/*` masing-masing punya salinan `_formatTime()`
  atau `_prettyTime()`.

Tugas:
1. Usulkan struktur feature-first Clean Architecture (presentation/domain/data)
   untuk fitur notes, posts, dan settings.
2. Untuk setiap file lama, sebutkan tujuan barunya: pindah, pecah, atau hapus.
3. Tandai bagian mana yang over-engineering bila diterapkan pada CRUD sederhana,
   dan kapan use case benar-benar dibutuhkan vs repository langsung ke notifier.
4. Tunjukkan wiring dependency injection dengan Riverpod (tanpa package DI
   tambahan seperti get_it).
5. Jelaskan trade-off setiap keputusan, termasuk di mana menaruh Dio dan SQLite
   agar folder domain dan core tetap steril dari framework.

Batasan yang harus dipatuhi:
- `lib/core` dan `lib/features/*/domain` TIDAK BOLEH mengimpor Flutter, Dio,
  sqflite, atau Firebase (ini akan diverifikasi dengan grep).
- Entity tidak boleh punya toMap/fromMap/toJson.
- Interface repository di domain, implementasi di data.
```

---

## Catatan

- Prompt di atas menyebutkan **masalah spesifik** (bukan hanya "rapikan project")
  supaya keluaran AI bisa dinilai secara teknis, bukan estetis.
- Batasan sterilitas dinyatakan lebih dulu agar usulan AI tidak perlu dibuang
  karena melanggar aturan modul.
