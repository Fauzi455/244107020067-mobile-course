// Widget baris catatan — presentasi murni.
//
// Widget ini tidak tahu apa-apa soal SQLite, provider, atau navigasi. Ia
// hanya menerima entity `Note` dan callback. Formatting tanggal pun tidak
// ditulis di sini, melainkan memanggil `core/format.dart`.

import 'package:flutter/material.dart';

import '../../../../core/format.dart';
import '../../domain/entities/note.dart';

class NoteTile extends StatelessWidget {
  const NoteTile({super.key, required this.note, this.onTap, this.onDelete});

  final Note note;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: note.dirty
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.primaryContainer,
        child: Icon(
          note.dirty ? Icons.cloud_upload_outlined : Icons.cloud_done_outlined,
          color: note.dirty
              ? theme.colorScheme.onErrorContainer
              : theme.colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(
        note.title.isEmpty ? '(tanpa judul)' : note.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (note.body.isNotEmpty)
            Text(note.body, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(
            formatDateTime(note.updatedAt),
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (note.dirty)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: _DirtyBadge(),
            ),
          if (onDelete != null)
            IconButton(
              tooltip: 'Hapus',
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _DirtyBadge extends StatelessWidget {
  const _DirtyBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Belum tersinkron',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onErrorContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
