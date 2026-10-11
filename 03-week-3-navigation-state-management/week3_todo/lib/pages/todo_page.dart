import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/todo_provider.dart';
import 'widgets/todo_tile.dart';

class TodoPage extends ConsumerWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch: halaman ini berlangganan dua provider.
    // Kalau daftar ToDo berubah ATAU filter dipilih/diubah,
    // build() jalan ulang otomatis. Ini inti dari UI deklaratif.
    final todos = ref.watch(todoListProvider);
    final showPendingOnly = ref.watch(pendingFilterProvider);

    final visibleTodos =
        showPendingOnly ? todos.where((t) => !t.done).toList() : todos;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ToDo Riverpod'),
        // Screenshot-able: tombol di appbar untuk demo filter turunan
        actions: [
          IconButton(
            icon: Icon(
              showPendingOnly ? Icons.filter_alt : Icons.filter_alt_off,
            ),
            tooltip: showPendingOnly
                ? 'Tampilkan semua tugas'
                : 'Hanya yang belum selesai',
            onPressed: () => ref.read(pendingFilterProvider.notifier).toggle(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: visibleTodos.isEmpty
          ? const Center(child: Text('Belum ada tugas'))
          : ListView.builder(
              itemCount: visibleTodos.length,
              itemBuilder: (context, index) => TodoTile(
                todo: visibleTodos[index],
                onToggle: () =>
                    ref.read(todoListProvider.notifier).toggle(index),
                onRemove: () =>
                    ref.read(todoListProvider.notifier).remove(index),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tugas baru'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                // ref.read di callback: cuma memanggil method,
                // TIDAK berlangganan perubahan state.
                ref
                    .read(todoListProvider.notifier)
                    .add(controller.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }
}

// ================= Provider filter (turunan) =================
// Refactoring Challenge: logika filter diekstrak dari widget.
// Notifier<bool> sederhana: true = hanya tampilkan yang belum selesai.
// Method toggle() dipakai widget (UI memanggil method, bukan mengubah
// state langsung -- pola Notifier yang benar).
class PendingFilterNotifier extends Notifier<bool> {
  @override
  bool build() => false; // default: tampilkan semua

  void toggle() => state = !state;
}

final pendingFilterProvider =
    NotifierProvider<PendingFilterNotifier, bool>(PendingFilterNotifier.new);
