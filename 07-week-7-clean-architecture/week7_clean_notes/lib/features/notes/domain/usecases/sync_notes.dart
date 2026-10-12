// USE CASE SyncNotes — contoh use case yang BENAR-BENAR dibutuhkan.
//
// Modul Minggu 7 mengingatkan: membuat use case untuk setiap CRUD satu-baris
// adalah over-engineering. `SyncNotes` berbeda karena ia menggabungkan
// beberapa operasi repository + aturan bisnis:
//
//   1. hitung catatan kotor,
//   2. bila tidak ada -> tidak perlu apa-apa (dan TIDAK menyentuh server),
//   3. bila mode offline aktif -> tolak dengan `OfflineFailure`,
//   4. upload antrean,
//   5. tandai bersih HANYA setelah upload sukses (urutan ini adalah aturan
//      bisnis; kalau dibalik, catatan bisa hilang dari antrean tanpa terkirim).
//
// Logika inilah yang pada Minggu 5 masih berupa fungsi bebas `syncNotes()`.

import '../../../../core/failures.dart';
import '../repositories/note_repository.dart';

class SyncNotes {
  const SyncNotes(this._repository);

  final NoteRepository _repository;

  /// Mengembalikan jumlah catatan yang tersinkron, atau [Failure] bila gagal.
  Future<({int synced, Failure? failure})> call({
    bool forceOffline = false,
  }) async {
    final counted = await _repository.countDirty();
    if (counted.failure != null) {
      return (synced: 0, failure: counted.failure);
    }
    if (counted.dirtyCount == 0) {
      return (synced: 0, failure: null);
    }
    if (forceOffline) {
      return (
        synced: 0,
        failure: const OfflineFailure(
          'Mode offline aktif: sinkronisasi dilewati.',
        ),
      );
    }

    final uploaded = await _repository.uploadPending();
    if (uploaded.failure != null) {
      return (synced: 0, failure: uploaded.failure);
    }

    final marked = await _repository.markAllSynced();
    if (marked != null) {
      return (synced: 0, failure: marked);
    }

    return (synced: uploaded.uploaded, failure: null);
  }
}
