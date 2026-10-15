// Tab Beranda: sapaan, daftar pengumuman dari API kampus, dan panel
// **Simulator FCM**.
//
// Panel simulator adalah kunci pembuktian di lingkungan tanpa emulator: ia
// menyuntikkan pesan ke jalur penanganan yang sama dengan FCM sungguhan
// sehingga ketiga app state tetap bisa diperagakan dan difoto.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/announcements.dart';
import '../data/api_errors.dart';
import '../messaging/push_service.dart';
import '../providers/auth_provider.dart';
import '../providers/providers.dart';
import '../routes.dart';

final _announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  return ref.watch(announcementRepositoryProvider).list();
});

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(currentUserEmailProvider);
    final pushState = ref.watch(pushStateProvider);
    final announcements = ref.watch(_announcementsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _GreetingCard(
          email: email.value ?? '(memuat…)',
          pushLabel: pushState.serviceLabel,
          isReal: pushState.isReal,
        ),
        const SizedBox(height: 18),
        const _SimulatorCard(),
        const SizedBox(height: 22),
        Row(
          children: [
            const Icon(Icons.campaign_outlined, size: 20),
            const SizedBox(width: 8),
            Text(
              'Pengumuman kampus',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Muat ulang',
              onPressed: () => ref.invalidate(_announcementsProvider),
              icon: const Icon(Icons.refresh, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 4),
        announcements.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => _ApiErrorCard(
            message: friendlyApiMessage(error),
            onRetry: () => ref.invalidate(_announcementsProvider),
          ),
          data: (items) => Column(
            children: [for (final item in items) _AnnouncementTile(item: item)],
          ),
        ),
      ],
    );
  }
}

class _GreetingCard extends StatelessWidget {
  const _GreetingCard({
    required this.email,
    required this.pushLabel,
    required this.isReal,
  });

  final String email;
  final String pushLabel;
  final bool isReal;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selamat datang,',
            style: TextStyle(color: scheme.onPrimaryContainer, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            email,
            style: TextStyle(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
              fontSize: 15.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                isReal ? Icons.verified : Icons.science_outlined,
                size: 15,
                color: scheme.onPrimaryContainer,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Kanal push: $pushLabel',
                  style: TextStyle(
                    color: scheme.onPrimaryContainer,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Panel Simulator FCM — menyuntikkan pesan ke tiga app state.
class _SimulatorCard extends ConsumerWidget {
  const _SimulatorCard();

  Future<void> _emit(
    BuildContext context,
    WidgetRef ref,
    PushEventKind kind,
  ) async {
    final simulator = ref.read(pushServiceProvider).simulator;
    if (simulator == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kanal sungguhan aktif — kirim dari Firebase Console.'),
        ),
      );
      return;
    }
    await simulator.emit(kind: kind);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.send_to_mobile, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Simulator FCM',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Mengirim payload gabungan notification + data '
              '{"route":"/pengumuman/3"} pada tiga app state.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            _SimButton(
              icon: Icons.visibility_outlined,
              label: 'Foreground (banner lokal)',
              onTap: () => _emit(context, ref, PushEventKind.foreground),
            ),
            _SimButton(
              icon: Icons.arrow_circle_down_outlined,
              label: 'Background (klik banner)',
              onTap: () => _emit(context, ref, PushEventKind.opened),
            ),
            _SimButton(
              icon: Icons.power_settings_new,
              label: 'Terminated (getInitialMessage)',
              onTap: () => _emit(context, ref, PushEventKind.initial),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimButton extends StatelessWidget {
  const _SimButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 17),
        label: Align(
          alignment: Alignment.centerLeft,
          child: Text(label, style: const TextStyle(fontSize: 12.5)),
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(38),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  const _AnnouncementTile({required this.item});

  final Announcement item;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          radius: 18,
          child: Text(item.id, style: const TextStyle(fontSize: 13)),
        ),
        title: Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          item.body,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: () => context.push(AppRoutes.announcement(item.id)),
      ),
    );
  }
}

class _ApiErrorCard extends StatelessWidget {
  const _ApiErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud_off, size: 18, color: scheme.onErrorContainer),
              const SizedBox(width: 8),
              Text(
                'Server kampus tidak terjangkau',
                style: TextStyle(
                  color: scheme.onErrorContainer,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: TextStyle(color: scheme.onErrorContainer, fontSize: 12.5),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onRetry,
              child: const Text('Coba lagi'),
            ),
          ),
        ],
      ),
    );
  }
}
