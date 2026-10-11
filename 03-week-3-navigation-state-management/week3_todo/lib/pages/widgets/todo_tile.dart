import 'package:flutter/material.dart';
import '../../providers/todo_provider.dart';

// Refactoring Challenge no. 1: bar ToDo dipisah dari TodoPage
// menjadi widget sendiri. build() di TodoPage jadi lebih pendek
// dan bar-nya bisa dites/dipakai ulang dengan mudah.
class TodoTile extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onRemove;

  const TodoTile({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: todo.done,
        onChanged: (_) => onToggle(),
      ),
      title: Text(
        todo.title,
        // Teks dicoret kalau tugas sudah selesai.
        style: TextStyle(
          decoration: todo.done ? TextDecoration.lineThrough : null,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: onRemove,
      ),
    );
  }
}
