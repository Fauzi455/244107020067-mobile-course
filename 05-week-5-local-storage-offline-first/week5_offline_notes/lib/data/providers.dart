// Provider Riverpod untuk data lokal.
//
// Aturan minggu 5: UI tidak boleh memanggil SQLite/SharedPreferences langsung.
// UI hanya membaca provider (AsyncValue) dan memanggil method notifier.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'local/note.dart';
import 'models/post.dart';
import 'prefs.dart';
import 'repositories/note_repository.dart';
import 'sync.dart';

// --- Infrastruktur ---------------------------------------------------------

final dioProvider = Provider<Dio>((ref) => createDio());

final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => NoteRepository(),
);

final prefsRepositoryProvider = Provider<PrefsRepository>(
  (ref) => PrefsRepository(),
);

// --- Catatan (SQLite) ------------------------------------------------------

class NotesNotifier extends AsyncNotifier<List<Note>> {
  @override
  Future<List<Note>> build() => ref.watch(noteRepositoryProvider).fetchNotes();

  Future<void> add(String title, String body) async {
    await ref.read(noteRepositoryProvider).addNote(title: title, body: body);
    ref.invalidateSelf();
  }

  Future<void> edit(Note note) async {
    await ref.read(noteRepositoryProvider).updateNote(note);
    ref.invalidateSelf();
  }

  Future<void> remove(int id) async {
    await ref.read(noteRepositoryProvider).deleteNote(id);
    ref.invalidateSelf();
  }
}

final notesProvider = AsyncNotifierProvider<NotesNotifier, List<Note>>(
  NotesNotifier.new,
  // Matikan retry otomatis Riverpod 3 agar error langsung final & mudah diuji.
  retry: (retryCount, error) => null,
);

/// Badge jumlah catatan yang belum tersinkron (antrean sync).
final dirtyCountProvider = FutureProvider<int>((ref) async {
  // Ikut berubah setiap daftar catatan berubah (tambah/hapus/edit/sync).
  await ref.watch(notesProvider.future);
  return ref.read(noteRepositoryProvider).countDirty();
});

/// Detail catatan dibaca dari repository lokal (bukan dari state halaman list).
final noteDetailProvider = FutureProvider.family<Note?, int>((ref, id) async {
  ref.watch(notesProvider); // refresh saat daftar catatan berubah
  return ref.read(noteRepositoryProvider).fetchNoteById(id);
});

// --- Preferensi (SharedPreferences) ----------------------------------------

class DarkModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.watch(prefsRepositoryProvider).getDarkMode();

  Future<void> toggle() async {
    final next = !(state.value ?? false);
    await ref.read(prefsRepositoryProvider).setDarkMode(next);
    state = AsyncData(next);
  }
}

final darkModeProvider =
    AsyncNotifierProvider<DarkModeNotifier, bool>(DarkModeNotifier.new);

final lastOpenedProvider = FutureProvider<String?>(
  (ref) => ref.watch(prefsRepositoryProvider).getLastOpened(),
);

// --- Offline-first: cache-first posts + antrean sync -----------------------

/// Toggle simulasi offline yang deterministik (tidak bergantung Wi-Fi).
class ForceOfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

final forceOfflineProvider =
    NotifierProvider<ForceOfflineNotifier, bool>(ForceOfflineNotifier.new);

class CachedPostsNotifier extends AsyncNotifier<List<Post>> {
  @override
  Future<List<Post>> build() async {
    // 1) Segera kembalikan cache agar UI tidak blank saat offline.
    final cached = await readCachedPosts();
    // 2) Refresh dari jaringan di background.
    Future.microtask(refreshFromNetwork);
    return cached;
  }

  Future<void> refreshFromNetwork() async {
    if (ref.read(forceOfflineProvider)) return;
    try {
      final posts = await fetchPostsFromNetwork(dio: ref.read(dioProvider));
      await writeCachedPosts(posts);
      state = AsyncData(posts);
    } catch (e, st) {
      // Cache-first: bila jaringan gagal, pertahankan cache yang ada.
      final cached = await readCachedPosts();
      if (cached.isEmpty) {
        state = AsyncError(e, st);
      } else {
        state = AsyncData(cached);
      }
    }
  }
}

final cachedPostsProvider =
    AsyncNotifierProvider<CachedPostsNotifier, List<Post>>(
  CachedPostsNotifier.new,
  retry: (retryCount, error) => null,
);

class SyncController extends AsyncNotifier<int> {
  @override
  Future<int> build() async => 0;

  /// Jalankan antrean sinkronisasi. Mengembalikan jumlah catatan tersinkron.
  Future<int> sync() async {
    state = const AsyncLoading();
    try {
      final count = await syncNotes(
        ref.read(noteRepositoryProvider),
        forceOffline: ref.read(forceOfflineProvider),
      );
      ref.invalidate(notesProvider);
      state = AsyncData(count);
      return count;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final syncControllerProvider =
    AsyncNotifierProvider<SyncController, int>(
  SyncController.new,
  retry: (retryCount, error) => null,
);
