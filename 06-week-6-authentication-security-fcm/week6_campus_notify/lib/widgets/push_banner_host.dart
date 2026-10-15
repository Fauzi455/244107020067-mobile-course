// Banner notifikasi DALAM aplikasi.
//
// Dipakai untuk membuktikan perilaku foreground pada lingkungan tanpa
// perangkat (web/desktop). Di Android/iOS, `NotificationPresenter` juga
// menembakkan banner sistem lewat `flutter_local_notifications`; banner ini
// tetap tampil sebagai lapisan UI yang konsisten.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../messaging/notification_presenter.dart';
import '../providers/providers.dart';

class PushBannerHost extends ConsumerWidget {
  const PushBannerHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presenter = ref.watch(notificationPresenterProvider);

    return Stack(
      children: [
        child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: ValueListenableBuilder<PushBanner?>(
              valueListenable: presenter.banner,
              builder: (context, banner, _) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: banner == null
                      ? const SizedBox.shrink()
                      : _BannerCard(
                          key: ValueKey(banner.route + banner.title),
                          banner: banner,
                          onClose: presenter.dismiss,
                        ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({super.key, required this.banner, required this.onClose});

  final PushBanner banner;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(14),
        color: scheme.inverseSurface,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.notifications_active,
                  size: 18,
                  color: scheme.onPrimary,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      banner.title,
                      style: TextStyle(
                        color: scheme.onInverseSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      banner.body,
                      style: TextStyle(
                        color: scheme.onInverseSurface.withValues(alpha: 0.86),
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'ketuk → ${banner.route}',
                      style: TextStyle(
                        color: scheme.primary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                iconSize: 18,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.close,
                  color: scheme.onInverseSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
