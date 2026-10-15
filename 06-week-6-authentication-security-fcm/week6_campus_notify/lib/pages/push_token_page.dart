// Tab "Push & Token".
//
// Memenuhi bagian "Wajib dibuktikan" pada modul Minggu 6:
//   * token FCM ditampilkan TERPOTONG (12 karakter pertama + …),
//   * `onTokenRefresh` benar-benar mengirim ulang token ke backend,
//   * status langganan topik `pengumuman-kampus`,
//   * jejak tiga app state.
//
// Token penuh tidak pernah dirender, sehingga tidak mungkin ikut terfoto.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api_errors.dart';
import '../data/token_store.dart';
import '../messaging/push_service.dart';
import '../providers/providers.dart';

/// Token yang tercatat di backend (`GET /devices`).
final backendTokensProvider = FutureProvider<List<String>>((ref) async {
  return ref.watch(deviceRegistryProvider).registered();
});

class PushTokenPage extends ConsumerWidget {
  const PushTokenPage({super.key});

  Future<void> _rotate(BuildContext context, WidgetRef ref) async {
    final simulator = ref.read(pushServiceProvider).simulator;
    if (simulator == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rotasi token hanya tersedia pada kanal simulasi.'),
        ),
      );
      return;
    }
    await simulator.rotateToken();
    ref.invalidate(backendTokensProvider);
  }

  Future<void> _toggleTopic(BuildContext context, WidgetRef ref) async {
    final service = ref.read(pushServiceProvider);
    final state = ref.read(pushStateProvider);
    if (state.topicSubscribed) {
      await service.unsubscribe(PushService.campusTopic);
      ref.read(pushStateProvider.notifier).setTopic(false);
      ref.read(pushStateProvider.notifier).log('berhenti langganan topik');
    } else {
      await service.subscribe(PushService.campusTopic);
      ref.read(pushStateProvider.notifier).setTopic(true);
      ref.read(pushStateProvider.notifier).log('langganan topik kembali');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pushStateProvider);
    final scheme = Theme.of(context).colorScheme;
    final backend = ref.watch(backendTokensProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _StatusCard(state: state),
        const SizedBox(height: 16),
        Text('Registration token', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                TokenStore.mask(state.token),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
              ),
              const SizedBox(height: 5),
              Text(
                'Token penuh sengaja tidak dirender — aturan modul: jangan '
                'menampilkan token utuh di screenshot.',
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => _rotate(context, ref),
          icon: const Icon(Icons.autorenew, size: 18),
          label: const Text('Rotasi token (simulasi reinstall)'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
          ),
        ),
        const SizedBox(height: 20),
        Text('Topik broadcast', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: scheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          child: ListTile(
            leading: Icon(
              state.topicSubscribed
                  ? Icons.notifications_active
                  : Icons.notifications_off_outlined,
              color: state.topicSubscribed ? scheme.primary : null,
            ),
            title: Text(
              PushService.campusTopic,
              style: const TextStyle(fontSize: 13.5),
            ),
            subtitle: Text(
              state.topicSubscribed ? 'Berlangganan' : 'Tidak berlangganan',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Switch(
              value: state.topicSubscribed,
              onChanged: (_) => _toggleTopic(context, ref),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Text(
              'Token tercatat di backend',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Muat ulang',
              onPressed: () => ref.invalidate(backendTokensProvider),
              icon: const Icon(Icons.refresh, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 4),
        backend.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Text(
            friendlyApiMessage(error),
            style: TextStyle(fontSize: 12, color: scheme.error),
          ),
          data: (tokens) => tokens.isEmpty
              ? Text(
                  'Belum ada token terdaftar.',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                )
              : Column(
                  children: [
                    for (final token in tokens)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(
                              Icons.smartphone,
                              size: 15,
                              color: scheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                TokenStore.mask(token),
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 20),
        Text(
          'Jejak lifecycle',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (state.log.isEmpty)
          Text(
            'Belum ada peristiwa push.',
            style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
          )
        else
          for (final line in state.log)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.chevron_right, size: 15, color: scheme.primary),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      line,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
        const SizedBox(height: 20),
        const _PlatformNote(),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.state});

  final PushState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          _row(
            context,
            Icons.bolt_outlined,
            'Kanal',
            state.serviceLabel,
          ),
          const SizedBox(height: 9),
          _row(
            context,
            state.permissionGranted
                ? Icons.check_circle_outline
                : Icons.cancel_outlined,
            'Izin notifikasi',
            state.permissionGranted ? 'Diberikan' : 'Belum diberikan',
          ),
          const SizedBox(height: 9),
          _row(
            context,
            state.isReal ? Icons.verified_user_outlined : Icons.science_outlined,
            'Mode',
            state.isReal ? 'FCM sungguhan' : 'Demo tanpa perangkat',
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 17, color: scheme.onPrimaryContainer),
        const SizedBox(width: 9),
        Text(
          label,
          style: TextStyle(color: scheme.onPrimaryContainer, fontSize: 12.5),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ),
      ],
    );
  }
}

/// Perbedaan platform yang ditanyakan pada AI Prompt Challenge.
class _PlatformNote extends StatelessWidget {
  const _PlatformNote();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Android 13+ vs iOS',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: scheme.primary),
          ),
          const SizedBox(height: 7),
          const Text(
            '• Android 13+ wajib POST_NOTIFICATIONS runtime → '
            'FirebaseMessaging.requestPermission() memicunya.\n'
            '• iOS wajib capability Push + APNs key; izin diminta lewat '
            'requestPermission() yang sama.\n'
            '• Handler background TIDAK boleh menyentuh BuildContext / '
            'Riverpod di kedua platform (isolate terpisah).',
            style: TextStyle(fontSize: 11.5, height: 1.45),
          ),
        ],
      ),
    );
  }
}
