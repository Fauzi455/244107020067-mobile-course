// Model data Post yang dipetakan dari respons JSON API JSONPlaceholder.
//
// Pola `fromJson` aman null digunakan di sini karena respons API nyata
// sering tidak sesuai dokumentasi (field hilang, tipe berubah). Cast
// defensif `(json['title'] as String?) ?? ''` mencegah crash
// `type 'Null' is not a subtype` yang menjadi sumber bug paling umum
// pada integrasi API pertama.

class Post {
  const Post({
    required this.userId,
    required this.id,
    required this.title,
    required this.body,
  });

  final int userId;
  final int id;
  final String title;
  final String body;

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'id': id,
        'title': title,
        'body': body,
      };
}
