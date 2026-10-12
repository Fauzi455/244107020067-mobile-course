// Halaman detail catatan.
//
// Rute: `/note/:id` (GoRouter). Data dibaca lewat `noteDetailProvider` yang
// memanggil repository, bukan dioper dari state halaman list. Ini membuat
// halaman detail tetap benar saat dibuka lewat deep link.
//
// Parameter rute di-parsing oleh fungsi murni `parseNoteId` (core/format.dart).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/failures.dart';
import '../../../../core/format.dart';
import '../providers/notes_providers.dart';
import '../widgets/note_editor_dialog.dart';

class NoteDetailPage extends ConsumerWidget {
  const NoteDetailPage({super.key, required this.noteId});

  final int noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteAsync = ref.watch(noteDetailProvider(noteId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Catatan'),
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              )
            : null,
        actions: [
          noteAsync.maybeWhen(
            data: (note) => note == null
                ? const SizedBox.shrink()
                : Row(
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () =>
                            showNoteEditor(context, existing: note),
                      ),
                      IconButton(
                        tooltip: 'Hapus',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _delete(context, ref),
                      ),
                    ],
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: noteAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Gagal memuat catatan.\n${userMessage(err)}',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (note) {
          if (note == null) {
            return const Center(child: Text('Catatan tidak ditemukan.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                note.title.isEmpty ? '(tanpa judul)' : note.title,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    note.dirty
                        ? Icons.cloud_upload_outlined
                        : Icons.cloud_done_outlined,
                    size: 16,
                    color: note.dirty
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    note.dirty ? 'Belum tersinkron' : 'Sudah tersinkron',
                    style: theme.textTheme.labelMedium,
                  ),
                  const Spacer(),
                  Text(
                    formatDateTime(note.updatedAt),
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
              const Divider(height: 32),
              Text(
                note.body.isEmpty ? '(tidak ada isi)' : note.body,
                style: theme.textTheme.bodyLarge,
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
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
      await ref.read(notesProvider.notifier).remove(noteId);
      if (context.mounted) {
        context.pop();
      }
    }
  }
}
