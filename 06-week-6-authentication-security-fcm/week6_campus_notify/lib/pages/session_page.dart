// Tab "Sesi & API".
//
// Halaman ini adalah alat bukti untuk tiga hal yang diwajibkan modul:
//   1. token hanya ada di secure storage (ditampilkan TERPOTONG),
//   2. 401 memicu refresh satu kali lalu mengulang request,
//   3. refresh yang ikut mati memaksa pengguna login ulang.
//
// Tombol "Uji 401 → refresh → retry" melakukan tiga langkah sekaligus:
// memaksa server menganggap access token kedaluwarsa, memanggil `GET /me`,
// lalu membiarkan interceptor Dio bekerja. Log di bawahnya adalah jejaknya.

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api_errors.dart';
import '../data/token_store.dart';
import '../providers/providers.dart';

/// Pasangan token yang sedang tersimpan (terpotong untuk ditampilkan).
final sessionTokensProvider = FutureProvider<TokenStore>((ref) async {
  return ref.watch(tokenStoreProvider);
});

class SessionPage extends ConsumerStatefulWidget {
  const SessionPage({super.key});

  @override
  ConsumerState<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends ConsumerState<SessionPage> {
  String? _status;
  String? _body;
  bool _ok = true;
  bool _busy = false;

  Dio get _dio => ref.read(apiClientProvider);

  Future<void> _run(
    Future<Response<dynamic>> Function() action, {
    required String label,
  }) async {
    setState(() {
      _busy = true;
      _ok = true;
      _status = 'memproses…';
      _body = label;
    });

    try {
      final res = await action();
      setState(() {
        _ok = true;
        _status = 'HTTP ${res.statusCode}';
        _body = _pretty(res.data);
      });
    } catch (error) {
      setState(() {
        _ok = false;
        _status = 'GAGAL';
        _body = friendlyApiMessage(error);
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _force401Flow() async {
    setState(() => _busy = true);
    // Langkah 1: server menandai seluruh access token sebagai kedaluwarsa.
    await _run(
      () => _dio.post<dynamic>('/debug/expire'),
      label: '1) memaksa access token kedaluwarsa di server…',
    );
    // Langkah 2: request biasa. Interceptor yang menangani 401 + retry.
    await _run(
      () => _dio.get<dynamic>('/me'),
      label: '2) GET /me — perhatikan rantai 401 → refresh → retry di log…',
    );
  }

  String _pretty(Object? data) {
    if (data == null) return '(kosong)';
    try {
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      return data.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(sessionTokensProvider);
    final log = ref.watch(apiLogProvider);
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Text(
          'Token di secure storage',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        store.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Gagal membaca token: $e'),
          data: (_) => const _TokenCards(),
        ),
        const SizedBox(height: 22),
        Text('Uji jalur refresh', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _busy ? null : _force401Flow,
          icon: const Icon(Icons.bolt),
          label: const Text('Uji 401 → refresh → retry'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(46),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _busy
              ? null
              : () => _run(
                  () => _dio.get<dynamic>('/me'),
                  label: 'GET /me',
                ),
          icon: const Icon(Icons.person_outline),
          label: const Text('Panggil GET /me'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
          ),
        ),
        const SizedBox(height: 12),
        _ResponseCard(status: _status, body: _body, ok: _ok),
        const SizedBox(height: 22),
        Row(
          children: [
            const Icon(Icons.receipt_long_outlined, size: 19),
            const SizedBox(width: 8),
            Text('Log lalu lintas', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            IconButton(
              tooltip: 'Bersihkan log',
              onPressed: () => ref.read(apiLogProvider.notifier).clear(),
              icon: const Icon(Icons.delete_sweep_outlined, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (log.isEmpty)
          Text(
            'Belum ada permintaan.',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5),
          )
        else
          for (final entry in log)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    entry.ok ? Icons.check_circle_outline : Icons.error_outline,
                    size: 15,
                    color: entry.ok ? scheme.primary : scheme.error,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      entry.message,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: entry.ok
                            ? scheme.onSurface
                            : scheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

class _TokenCards extends ConsumerWidget {
  const _TokenCards();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(tokenStoreProvider);
    return FutureBuilder<List<String?>>(
      future: Future.wait([store.readAccess(), store.readRefresh()]),
      builder: (context, snapshot) {
        final access = snapshot.data?[0];
        final refresh = snapshot.data?[1];
        return Column(
          children: [
            _TokenRow(
              icon: Icons.vpn_key_outlined,
              label: 'Access token (umur pendek)',
              value: TokenStore.mask(access),
              note: 'Dikirim sebagai Authorization: Bearer …',
            ),
            const SizedBox(height: 10),
            _TokenRow(
              icon: Icons.autorenew,
              label: 'Refresh token (umur panjang)',
              value: TokenStore.mask(refresh),
              note: 'Hanya keluar lewat body POST HTTPS — tidak pernah di URL.',
            ),
          ],
        );
      },
    );
  }
}

class _TokenRow extends StatelessWidget {
  const _TokenRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.note,
  });

  final IconData icon;
  final String label;
  final String value;
  final String note;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
          ),
          const SizedBox(height: 5),
          Text(
            note,
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ResponseCard extends StatelessWidget {
  const _ResponseCard({this.status, this.body, this.ok = true});

  final String? status;
  final String? body;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (status == null) {
      return Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Text(
          'Belum ada respons. Tekan salah satu tombol di atas.',
          style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: ok ? scheme.surfaceContainerHighest : scheme.errorContainer,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            status!,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: ok ? scheme.primary : scheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body ?? '',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11.5,
              color: ok ? scheme.onSurface : scheme.onErrorContainer,
            ),
          ),
        ],
      ),
    );
  }
}
