import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ============ AI CHALLENGE ============
// Halaman statistik dibuat dari prompt yang diminta codelab,
// lalu diverifikasi & diperbaiki lewat checklist di codelab.
// Riwayat lengkapnya ada di folder docs/.

/// Model data untuk satu baris statistik.
class StatRow {
  const StatRow(this.label, this.value);
  final String label;
  final int value;
}

/// AsyncNotifier yang mensimulasikan fetch data statistik:
/// delay 2 detik (gaya network), dan 30% kemungkinan gagal.
/// state-nya AsyncValue sehingga otomatis punya 3 fase:
/// loading -> (error | data).
class StatsNotifier extends AsyncNotifier<List<StatRow>> {
  final _random = Random();

  /// Static flag untuk testing. Nilainya bisa:
  /// - null (default, produksi): pakai acak, 30% gagal.
  /// - true: fetch selalu gagal.
  /// - false: fetch selalu sukses.
  /// Dipakai widget test agar tiap fase AsyncValue bisa diuji
  /// secara deterministik, bebas "flaky" karena random.
  static bool? forceFail;

  @override
  Future<List<StatRow>> build() async => _fetch();

  /// Refresh manual: kembali ke loading, lalu fetch ulang.
  /// AsyncValue.guard menangkap exception dan mengubahnya jadi
  /// AsyncError, jadi tidak perlu try/catch manual yang berantakan.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<List<StatRow>> _fetch() async {
    await Future.delayed(const Duration(seconds: 2));
    // Keputusan gagal/sukses:
    // - Kalau forceFail di-set (test), ikuti nilainya.
    // - Kalau null (produksi), pakai 30% acak.
    final shouldFail = forceFail ?? _random.nextDouble() < 0.3;
    if (shouldFail) {
      throw Exception('Gagal terhubung ke server');
    }
    return const [
      StatRow('Total tugas', 10),
      StatRow('Selesai', 6),
      StatRow('Belum selesai', 4),
    ];
  }
}

final statsProvider =
    AsyncNotifierProvider<StatsNotifier, List<StatRow>>(StatsNotifier.new);

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch DI build: halaman otomatis re-render saat
    // fase AsyncValue berubah (loading -> data / error).
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik'),
        actions: [
          // Tombol untuk kembali ke daftar tugas.
          IconButton(
            icon: const Icon(Icons.checklist_outlined),
            tooltip: 'Ke daftar tugas',
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      //when(): memaksa kita menanganai KETIGA fase AsyncValue
      //di satu tempat, jadi tidak mungkin "lupa" salah satu.
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Gagal memuat: $err'),
              // ref.read di callback: satu kali panggil ulang
              // fetch tanpa berlangganan.
              FilledButton(
                onPressed: () => ref.read(statsProvider.notifier).refresh(),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
        data: (rows) => ListView.builder(
          itemCount: rows.length,
          itemBuilder: (context, index) => ListTile(
            title: Text(rows[index].label),
            trailing: Text(
              '${rows[index].value}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
