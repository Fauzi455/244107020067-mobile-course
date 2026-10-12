// Data source cache lokal untuk posts (SQLite).
//
// Menyimpan payload JSON apa adanya di tabel `cached_posts` supaya bentuk
// tabel tidak perlu ikut berubah setiap kali API menambah field.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../shared/data/local/app_database.dart';
import '../models/post_model.dart';

/// Wiring DI data source cache (SQLite).
final postCacheDataSourceProvider = Provider<PostCacheDataSource>(
  (ref) => PostCacheDataSource(),
);

class PostCacheDataSource {
  PostCacheDataSource({Future<Database> Function()? openDb})
    : _openDb = openDb ?? openAppDb;

  final Future<Database> Function() _openDb;

  Future<List<PostModel>> readAll() async {
    final db = await _openDb();
    final rows = await db.query('cached_posts', orderBy: 'id ASC');
    return rows
        .map((row) => jsonDecode(row['payload'] as String))
        .whereType<Map<String, dynamic>>()
        .map(PostModel.fromJson)
        .toList();
  }

  Future<void> replaceAll(List<PostModel> posts) async {
    final db = await _openDb();
    final now = DateTime.now().toIso8601String();
    final batch = db.batch();
    batch.delete('cached_posts');
    for (final post in posts) {
      batch.insert('cached_posts', {
        'id': post.id,
        'payload': jsonEncode(post.toJson()),
        'cached_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }
}
