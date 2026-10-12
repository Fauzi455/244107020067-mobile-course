// Kerangka navigasi utama (NavigationBar Material 3).
//
// Ini "shell" aplikasi, bukan fitur domain: ia hanya menyusun tiga halaman
// presentasi (notes, posts, settings) dalam satu IndexedStack. Fitur tidak
// saling mengimpor widget — komunikasi antar fitur dilakukan lewat provider
// atau rute.

import 'package:flutter/material.dart';

import '../../../notes/presentation/pages/notes_page.dart';
import '../../../posts/presentation/pages/cached_posts_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';

class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key});

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [NotesPage(), CachedPostsPage(), SettingsPage()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.sticky_note_2_outlined),
            selectedIcon: Icon(Icons.sticky_note_2),
            label: 'Catatan',
          ),
          NavigationDestination(
            icon: Icon(Icons.cloud_download_outlined),
            selectedIcon: Icon(Icons.cloud_download),
            label: 'Posts',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }
}
