// Logika offline-first: cache-first read untuk data bacaan (posts) dan
// sinkronisasi catatan kotor (dirty).
//
// File ini sengaja dipisah dari repository (Refactoring Challenge no. 2) agar
// `NoteRepository` tetap fokus pada CRUD database, sedangkan strategi
// offline-first (cache + antrean sync) hidup di satu tempat yang mudah diuji.

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';

import 'api_client.dart';
import 'local/db.dart';
import 'models/post.dart';
import 'repositories/note_repository.dart';

/// Dilempar bila sinkronisasi diminta sementara `forceOffline` aktif.
class SyncOfflineException implements Exception {
  const SyncOfflineException();
  @override
  String toString() => 'Mode offline aktif: sinkronisasi dilewati.';
}

/// Ambil posts dari jaringan (`GET /posts`). Hanya sebagian agar ringan.
Future<List<Post>> fetchPostsFromNetwork({Dio? dio, int limit = 20}) async {
  final client = dio ?? createDio();
  final response = await client.get<List>(
    '/posts',
    queryParameters: {'_limit': limit},
  );
  final data = response.data ?? [];
  return data
      .whereType<Map<String, dynamic>>()
      .map(Post.fromJson)
      .toList();
}

/// Baca posts dari cache lokal (`cached_posts`). Bisa dipanggil tanpa internet.
Future<List<Post>> readCachedPosts({
  Future<Database> Function()? openDb,
}) async {
  final db = await (openDb ?? openNotesDb)();
  final rows = await db.query('cached_posts', orderBy: 'id ASC');
  return rows
      .map((row) => jsonDecode(row['payload'] as String))
      .whereType<Map<String, dynamic>>()
      .map(Post.fromJson)
      .toList();
}

/// Simpan hasil fetch ke cache lokal untuk kunjungan berikutnya.
Future<void> writeCachedPosts(
  List<Post> posts, {
  Future<Database> Function()? openDb,
}) async {
  final db = await (openDb ?? openNotesDb)();
  final now = DateTime.now().toIso8601String();
  final batch = db.batch();
  batch.delete('cached_posts');
  for (final post in posts) {
    batch.insert(
      'cached_posts',
      {
        'id': post.id,
        'payload': jsonEncode(post.toJson()),
        'cached_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  await batch.commit(noResult: true);
}

/// Sinkronisasi catatan kotor (antrean tulis).
///
/// Karena codelab ini belum punya backend tulis, server disimulasikan dengan
/// delay. Yang dinilai adalah MEKANISME-nya:
///   1. Hitung catatan dirty.
///   2. "Upload" (di sini: delay). Pada project nyata: kirim ke REST API.
///   3. Tandai bersih HANYA setelah server menjawab sukses.
///
/// Aturan konflik yang dipilih: **last-write-wins berdasarkan `updated_at`**
/// (lihat docs/offline_first.md).
Future<int> syncNotes(
  NoteRepository repo, {
  bool forceOffline = false,
}) async {
  final dirtyCount = await repo.countDirty();
  if (dirtyCount == 0) return 0;
  if (forceOffline) {
    throw const SyncOfflineException();
  }
  await Future.delayed(const Duration(seconds: 1));
  await repo.markAllSynced();
  return dirtyCount;
}
