// Halaman detail post (Refactoring Challenge no. 3) + daftar komentar
// (AI Prompt Challenge).
//
// Rute: `/post/:id` (GoRouter).
//
// Data post diambil lewat `postDetailProvider` (cache daftar dulu, baru API)
// sedangkan komentar lewat `commentsProvider` (AsyncNotifierProvider.family).
// Keduanya mengembalikan `AsyncValue`, sehingga loading/error/data ditangani
// secara deklaratif tanpa try/catch di widget.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/comments.dart';
import '../data/post_detail.dart';
import '../data/providers.dart';

class PostDetailPage extends ConsumerWidget {
  const PostDetailPage({super.key, required this.postId});

  final int postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(postDetailProvider(postId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Post #$postId'),
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              )
            : null,
      ),
      body: postAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  friendlyErrorMessage(err),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(postDetailProvider(postId)),
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
        data: (post) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(postDetailProvider(postId));
            ref.invalidate(commentsProvider(postId));
            await ref.read(postDetailProvider(postId).future);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                post.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Oleh user #${post.userId}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              Text(post.body, style: Theme.of(context).textTheme.bodyLarge),
              const Divider(height: 40),
              Text(
                'Komentar',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              _CommentSection(postId: postId),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bagian komentar: memakai `commentsProvider` (AsyncNotifierProvider.family)
/// dan menangani sendiri keempat state-nya.
class _CommentSection extends ConsumerWidget {
  const _CommentSection({required this.postId});

  final int postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentsAsync = ref.watch(commentsProvider(postId));

    return commentsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Column(
        children: [
          Text(
            friendlyErrorMessage(err),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => ref.read(commentsProvider(postId).notifier).refresh(),
            child: const Text('Muat ulang komentar'),
          ),
        ],
      ),
      data: (comments) {
        if (comments.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('Belum ada komentar untuk post ini.')),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${comments.length} komentar'),
            const SizedBox(height: 8),
            ...comments.map(
              (c) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(child: Text(c.id.toString())),
                  title: Text(
                    c.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text(
                        c.email,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(c.body),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
