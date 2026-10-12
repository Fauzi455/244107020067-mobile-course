// Failure domain — MURNI Dart (Praktikum 2, modul Minggu 7).
//
// Aturan dependency: `domain` tidak tahu apa pun tentang Flutter, Dio, atau
// SQLite. Karena itu file ini hanya boleh memakai `dart:core`.
//
// Semua exception mentah dari platform (DatabaseException, DioException, ...)
// ditangkap di layer `data` lalu diterjemahkan menjadi salah satu Failure di
// bawah ini, sehingga UI hanya menerima `message` yang ramah pengguna.

/// Kontrak kegagalan yang dipahami seluruh layer.
sealed class Failure {
  const Failure(this.message);

  /// Pesan siap tampil untuk pengguna (bahasa Indonesia).
  final String message;

  @override
  String toString() => message;
}

/// Kegagalan pada sumber data lokal: SQLite (sqflite) atau SharedPreferences.
class LocalFailure extends Failure {
  const LocalFailure(super.message);
}

/// Kegagalan pada sumber data jaringan (Dio/HTTP).
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Kegagalan karena mode offline sedang disimulasikan aktif.
///
/// Ditambahkan (bukan bagian contoh modul) agar `SyncNotes` dapat melaporkan
/// "sinkronisasi dilewati" tanpa melempar exception mentah ke presentation.
class OfflineFailure extends Failure {
  const OfflineFailure(super.message);
}

/// Jembatan Failure -> exception agar `AsyncValue.error` Riverpod membawa
/// pesan ramah pengguna, bukan `DatabaseException` mentah.
class FailureException implements Exception {
  const FailureException(this.failure);

  final Failure failure;

  @override
  String toString() => failure.message;
}

/// Ambil pesan yang aman ditampilkan dari objek error apa pun.
String userMessage(Object error) =>
    error is FailureException ? error.failure.message : error.toString();
