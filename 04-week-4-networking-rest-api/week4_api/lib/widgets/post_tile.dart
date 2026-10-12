// Widget baris post yang diekstrak dari `ListView.builder`
// (Refactoring Challenge no. 1).
//
// Tujuan: membuat itemBuilder di halaman daftar tetap pendek, mudah dibaca,
// dan mudah diuji secara terpisah. `PostTile` hanya menerima data (Post) dan
// sebuah callback `onTap` — ia tidak tahu apa-apa soal Dio, provider, atau
// navigasi, sehingga bisa dipakai ulang di halaman mana pun.

import 'package:flutter/material.dart';
import '../data/models/post.dart';

class PostTile extends StatelessWidget {
  const PostTile({
    super.key,
    required this.post,
    this.onTap,
  });

  final Post post;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Text(post.id.toString())),
      title: Text(
        post.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        post.body,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
