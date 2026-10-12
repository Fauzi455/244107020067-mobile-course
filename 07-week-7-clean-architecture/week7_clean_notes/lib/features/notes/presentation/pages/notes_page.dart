// Halaman daftar catatan (tab "Catatan").
//
// Versi bersih hasil refactor: TIDAK ADA SQL, Dio, JSON, atau formatting
// tanggal mentah di file ini. Halaman hanya membaca state dan memanggil
// notifier — sesuai "Definisi selesai" modul Minggu 7.
//
// Menampilkan keempat state: loading, error (+ retry), empty, dan success.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/failures.dart';
import '../../../../routes.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../providers/notes_providers.dart';
import '../widgets/note_editor_dialog.dart';
import '../widgets/note_tile.dart';

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);
    final dirtyCount = ref.watch(dirtyCountProvider).value ?? 0;
    final forceOffline = ref.watch(forceOfflineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan'),
        actions: [
          if (forceOffline)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Chip(
                avatar: Icon(Icons.wifi_off, size: 16),
                label: Text('Offline'),
                visualDensity: VisualDensity.compact,
              ),
            ),
          Badge.count(
            count: dirtyCount,
            isLabelVisible: dirtyCount > 0,
            child: IconButton(
              tooltip: 'Sinkronkan',
              icon: const Icon(Icons.sync),
              onPressed: () => _sync(context, ref),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showNoteEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('Catatan'),
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorView(
          message: userMessage(err),
          onRetry: () => ref.invalidate(notesProvider),
        ),
        data: (notes) {
          if (notes.isEmpty) {
            return const _EmptyNotes();
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: notes.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final note = notes[index];
              return NoteTile(
                note: note,
                onTap: () => context.push(AppRoutes.noteDetail(note.id ?? 0)),
                onDelete: () => _confirmDelete(context, ref, note.id ?? 0),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _sync(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final count = await ref.read(syncControllerProvider.notifier).sync();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            count == 0
                ? 'Semua catatan sudah sinkron.'
                : '$count catatan berhasil disinkronkan.',
          ),
        ),
      );
    } on FailureException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.failure.message)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Sinkronisasi gagal: $e')));
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    int id,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus catatan?'),
        content: const Text('Catatan akan dihapus permanen dari perangkat.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(notesProvider.notifier).remove(id);
    }
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 12),
            Text(
              'Gagal membaca database lokal.\n$message',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ),
      ),
    );
  }
}

class _EmptyNotes extends StatelessWidget {
  const _EmptyNotes();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.note_add_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('Belum ada catatan', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Ketuk tombol "Catatan" di bawah untuk menambah. '
              'Semua catatan tersimpan di perangkat dan tetap bisa '
              'dibuka tanpa internet.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
