// Unit test untuk notifier (bagian yang diminta AI Prompt Challenge:
// "Berikan unit test untuk notifier-nya"). Di luar UI, jadi cepat.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week3_todo/providers/todo_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  group('TodoListNotifier', () {
    test('state awal adalah daftar kosong', () {
      expect(container.read(todoListProvider), isEmpty);
    });

    test('add menambah tugas baru', () {
      container.read(todoListProvider.notifier).add('Belajar Riverpod');
      final todos = container.read(todoListProvider);
      expect(todos, hasLength(1));
      expect(todos.first.title, 'Belajar Riverpod');
      expect(todos.first.done, isFalse);
    });

    test('toggle membalik status selesai', () {
      container.read(todoListProvider.notifier).add('Tugas');
      container.read(todoListProvider.notifier).toggle(0);
      expect(container.read(todoListProvider).single.done, isTrue);
      container.read(todoListProvider.notifier).toggle(0);
      expect(container.read(todoListProvider).single.done, isFalse);
    });

    test('remove menghapus tugas di index tertentu', () {
      container.read(todoListProvider.notifier).add('A');
      container.read(todoListProvider.notifier).add('B');
      container.read(todoListProvider.notifier).add('C');
      container.read(todoListProvider.notifier).remove(1);
      expect(
        container.read(todoListProvider).map((t) => t.title),
        ['A', 'C'],
      );
    });
  });

  group('pendingFilterProvider (provider turunan)', () {
    test('hanya mengembalikan tugas yang belum selesai', () {
      final notifier = container.read(todoListProvider.notifier);
      notifier.add('Selesai');
      notifier.add('Belum');
      notifier.toggle(0); // tandai pertama sebagai selesai

      final pending = container.read(pendingTodosProvider);
      expect(pending.map((t) => t.title), ['Belum']);
    });
  });

  group('todoStatsProvider', () {
    test('menghitung total, selesai, dan belum selesai', () {
      final notifier = container.read(todoListProvider.notifier);
      notifier.add('1');
      notifier.add('2');
      notifier.add('3');
      notifier.toggle(0);
      notifier.toggle(2);

      final stats = container.read(todoStatsProvider);
      expect(stats.total, 3);
      expect(stats.done, 2);
      expect(stats.pending, 1);
    });
  });
}
