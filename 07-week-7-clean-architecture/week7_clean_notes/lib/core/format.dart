// Fungsi format & parsing MURNI (Refactoring Challenge no. 2, modul Minggu 7).
//
// Mengapa di `core/`? Karena `presentation` tidak boleh lagi memuat logika
// formatting mentah (`DateFormat`, `jsonDecode`, `.toIso8601String`). Dengan
// dipindah ke sini, logika tersebut bisa diuji lewat `flutter test` biasa
// tanpa mem-build widget apa pun.
//
// File ini tetap murni Dart: tidak mengimpor Flutter, Dio, maupun SQLite
// (lolos grep sterilitas no. 2 pada modul).

/// Singkatan nama bulan versi Indonesia (indeks 0 = Januari).
const List<String> _shortMonths = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

String _two(int value) => value.toString().padLeft(2, '0');

/// `13 Okt 2026` — tanggal ringkas untuk label.
String formatDate(DateTime time) {
  final local = time.toLocal();
  return '${local.day} ${_shortMonths[local.month - 1]} ${local.year}';
}

/// `14:05` — jam saja.
String formatClock(DateTime time) {
  final local = time.toLocal();
  return '${_two(local.hour)}:${_two(local.minute)}';
}

/// `13 Okt 2026, 14:05` — cap waktu lengkap untuk daftar & detail catatan.
String formatDateTime(DateTime time) =>
    '${formatDate(time)}, ${formatClock(time)}';

/// Cap waktu dengan detik, dipakai halaman Pengaturan.
String formatDateTimeWithSeconds(DateTime time) {
  final local = time.toLocal();
  return '${formatDateTime(local)}:${_two(local.second)}';
}

/// Waktu relatif (`baru saja`, `5 menit lalu`, `3 jam lalu`, `2 hari lalu`).
///
/// `now` bisa disuntik agar hasilnya deterministik saat diuji.
String formatRelative(DateTime time, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final diff = reference.difference(time.toLocal());
  if (diff.isNegative) return 'baru saja';
  if (diff.inMinutes < 1) return 'baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  if (diff.inDays < 30) return '${diff.inDays} hari lalu';
  return formatDate(time);
}

/// Parsing parameter rute `/note/:id` menjadi integer.
///
/// Dipisah dari `routes.dart` supaya bisa diuji tanpa GoRouter.
int parseNoteId(String? raw) => int.tryParse((raw ?? '').trim()) ?? 0;

/// Parsing ISO-8601 menjadi `DateTime` lokal; `null` bila tidak valid.
DateTime? parseIsoDate(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw)?.toLocal();
}
