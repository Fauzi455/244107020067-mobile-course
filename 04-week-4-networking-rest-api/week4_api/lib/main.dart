// Entry point aplikasi. ProviderScope membungkus seluruh widget tree
// sehingga ref.watch / ref.read bisa digunakan di mana saja.
//
// Setelah Refactoring Challenge, aplikasi memakai `MaterialApp.router`
// dengan GoRouter (lihat app_router.dart).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_router.dart';

void main() => runApp(const ProviderScope(child: MyApp()));

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'Week 4 - REST API',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            colorSchemeSeed: Colors.indigo, useMaterial3: true),
        routerConfig: appRouter,
      );
}
