// ENTITY Post — objek bisnis murni untuk data bacaan dari jaringan.
//
// Tanpa import Flutter/Dio dan tanpa method serialisasi apa pun; parsing JSON
// adalah tanggung jawab `PostModel` di layer data.

class Post {
  const Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
  });

  final int id;
  final int userId;
  final String title;
  final String body;
}
