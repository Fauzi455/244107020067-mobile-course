// Dialog tambah/edit catatan.
//
// Dipisah sebagai widget tersendiri agar dipakai halaman daftar maupun detail.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/note.dart';
import '../data/providers.dart';

/// Menampilkan dialog editor. Mengembalikan true bila tersimpan.
Future<bool> showNoteEditor(
  BuildContext context,
  WidgetRef ref, {
  Note? existing,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => _NoteEditorDialog(existing: existing),
  );
  return result ?? false;
}

class _NoteEditorDialog extends ConsumerStatefulWidget {
  const _NoteEditorDialog({this.existing});

  final Note? existing;

  @override
  ConsumerState<_NoteEditorDialog> createState() => _NoteEditorDialogState();
}

class _NoteEditorDialogState extends ConsumerState<_NoteEditorDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existing?.title ?? '');
    _bodyController = TextEditingController(text: widget.existing?.body ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    final notifier = ref.read(notesProvider.notifier);
    final existing = widget.existing;
    if (existing == null) {
      await notifier.add(title, _bodyController.text.trim());
    } else {
      await notifier.edit(
        existing.copyWith(
          title: title,
          body: _bodyController.text.trim(),
        ),
      );
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit catatan' : 'Catatan baru'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            autofocus: true,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Judul',
              hintText: 'mis. Belanja mingguan',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Isi',
              hintText: 'Tuliskan detail catatan...',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
