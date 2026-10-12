// UI infinite scroll: scroll controller memicu loadNextPage
// 200px sebelum ujung list. Data lama dipertahankan; indikator loading
// muncul di bawah, tanpa menghapus daftar yang sudah ada.
//
// Baris post memakai `PostTile` (Refactoring Challenge no. 1) dan menampilkan
// keempat state: loading awal, error, empty, dan success.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/paged_posts.dart';
import '../data/providers.dart';
import '../widgets/post_tile.dart';

class PagedPostPage extends ConsumerStatefulWidget {
  const PagedPostPage({super.key});

  @override
  ConsumerState<PagedPostPage> createState() =>
      _PagedPostPageState();
}

class _PagedPostPageState
    extends ConsumerState<PagedPostPage> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.position.pixels >=
          _controller.position.maxScrollExtent - 200) {
        ref.read(pagedPostsProvider.notifier).loadNextPage();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pagedPostsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts Paged'),
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              )
            : null,
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(PagedPostsState state) {
    // 1) Error saat memuat halaman pertama (belum ada data sama sekali).
    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                friendlyErrorMessage(state.error!),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref
                    .read(pagedPostsProvider.notifier)
                    .loadFirstPage(),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    // 2) Loading saat halaman pertama dimuat.
    if (state.items.isEmpty && state.hasMore) {
      return const Center(child: CircularProgressIndicator());
    }

    // 3) Empty: server membalas tetapi tidak ada data.
    if (state.items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Belum ada data dari server.'),
        ),
      );
    }

    // 4) Success + infinite scroll.
    return ListView.builder(
      controller: _controller,
      itemCount: state.items.length + 1,
      itemBuilder: (context, index) {
        if (index == state.items.length) {
          if (!state.hasMore) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('Semua data termuat.')),
            );
          }
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final post = state.items[index];
        return PostTile(
          post: post,
          onTap: () => context.push('/post/${post.id}'),
        );
      },
    );
  }
}
