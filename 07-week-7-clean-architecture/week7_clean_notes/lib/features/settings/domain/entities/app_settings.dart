// ENTITY AppSettings — preferensi pengguna sebagai objek bisnis murni.
//
// Sama seperti `Note`: tanpa import Flutter dan tanpa mapping. Bentuk
// penyimpanan (SharedPreferences key-value) adalah urusan layer `data`.

class AppSettings {
  const AppSettings({this.darkMode = false, this.lastOpened});

  final bool darkMode;
  final DateTime? lastOpened;

  AppSettings copyWith({bool? darkMode, DateTime? lastOpened}) {
    return AppSettings(
      darkMode: darkMode ?? this.darkMode,
      lastOpened: lastOpened ?? this.lastOpened,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.darkMode == darkMode &&
      other.lastOpened == lastOpened;

  @override
  int get hashCode => Object.hash(darkMode, lastOpened);
}
