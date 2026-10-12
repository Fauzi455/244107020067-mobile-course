// Fallback (tidak dipakai pada platform yang didukung minggu ini).
Future<void> initDatabaseFactory() async {}

Future<String> databasePath(String name) async => name;
