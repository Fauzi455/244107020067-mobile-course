import 'package:riverpod/riverpod.dart';

// ======================= Model =======================
// Todo adalah data immutable sederhana: setiap perubahan
// membuat objek baru lewat copyWith(), bukan mengubah objek lama.
class Todo {
  Todo(this.title, {this.done = false});
  final String title;
  final bool done;

  Todo copyWith({String? title, bool? done}) =>
      Todo(title ?? this.title, done: done ?? this.done);
}

// ======================= Notifier =======================
// Notifier<List<Todo>>: state-nya sebuah daftar Todo.
// Aturan penting: JANGAN ubah list lama (misal state.add(...)).
// Selalu buat list baru ([...state, ...]) supaya Riverpod
// bisa mendeteksi perubahan dan mererender UI.
class TodoListNotifier extends Notifier<List<Todo>> {
  @override
  List<Todo> build() => const []; // state awal: daftar kosong

  void add(String title) => state = [...state, Todo(title)];

  void toggle(int index) {
    // Salin dulu list lama, ubah salinannya, lalu simpan list baru.
    final todos = [...state];
    todos[index] = todos[index].copyWith(done: !todos[index].done);
    state = todos;
  }

  void remove(int index) => state = [...state]..removeAt(index);
}

// Tipe eksplisit NotifierProvider agar compile-safe:
// kalau typo atau salah tipe, error langsung saat compile.
final todoListProvider =
    NotifierProvider<TodoListNotifier, List<Todo>>(TodoListNotifier.new);

// ======================= Provider turunan (filter) =======================
// Refactoring Challenge no. 2: logika filter diekstrak jadi
// provider turunan. Dia "menonton" todoListProvider dan
// otomatis dihitung ulang setiap kali daftar berubah.
// UI cukup watch provider ini tanpa menghitung sendiri.
final pendingTodosProvider = Provider<List<Todo>>(
  (ref) {
    final todos = ref.watch(todoListProvider);
    return todos.where((todo) => !todo.done).toList();
  },
);

// Statistik sederhana yang dipakai halaman Stats:
// total tugas, jumlah selesai, dan jumlah belum selesai.
class TodoStats {
  const TodoStats(this.total, this.done);
  final int total;
  final int done;

  int get pending => total - done;
}

final todoStatsProvider = Provider<TodoStats>((ref) {
  final todos = ref.watch(todoListProvider);
  final doneCount = todos.where((todo) => todo.done).length;
  return TodoStats(todos.length, doneCount);
});
