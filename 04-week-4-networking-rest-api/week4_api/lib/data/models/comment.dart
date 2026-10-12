// Model Comment (AI Prompt Challenge).
//
// Dipetakan dari endpoint `GET /comments?postId={id}` JSONPlaceholder.
// Sama seperti `Post`, seluruh cast dibuat defensif: `as num?` / `as String?`
// dengan nilai default, sehingga respons yang tidak lengkap tidak membuat
// aplikasi crash dengan `type 'Null' is not a subtype of type 'String'`.

class Comment {
  const Comment({
    required this.postId,
    required this.id,
    required this.name,
    required this.email,
    required this.body,
  });

  final int postId;
  final int id;
  final String name;
  final String email;
  final String body;

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      postId: (json['postId'] as num?)?.toInt() ?? 0,
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'postId': postId,
        'id': id,
        'name': name,
        'email': email,
        'body': body,
      };
}
