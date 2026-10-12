// Data source jaringan untuk posts (Dio).
//
// Satu-satunya tempat di fitur posts yang tahu endpoint HTTP. Mengembalikan
// model mentah; penerjemahan exception Dio dilakukan di repository.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/data/network/api_client.dart';
import '../models/post_model.dart';

/// Wiring DI data source jaringan.
///
/// Provider ini sengaja berada di layer DATA (bukan presentation) supaya
/// folder presentation sama sekali tidak mengimpor Dio — sesuai grep
/// sterilitas no. 1 pada modul Minggu 7.
final postRemoteDataSourceProvider = Provider<PostRemoteDataSource>(
  (ref) => PostRemoteDataSource(createDio()),
);

class PostRemoteDataSource {
  const PostRemoteDataSource(this._dio);

  final Dio _dio;

  /// `GET /posts?_limit=n`
  Future<List<PostModel>> fetchPosts({int limit = 20}) async {
    final response = await _dio.get<List<dynamic>>(
      '/posts',
      queryParameters: {'_limit': limit},
    );
    final data = response.data ?? const <dynamic>[];
    return data
        .whereType<Map<String, dynamic>>()
        .map(PostModel.fromJson)
        .toList();
  }
}
