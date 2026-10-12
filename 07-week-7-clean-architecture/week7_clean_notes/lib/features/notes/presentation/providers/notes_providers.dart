// WIRING DI + STATE fitur notes (Praktikum 5, modul Minggu 7).
//
// Urutan dependensi yang dibangun di sini:
//   NotesLocalDataSource (data)
//        -> NoteRepositoryImpl (data)  implements  NoteRepository (domain)
//        -> GetNotes / SyncNotes (domain)
//        -> NotesNotifier (presentation)
//
// Presentation TIDAK PERNAH menginstansiasi repository atau membuka database.
// Semua lewat provider, sehingga test cukup `overrideWithValue` pada
// `noteRepositoryProvider`.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/failures.dart';
import '../../../../shared/data/local/app_database.dart';
import '../../data/datasources/notes_local_datasource.dart';
import '../../data/repositories/note_repository_impl.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/usecases/get_notes.dart';
import '../../domain/usecases/sync_notes.dart';
import '../../../settings/presentation/providers/settings_providers.dart';

// --- Data layer ------------------------------------------------------------

final notesLocalDataSourceProvider = Provider<NotesLocalDataSource>(
  (ref) => NotesLocalDataSource(openDb: openAppDb),
);

/// Tipe yang di-ekspos adalah KONTRAK domain, bukan implementasi.
final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => NoteRepositoryImpl(ref.watch(notesLocalDataSourceProvider)),
);

// --- Domain layer ----------------------------------------------------------

/// Use case menerima abstraksi, bukan implementasi.
final getNotesProvider = Provider<GetNotes>(
  (ref) => GetNotes(ref.watch(noteRepositoryProvider)),
);

final syncNotesProvider = Provider<SyncNotes>(
  (ref) => SyncNotes(ref.watch(noteRepositoryProvider)),
);

// --- Presentation layer ----------------------------------------------------

class NotesNotifier extends AsyncNotifier<List<Note>> {
  @override
  Future<List<Note>> build() async {
    // Satu-satunya jalur baca daftar: lewat use case GetNotes.
    final result = await ref.watch(getNotesProvider).call();
    final failure = result.failure;
    if (failure != null) {
      throw FailureException(failure);
    }
    return result.notes;
  }

  /// CRUD sederhana dipanggil langsung ke repository — SENGAJA bukan use case.
  ///
  /// Alasannya ditulis di `docs/AI_challenge/usulan_vs_keputusan.md`:
  /// use case untuk operasi satu baris hanya menambah lapisan tanpa nilai,
  /// sementara use case diwajibkan saat ada aturan bisnis (lihat SyncNotes).
  Future<void> add(String title, String body) async {
    final result = await ref
        .read(noteRepositoryProvider)
        .addNote(title: title, body: body);
    _guard(result.failure);
    ref.invalidateSelf();
  }

  Future<void> edit(Note note) async {
    _guard(await ref.read(noteRepositoryProvider).updateNote(note));
    ref.invalidateSelf();
  }

  Future<void> remove(int id) async {
    _guard(await ref.read(noteRepositoryProvider).deleteNote(id));
    ref.invalidateSelf();
  }

  void _guard(Failure? failure) {
    if (failure != null) {
      throw FailureException(failure);
    }
  }
}

final notesProvider = AsyncNotifierProvider<NotesNotifier, List<Note>>(
  NotesNotifier.new,
  retry: (retryCount, error) => null,
);

/// Badge jumlah catatan yang belum tersinkron (antrean sync).
final dirtyCountProvider = FutureProvider<int>((ref) async {
  // Ikut berubah setiap daftar catatan berubah (tambah/hapus/edit/sync).
  await ref.watch(notesProvider.future);
  final result = await ref.read(noteRepositoryProvider).countDirty();
  return result.dirtyCount;
});

/// Detail catatan dibaca dari repository (bukan dari state halaman list).
///
/// Ini membuat halaman detail tetap benar saat dibuka lewat deep link atau
/// setelah daftar berubah.
final noteDetailProvider = FutureProvider.family<Note?, int>((ref, id) async {
  ref.watch(notesProvider); // refresh saat daftar catatan berubah
  final result = await ref.read(noteRepositoryProvider).fetchNoteById(id);
  final failure = result.failure;
  if (failure != null) {
    throw FailureException(failure);
  }
  return result.note;
});

/// Pengendali antrean sinkronisasi.
class SyncController extends AsyncNotifier<int> {
  @override
  Future<int> build() async => 0;

  /// Menjalankan use case `SyncNotes`. Mengembalikan jumlah catatan tersinkron
  /// dan melempar [FailureException] bila gagal (termasuk mode offline).
  Future<int> sync() async {
    state = const AsyncLoading();
    final result = await ref
        .read(syncNotesProvider)
        .call(forceOffline: ref.read(forceOfflineProvider));
    final failure = result.failure;
    if (failure != null) {
      final exception = FailureException(failure);
      state = AsyncError(exception, StackTrace.current);
      throw exception;
    }
    ref.invalidate(notesProvider);
    state = AsyncData(result.synced);
    return result.synced;
  }
}

final syncControllerProvider = AsyncNotifierProvider<SyncController, int>(
  SyncController.new,
  retry: (retryCount, error) => null,
);
