import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'pages/stats_page.dart';
import 'pages/todo_page.dart';

void main() => runApp(const ProviderScope(child: MyApp()));

// ProviderScope membungkus seluruh aplikasi: semua provider
// (state ToDo, statistik, filter) disimpan di wadah global ini.
// State tetap hidup walau halaman di-unmount, dan bisa diakses
// dari mana saja tanpa prop drilling.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // GoRouter: daftar tugas ada di '/', statistik ada di '/stats'.
    // Setiap halaman dibungkus AppShell agar NavigationBar tetap
    // ada di dua halaman sekaligus.
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => const MaterialPage(
            child: AppShell(child: TodoPage()),
          ),
        ),
        GoRoute(
          path: '/stats',
          pageBuilder: (context, state) => const MaterialPage(
            child: AppShell(child: StatsPage()),
          ),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Week 3 - ToDo',
      routerConfig: router,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
    );
  }
}

// Scaffold bersama yang menampilkan NavigationBar di dua halaman.
// Refactoring Challenge no. 3: ToDo + GoRouter + NavigationBar.
class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // GoRouterState.of(context) memberi lokasi Uri yang sedang aktif
    // di router, dipakai untuk menentukan tab mana yang sedang terpilih.
    final location = GoRouterState.of(context).uri.path;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: location == '/stats' ? 1 : 0,
        onDestinationSelected: (index) {
          // context.go(): mengganti stack (bukan menumpuk),
          // jadi tombol back sistem tidak membuat halaman menumpuk
          // seperti tab seharusnya.
          index == 0 ? context.go('/') : context.go('/stats');
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Tugas',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Statistik',
          ),
        ],
      ),
    );
  }
}
