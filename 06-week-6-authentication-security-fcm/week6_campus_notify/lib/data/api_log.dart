// Catatan lalu lintas HTTP untuk keperluan demo/verifikasi.
//
// Modul Minggu 6 mewajibkan pembuktian bahwa 401 benar-benar memicu refresh
// satu kali lalu mengulang request. Log inilah buktinya: ia dirender di
// halaman "Sesi & API" dan ikut terfoto pada screenshot.

class ApiLogEntry {
  const ApiLogEntry(this.message, {this.ok = true});

  final String message;

  /// `false` untuk langkah yang menandakan masalah (401, gagal refresh,
  /// koneksi putus) sehingga bisa diberi warna berbeda di UI.
  final bool ok;
}
