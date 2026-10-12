// Fallback (tidak dipakai pada platform yang didukung).
Future<void> initDatabaseFactory() async {}

Future<String> databasePath(String name) async => name;
