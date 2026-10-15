// Shell beranda: tiga tab (Beranda, Sesi & API, Push & Token).
//
// Pola ini sama dengan shell yang dipakai pada Minggu 5/7 agar navigasi
// konsisten di seluruh portfolio, dan membuat pengambilan screenshot per tab
// menjadi deterministik.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import 'home_page.dart';
import 'push_token_page.dart';
import 'session_page.dart';

class HomeShellPage extends ConsumerStatefulWidget {
  const HomeShellPage({super.key});

  @override
  ConsumerState<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends ConsumerState<HomeShellPage> {
  int _index = 0;

  static const _titles = ['Beranda', 'Sesi & API', 'Push & Token'];

  static const _tabs = [HomePage(), SessionPage(), PushTokenPage()];

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar?'),
        content: const Text(
          'Seluruh token di secure storage akan dihapus. Anda harus masuk '
          'ulang untuk membuka aplikasi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref.read(authStateProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.vpn_key_outlined),
            selectedIcon: Icon(Icons.vpn_key),
            label: 'Sesi & API',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Push & Token',
          ),
        ],
      ),
    );
  }
}
